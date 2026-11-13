---
title: async 与 await 异步编程规范：Promise 链的正确姿势
tags: [ArkTS, 异步编程, async, await, Promise]
description: 整理 ArkTS 异步编程的规范写法：async 函数的返回类型、await 的错误处理、并发任务的聚合、回调转 Promise，以及忘记 await 导致的常见事故。
---

# async 与 await 异步编程规范：Promise 链的正确姿势

ArkTS 的异步模型建立在 Promise 之上，`async/await` 是糖。糖好吃，但每个坑都真实存在。

## 基本规则

### 规则一：async 函数返回 Promise<T>，类型要显式

```typescript
async function loadArticle(slug: string): Promise<ArticleMeta | undefined> {
  return repo.getArticleMeta(slug);   // 单返回值也要标 Promise
}
```

`async` 函数哪怕 `return 42`，实际返回的也是 `Promise<number>`。调用侧必须 `await` 或 `.then`，**直接当值用是 undefined**。

### 规则二：await 必须配错误处理

```typescript
// ❌ 未捕获的 reject 会让应用崩溃
const data = await fetchIndex();

// ✅ try-catch 包住整段 await 链
async function safeLoad(): Promise<ArticleIndex | undefined> {
  try {
    const raw = await fetchIndex();
    return JSON.parse(raw) as ArticleIndex;
  } catch (e) {
    console.error(`加载失败: ${(e as Error).message}`);
    return undefined;   // 调用方拿 undefined 做降级
  }
}
```

`.catch` 回调里用到 error 时要标类型：`.catch((e: BusinessError) => { ... })`。

### 规则三：别在箭头回调里丢 await

```typescript
// ❌ forEach 回调是普通函数，await 不等待，循环先跑完了
items.forEach(async (slug: string) => {
  await loadArticle(slug);
});

// ✅ for-of 顺序等待
for (const slug of slugs) {
  await loadArticle(slug);
}

// ✅ 无依赖任务并发跑
const results: ArticleMeta[] = await Promise.all(
  slugs.map((slug: string) => loadArticle(slug))
);
```

## 高频事故清单

| 事故 | 症状 | 修法 |
|---|---|---|
| 忘记 await | 变量是 Promise 对象，取属性 undefined | 检查每一处异步调用 |
| 循环里 await 串行 | 10 个请求排队 10 倍耗时 | 无依赖用 `Promise.all` |
| async 回调未等待 | 回调先返回，副作用后发生 | 回调内自管错误，外层不用等 |
| 在 build 里 await | build 不是 async，写不了 | 数据预加载进 `@State` |
| 嵌套 then 链 | 缩进失控、错误处理割裂 | 拍平成 async 函数 |

## 回调风格 API 转 Promise

部分系统 API 同时提供回调与 Promise 两种形式，**优先 Promise 形式**，统一进 async 链：

```typescript
// 回调风格（混用会打断 async 链，尽量别用）
xxxApi.execute((err, data) => { ... });

// Promise 风格
const data = await xxxApi.execute();
```

## 生命周期竞态

异步回来时页面可能已经销毁，`this` 引用的组件早不在了。防御写法：

```typescript
private alive: boolean = true;

aboutToDisappear(): void {
  this.alive = false;
}

async function refresh(): Promise<void> {
  const list = await loadList();
  if (!this.alive) {
    return;              // 页面已销毁，丢弃结果
  }
  this.list = list;
}
```

## 一句话总结

**每个 await 都有归属**：要么在 try-catch 里，要么在 Promise.all 里。异步代码的体面，就是让每个失败路径都有人接。
