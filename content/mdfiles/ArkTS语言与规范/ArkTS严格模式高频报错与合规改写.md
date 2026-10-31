---
title: ArkTS 严格模式踩坑：禁用 any、对象字面量与类型断言
tags: [ArkTS, 严格模式, 类型系统, arkts-no-any]
description: 整理本脚手架开发中被 ArkTS 严格模式拦截的高频问题：arkts-no-any、arkts-no-obj-literals-as-types、as 类型断言禁用、动态属性访问禁用，并给出每一类的合规改写方案。
---

# ArkTS 严格模式踩坑：禁用 any、对象字面量与类型断言

ArkTS 是 TypeScript 的严格化子集。从 TS 迁移过来的第一周，`arkts_check` 的报错几乎全来自四个规则。逐个记录如下。

## 踩坑一：arkts-no-any —— 禁用 any/unknown

### 错误写法

```typescript
function parse(json: string): any {          // ❌ ERROR
  return JSON.parse(json);
}
```

### 合规改写

为返回值声明**明确的接口**，反序列化后逐字段校验：

```typescript
interface ArticleMeta {
  slug: string;
  title: string;
  tags: string[];
}

function parseArticle(json: string): ArticleMeta {
  const obj: ArticleMeta = JSON.parse(json) as ArticleMeta; // as 用于接收，见坑三说明
  return obj;
}
```

## 踩坑二：arkts-no-obj-literals-as-types —— 禁用对象字面量类型

### 错误写法

```typescript
let point: { x: number, y: number } = { x: 1, y: 2 };   // ❌ ERROR
function move(p: { x: number, y: number }) {}            // ❌ ERROR
```

### 合规改写

一律抽成 `interface` 或 `class`：

```typescript
interface Point {
  x: number;
  y: number;
}
let point: Point = { x: 1, y: 2 };   // ✅ 字面量有明确类型上下文
```

> 关键区别：**对象字面量本身不违规**，违规的是把字面量形状直接当类型用。只要变量/参数有 interface 类型注解，字面量赋值是合法的。

## 踩坑三：as 类型断言的边界

ArkTS 并非一刀切禁止 `as`，但**禁止用 as 规避类型检查**（如 `as any`）。合法场景基本只有一种：`JSON.parse` 的接收端做一次声明，后续代码必须按声明类型写。结构性收窄应改用类型守卫：

```typescript
function isArticle(v: object): v is ArticleMeta {
  return 'slug' in v && 'title' in v;
}
```

## 踩坑四：arkts-no-property-props —— 禁用动态属性访问

参考项目 `publish.js` 里大量出现 `item[field]` 动态取值：

```javascript
const taxonomy = generateTaxonomy(mdFiles, 'category');  // item[field] 动态访问
```

迁移到 ArkTS 侧（比如数据仓库）时必须显式展开为具体函数：`byCategory()`、`byTag()` 各自直书属性名。动态性留在 **Node 构建脚本**里（Node 侧是普通 JS，不受 ArkTS 约束），应用侧只消费静态形状的数据 —— 这也是"构建期做数据整形"的另一个理由。

## 经验清单

| 规则 | 一句话改法 |
|---|---|
| arkts-no-any | 给 JSON.parse 声明 interface |
| arkts-no-obj-literals-as-types | 字面量形状抽成 interface |
| as 滥用 | 只用于 parse 接收端，其余用类型守卫 |
| 动态属性访问 | 构建期展开，应用侧静态化 |

严格模式的本质是**把运行期风险前移到编译期**。改写虽繁琐，但换来的是包体更小、运行更稳。
