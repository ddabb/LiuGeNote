---
title: @Watch 与 @Monitor：状态变化的副作用编排对比
tags: [ArkTS, 状态管理, Watch, Monitor, 副作用]
description: 对比 V1 @Watch 与 V2 @Monitor 两个状态监听装饰器的语法差异：单值监听与批量监听、拿到新值的方式、触发时机，以及哪些副作用适合放进监听、哪些不适合。
---

# @Watch 与 @Monitor：状态变化的副作用编排对比

状态变了要「顺带做点事」——存进度、发日志、联动另一个状态。两代体系各有一个监听装饰器，语义细节差别不小。

## V1：@Watch —— 拿回调，自己取值

```typescript
@Component
struct Reader {
  @State @Watch('onProgressChange') progress: number = 0;

  onProgressChange(propName: string): void {
    // 回调只给属性名，新值要从 this 上读
    console.info(`进度更新: ${this.progress}`);
    this.persistProgress(this.progress);
  }
}
```

注意：

- 装饰器参数是**回调方法名字符串**，拼错编译期不报错，运行期静默不触发；
- 回调签名是 `(propName: string)`，新旧值都要自己从 `this` 取——此时状态已更新，旧值已丢失；
- 监听对象整体赋值与嵌套属性变化是否触发，取决于配套的观察装饰器（`@State` 只看第一层）。

## V2：@Monitor —— 声明式，给足上下文

```typescript
@ComponentV2
struct ReaderV2 {
  @Local progress: number = 0;
  @Local fontSize: number = 17;

  @Monitor('progress', 'fontSize')
  onPrefChange(monitor: IMonitor): void {
    for (const change of monitor.value()) {
      // change: { name, value(新值), oldValue(旧值) }
      console.info(`${change.name}: ${change.oldValue} -> ${change.value}`);
    }
    if (monitor.dirty('progress')) {
      this.persistProgress(this.progress);
    }
  }
}
```

优势：

- **新旧值都给**：`@State` 时代「想知道旧值只能自己存一份」的别扭没有了；
- **一个回调监听多个属性**，且能用 `monitor.dirty(name)` 精确判断本次是谁变了；
- 属性名是真实引用而非字符串，重构改名时编译器跟着走（装饰器参数仍是字符串，但触发机制与取值都更可靠）。

## 什么该放进监听，什么不该

**适合**：

- 持久化：进度/偏好变化即存；
- 日志埋点：状态迁移记录；
- 跨模块联动：字号变化刷新卡片尺寸。

**不适合**：

- **可以在 build 里表达的计算**——能用 `@Computed`（V2）就别用监听回写状态，容易造成监听链；
- **网络请求等重操作**——监听回调跑在 UI 线程，重活放 `TaskPool`；
- **双向互写**：A 监听改 B、B 监听改 A，两代装饰器都不做环检测，直接死循环。

## 一句话总结

@Watch 是「**属性名 + 自取值**」的老式回调，@Monitor 是「**变更集 + 新旧值**」的现代声明。能用 V2 就用 V2，用 V1 就把回调名和触发层级测清楚。
