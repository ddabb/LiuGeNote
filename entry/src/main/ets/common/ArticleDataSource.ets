/**
 * 文章列表懒加载数据源：IDataSource 实现，配合 List + LazyForEach 渲染 928 篇级大列表。
 * - 仅可见区附近的卡片参与创建（对比 ForEach 全量创建），列表滚动性能的地基
 * - 数据整体替换经 reload() 通知框架；数据不变仅刷新派生态（已读状态）用 notifyReload()
 * - 数据源实例随页面持有，禁止重新赋值（LazyForEach 约束），更新必须走 DataChangeListener
 */
import { ArticleMeta } from '../model/ArticleModels';

export class ArticleDataSource implements IDataSource {
  private items: ArticleMeta[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): ArticleMeta {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) === -1) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx: number = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  /** 整体替换数据并通知框架重建可见项（滚动位置保持） */
  reload(items: ArticleMeta[]): void {
    this.items = items;
    this.notifyReload();
  }

  /** 数据不变，仅通知重建可见项（返回本页时刷新卡片已读状态等派生态） */
  notifyReload(): void {
    for (const listener of this.listeners) {
      listener.onDataReloaded();
    }
  }
}
