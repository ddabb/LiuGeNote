---
title: LazyForEach 懒加载：长列表不卡顿的正确姿势
tags: [ArkTS, 性能优化, LazyForEach, IDataSource, List]
description: 用 LazyForEach + IDataSource 替代 For 渲染长列表：按需创建节点、onDataReloaded 通知时机、数据源接口的完整实现，以及常见的不生效排查。
---

# LazyForEach 懒加载：长列表不卡顿的正确姿势

`ForEach` 会**一次性创建全部子组件**。100 条还好，1000 条时帧率直接崩掉——每个卡片都是真实的组件节点树。`LazyForEach` 只为屏幕内可见（含预加载缓存区）的条目创建节点，滑出屏幕即销毁复用。

## 数据源：实现 IDataSource

LazyForEach 不接受数组，必须给它一个实现了 `IDataSource` 的数据源对象：

```typescript
class ArticleDataSource implements IDataSource {
  private list: ArticleMeta[] = [];

  totalCount(): number {
    return this.list.length;
  }

  getData(index: number): ArticleMeta {
    return this.list[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    // 生产实现需持有 listener，变更时回调；简单只读场景可空实现
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
  }

  // 自定义：整体替换数据
  reload(list: ArticleMeta[]): void {
    this.list = list;
    // 生产实现中此处应回调 listener.onDataReloaded()
  }
}
```

## 使用

```typescript
@State dataSource: ArticleDataSource = new ArticleDataSource();

build() {
  List() {
    LazyForEach(this.dataSource, (item: ArticleMeta) => {
      ListItem() {
        ArticleCard({ meta: item })
      }
    }, (item: ArticleMeta) => item.slug)   // 键生成器必须稳定唯一
  }
}
```

## 三个必须做对的地方

### 1. 键生成器要稳定

第三个参数返回的 key 用于 diff 复用。用 `slug`、`id` 这类**业务唯一键**；用数组下标 `index` 会让插入/删除导致整片节点重建，懒加载优势归零。

### 2. 数据变更要通知

改了 `dataSource` 内部数组但没回调 `onDataReloaded()` / `onDataAdd(index)`，UI 不会刷新——LazyForEach 不观察数据源内部。这是「为什么我改了数据没反应」的第一嫌疑人。

### 3. 条目组件内不要再包重逻辑

懒加载只在「节点数量」上省，单卡片 `build` 里的重计算（排序、深拷贝）照样每次滚动都跑。重的预处理放数据源构造期，或用 `@Computed` 缓存。

## 不生效的排查清单

| 症状 | 原因 |
|---|---|
| 首屏依旧全量创建 | 外层套了 `Scroll` + `Column`，LazyForEach 失去滚动上下文，退化全量 |
| 数据变了 UI 不动 | 缺 `onDataReloaded` 回调 |
| 滚动闪烁/状态错乱 | key 不稳定，节点被错误复用 |
| 嵌套 List 不懒加载 | 内层 LazyForEach 高度不定时缓存失效，考虑改平铺结构 |

## 一句话总结

LazyForEach 三要素：**IDataSource 喂数、稳定 key 找节点、变更回调通知刷新**。三者缺一，要么全量渲染，要么界面纹丝不动。
