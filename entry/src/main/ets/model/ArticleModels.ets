/**
 * 数据模型：与 scripts/publish.js 产出的 rawfile JSON 结构一一对应。
 * 共享类型统一在本文件声明，导出后供各页面/组件导入（声明唯一原则）。
 */

/** index.json -> meta */
export interface IndexMeta {
  generatedAt: string;
  totalFiles: number;
  generator: string;
}

/** index.json -> files[] 单篇文章元数据 */
export interface ArticleMeta {
  /** 中文稳定 ID：路由与展示用 */
  slug: string;
  /** 正文文件存储 ID（slug 的 FNV-1a 哈希，8 位十六进制） */
  fileId: string;
  title: string;
  description: string;
  category: string;
  tags: string[];
  wordCount: number;
  createTime: string;
  updateTime: string;
  order: number;
}

/** index.json 整体 */
export interface ArticleIndex {
  meta: IndexMeta;
  files: ArticleMeta[];
}

/** taxonomy.json -> tags[]/categories[] 单项 */
export interface TaxonomyItem {
  name: string;
  count: number;
}

/** taxonomy.json 整体 */
export interface Taxonomy {
  generatedAt: string;
  tags: TaxonomyItem[];
  categories: TaxonomyItem[];
}

/** 路由参数：文章详情页（声明唯一，各页面共用） */
export interface ArticleDetailParams {
  slug: string;
}

/** 路由参数：标签详情页 */
export interface TagDetailParams {
  tag: string;
}

/** 路由参数：分类详情页 */
export interface CategoryDetailParams {
  category: string;
}

/** 全文搜索结果：文章元数据 + 命中摘要 + 得分 */
export class SearchResult {
  article: ArticleMeta = createEmptyArticleMeta();
  /** 首个命中位置附近的正文片段 */
  snippet: string = '';
  /** 相关度得分（标题/标签/正文加权累计，降序排序用） */
  score: number = 0;
}

/** 创建空的文章元数据（供 @Prop 默认值等场景） */
export function createEmptyArticleMeta(): ArticleMeta {
  const m: ArticleMeta = {
    slug: '',
    fileId: '',
    title: '',
    description: '',
    category: '',
    tags: [],
    wordCount: 0,
    createTime: '',
    updateTime: '',
    order: 0
  };
  return m;
}

/** 预计阅读时长（分钟）：中文约 400 字/分钟，至少 1 分钟（Kindle 剩余时长同思路） */
export function estReadingMinutes(wordCount: number): number {
  if (!Number.isFinite(wordCount) || wordCount <= 0) {
    return 1;
  }
  return Math.max(1, Math.round(wordCount / 400));
}
