/**
 * 数据仓库：离线读取 rawfile 数据（index.json / taxonomy.json / articles/<fileId>.md）。
 * 单例 + 进程内缓存；由 EntryAbility.onCreate 注入 Context。
 */
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { ArticleIndex, ArticleMeta, Taxonomy } from '../model/ArticleModels';

export class DataRepository {
  private static instance: DataRepository | undefined = undefined;
  private static readonly BODY_CACHE_CAP = 20;

  private context: common.Context | undefined = undefined;
  private indexCache: ArticleIndex | undefined = undefined;
  private taxonomyCache: Taxonomy | undefined = undefined;
  private bodyCache: Map<string, string> = new Map();

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
}
