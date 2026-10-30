---
title: Markdown 离线渲染选型：Web 组件还是原生解析
category: 数据与渲染
tags: [Markdown, 渲染, 性能, 选型]
description: 记录文章详情页 Markdown 渲染方案的选型对比：Web 组件加载预渲染 HTML 与 ArkUI 原生解析渲染的优劣权衡，最终实现轻量解析器 + Builder 渲染的分层设计。
---

# Markdown 离线渲染选型：Web 组件还是原生解析

文章详情页要渲染 Markdown 正文。参考项目 `vercel-ci` 的做法是构建期 `md2html.js` 把 md 转成 HTML 页面。在鸿蒙侧我们对比了两条路线。

## 方案对比

| 维度 | A：Web 组件 + 预渲染 HTML | B：原生解析 + ArkUI 渲染 |
|---|---|---|
| 实现成本 | 构建期复用 `marked`，应用侧几乎零代码 | 需要自写解析器与渲染层 |
| 体积 | Web 内核页面较重，HTML 体积膨胀 | md 纯文本，体积最小 |
| 一致性 | 需注入 CSS 抹平默认样式 | 与应用视觉天然统一，支持深色模式 |
| 离线安全 | 本地 HTML 仍需防外链跳转 | 无外链风险，纯本地 |
| 交互 | 与原生页面通信要桥接 | 标签/分类点击直接走原生路由 |
| 性能 | 首帧加载慢，滚动惯性不同 | 首帧快，滚动体验原生 |

结论：离线内容应用选 **B**。内容是自己的（不涉及任意第三方 md），语法子集可控，
自写解析器的复杂度可以接受，换来体积、一致性、交互三重收益。

## 轻量解析器设计（MarkdownParser）

两遍扫描，产出 `MdNode[]` 抽象节点：

1. **块级扫描**：逐行识别标题（`#`~`######`）、无序/有序列表、代码块（``` 围栏）、
   引用块（`>`）、表格（`|` 分隔）、分割线、空行分段；
2. **行内解析**：对段落文本解析 `**粗体**`、`*斜体*`、`` `行内代码` ``、
   `[链接](url)`，产出行内 span 序列。

```typescript
export enum MdNodeType {
  Heading, Paragraph, BulletList, OrderedList,
  CodeBlock, Quote, Table, Divider
}

export interface MdNode {
  type: MdNodeType;
  level: number;              // 标题级别
  text: string;               // 纯文本（代码块原样保留）
  items: string[];            // 列表项
  inlineSpans: MdSpan[];      // 行内样式片段
}
```

## 渲染层（MarkdownRenderer）

- `@Builder` 函数按 `MdNode.type` 分发到对应 ArkUI 组件：`Text`/`Column`/`List`；
- 标题字号、间距按 `level` 映射统一资源表；
- 代码块用等宽字体 + 深色底 `Column`，长代码横向可滚动；
- 表格用 `Flex` 按列渲染，列宽自适应。

## 性能实测结论

- 3000 字文章解析耗时在毫秒级，`aboutToAppear` 中同步解析无感知；
- 长文滚动用 `Scroll` + 懒加载不必上：单篇 8k 字内直接整页渲染即可，硬上虚拟滚动反而复杂化；
- 真正的性能敏感点在**正文的按需加载**（见 rawfile 缓存一文），不在解析本身。

## 未支持语法的处理原则

图片、脚注等语法暂未支持。原则：**不支持的块级语法按普通段落兜底展示原文**，
绝不抛异常、绝不吞内容 —— 读者至少能看到原始文本，作者能发现哪篇用了未支持语法。
