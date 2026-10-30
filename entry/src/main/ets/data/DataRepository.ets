/**
 * 数据仓库：离线读取 rawfile 数据（index.json / taxonomy.json / articles/<fileId>.md）。
 * 单例 + 进程内缓存；由 EntryAbility.onCreate 注入 Context。
 */
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ArticleIndex, ArticleMeta, SearchResult, Taxonomy } from '../model/ArticleModels';

export class DataRepository {
  private static instance: DataRepository | undefined = undefined;
  private static readonly BODY_CACHE_CAP = 20;
  /** 搜索命中片段半径（字符） */
  private static readonly SNIPPET_RADIUS = 30;
  /** 单篇正文命中计分上限 */
  private static readonly BODY_HIT_CAP = 10;

  private context: common.Context | undefined = undefined;
  private indexCache: ArticleIndex | undefined = undefined;
  private taxonomyCache: Taxonomy | undefined = undefined;
  private bodyCache: Map<string, string> = new Map();
  /** 全文检索语料：slug -> 小写正文（首词触发时一次性构建） */
  private searchCorpus: Map<string, string> = new Map();

  static getInstance(): DataRepository {
    if (DataRepository.instance === undefined) {
      DataRepository.instance = new DataRepository();
    }
    return DataRepository.instance;
  }

  /** EntryAbility.onCreate 中调用，注入能力上下文 */
  init(context: common.Context): void {
    this.context = context;
  }

  /** 同步读取 rawfile 文本并按 UTF-8 解码（TextDecoder 显式吞掉 BOM） */
  private readRawText(path: string): string {
    if (this.context === undefined) {
      throw new Error('DataRepository 未初始化，请确认 EntryAbility 已注入 context');
    }
    const buf: Uint8Array = this.context.resourceManager.getRawFileContentSync(path);
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: false });
    return decoder.decodeToString(buf);
  }

  /** 文章索引（缓存） */
  getIndex(): ArticleIndex {
    if (this.indexCache === undefined) {
      const text: string = this.readRawText('index.json');
      this.indexCache = JSON.parse(text) as ArticleIndex;
    }
    return this.indexCache;
  }

  /** 标签/分类统计（缓存） */
  getTaxonomy(): Taxonomy {
    if (this.taxonomyCache === undefined) {
      const text: string = this.readRawText('taxonomy.json');
      this.taxonomyCache = JSON.parse(text) as Taxonomy;
    }
    return this.taxonomyCache;
  }

  /** 全部文章（按 updateTime 降序，与发布顺序一致） */
  getAllArticles(): ArticleMeta[] {
    return this.getIndex().files;
  }

  /** 按标签过滤文章 */
  getArticlesByTag(tag: string): ArticleMeta[] {
    return this.getIndex().files.filter((a: ArticleMeta) => a.tags.indexOf(tag) >= 0);
  }

  /** 按分类过滤文章 */
  getArticlesByCategory(category: string): ArticleMeta[] {
    return this.getIndex().files.filter((a: ArticleMeta) => a.category === category);
  }

  /** 按 slug 查文章元数据 */
  getArticleMeta(slug: string): ArticleMeta | undefined {
    return this.getIndex().files.find((a: ArticleMeta) => a.slug === slug);
  }

  /** 按需加载文章正文（front-matter 已剥离的 Markdown 文本），带容量上限缓存 */
  getArticleBody(meta: ArticleMeta): string {
    const cached: string | undefined = this.bodyCache.get(meta.slug);
    if (cached !== undefined) {
      return cached;
    }
    const text: string = this.readRawText(`articles/${meta.fileId}.md`);
    if (this.bodyCache.size >= DataRepository.BODY_CACHE_CAP) {
      this.bodyCache.clear();
    }
    this.bodyCache.set(meta.slug, text);
    return text;
  }

  /** 离线全文搜索：空查询返回空数组；多关键词按空格分词，全部命中才计入 */
  searchArticles(query: string): SearchResult[] {
    const trimmed: string = query.trim();
    if (trimmed === '') {
      return [];
    }
    const terms: string[] = trimmed.toLowerCase().split(/\s+/).filter((t: string) => t !== '');
    if (terms.length === 0) {
      return [];
    }
    this.ensureSearchCorpus();
    const results: SearchResult[] = [];
    for (const article of this.getAllArticles()) {
      const score: number = this.scoreArticle(article, terms);
      if (score > 0) {
        const r: SearchResult = new SearchResult();
        r.article = article;
        r.score = score;
        r.snippet = this.buildSnippet(article.slug, terms);
        results.push(r);
      }
    }
    results.sort((a: SearchResult, b: SearchResult) => b.score - a.score);
    return results;
  }

  /** 计分：标题 8 分/词，标签与分类 4 分/词，描述 2 分/词，正文每处命中 1 分（封顶） */
  private scoreArticle(article: ArticleMeta, terms: string[]): number {
    const title: string = article.title.toLowerCase();
    const desc: string = article.description.toLowerCase();
    const category: string = article.category.toLowerCase();
    let score: number = 0;
    const body: string = this.searchCorpus.get(article.slug) ?? '';
    for (const term of terms) {
      let hit: boolean = false;
      if (title.indexOf(term) >= 0) {
        score += 8;
        hit = true;
      }
      if (category.indexOf(term) >= 0) {
        score += 4;
        hit = true;
      }
      for (const tag of article.tags) {
        if (tag.toLowerCase().indexOf(term) >= 0) {
          score += 4;
          hit = true;
        }
      }
      if (desc.indexOf(term) >= 0) {
        score += 2;
        hit = true;
      }
      if (body !== '') {
        let from: number = body.indexOf(term);
        let count: number = 0;
        while (from >= 0 && count < DataRepository.BODY_HIT_CAP) {
          count++;
          from = body.indexOf(term, from + term.length);
        }
        if (count > 0) {
          score += count;
          hit = true;
        }
      }
      if (!hit) {
        return 0;
      }
    }
    return score;
  }

  /** 命中摘要：取正文首个命中词上下文片段 */
  private buildSnippet(slug: string, terms: string[]): string {
    const body: string = this.searchCorpus.get(slug) ?? '';
    if (body === '') {
      return '';
    }
    let pos: number = -1;
    for (const term of terms) {
      pos = body.indexOf(term);
      if (pos >= 0) {
        break;
      }
    }
    if (pos < 0) {
      return body.substring(0, DataRepository.SNIPPET_RADIUS * 2);
    }
    const start: number = Math.max(0, pos - DataRepository.SNIPPET_RADIUS);
    const end: number = Math.min(body.length, pos + DataRepository.SNIPPET_RADIUS);
    let snippet: string = body.substring(start, end).replace(/\s+/g, ' ').trim();
    if (start > 0) {
      snippet = '...' + snippet;
    }
    if (end < body.length) {
      snippet = snippet + '...';
    }
    return snippet;
  }

  /** 首次搜索时构建全量小写语料（数千篇规模内存可承受；正文原始缓存不受影响） */
  private ensureSearchCorpus(): void {
    if (this.searchCorpus.size > 0) {
      return;
    }
    for (const article of this.getAllArticles()) {
      const cached: string | undefined = this.bodyCache.get(article.slug);
      const text: string = cached !== undefined ? cached : this.readRawText(`articles/${article.fileId}.md`);
      this.searchCorpus.set(article.slug, text.toLowerCase());
    }
  }
}
