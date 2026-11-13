---
title: @Observed 与 @ObjectLink：V1 时代嵌套对象观察指南
tags: [ArkTS, Observed, ObjectLink, 状态管理, 嵌套对象]
description: 讲解 V1 体系观察嵌套对象的标准组合 @Observed + @ObjectLink：装饰器职责、代理刷新机制、数组项不刷新的经典问题，以及何时应该升级 V2 的 ObservedV2。
---

# @Observed 与 @ObjectLink：V1 时代嵌套对象观察指南

V1 的 `@State` 只观察**第一层**：赋值刷新，嵌套属性不刷新。要让「对象的属性变化」被看见，得请出这对搭档。

## 装饰器职责

```typescript
@Observed
class ArticleProgress {
  slug: string;
  percent: number;

  constructor(slug: string) {
    this.slug = slug;
    this.percent = 0;
  }
}

@Component
struct ProgressItem {
  @ObjectLink item: ArticleProgress;   // 接收 @Observed 类实例，建立观察
  build() {
    Progress({ value: this.item.percent, total: 100 })
  }
}

@Component
struct Shelf {
  @State list: ArticleProgress[] = [new ArticleProgress('slug-a')];
  build() {
    Column() {
      ForEach(this.list, (p: ArticleProgress) => {
        ProgressItem({ item: p })       // 子组件用 @ObjectLink 接住数组项
      }, (p: ArticleProgress) => p.slug)
    }
  }
}
```

- `@Observed` 装饰**类**：标记「我的实例需要被代理观察」；
- `@ObjectLink` 装饰**子组件属性**：接收一个 `@Observed` 实例并订阅它的属性变化。

## 为什么必须拆子组件

经典坑：数组项的属性直接改，页面不刷新——

```typescript
// ❌ 页面不刷新：@State 只观察 list 本身（赋值/长度），不管项内属性
this.list[0].percent = 50;

// ✅ 数组项交给 @ObjectLink 子组件，percent 变化由代理触发子组件刷新
```

`@Observed` 的代理在实例被 `@ObjectLink` 接住时建立，**没有 @ObjectLink 的 @Observed 是摆设**。所以「列表项有可变属性」的列表，必须拆成子组件接收。

## @ObjectLink 的约束

1. 类型必须是 `@Observed` 类，且**不能本地初始化**——只能从父组件传入；
2. 与 `@State` 一样属于 V1 体系，不能出现在 `@ComponentV2` 里；
3. 传递路径要保持引用同一实例：`ProgressItem({ item: this.list[i] })` 传的是引用，深拷贝会断开观察。

## 什么时候放弃这对组合，升级 V2

- **层级深**：`@Observed` 只代理一层，两层以上嵌套要层层传递、层层 @ObjectLink，链路一长必漏；
- **属性多、只想刷新变化的那个**：V1 代理粒度是「实例级」，`@ObservedV2` + `@Trace` 是「属性级」；
- **新写的组件**：直接 V2 起步，老组合只留给存量 V1 页面。

```
嵌套观察选型：
  一层嵌套 + 存量 V1 列表 → @Observed + @ObjectLink
  两层以上 / 新项目 / 精准刷新 → @ObservedV2 + @Trace（配合 @Local/@Param）
```

## 一句话总结

`@Observed` 标记可观察，`@ObjectLink` 建立观察——**一个标记、一个接线，缺一个都不通电**。新代码优先 V2，别再拉长 V1 的接线板。
