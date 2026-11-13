
# Span 与富文本：Text 里的混排世界

一段文字里「高亮关键词」「内嵌小图标」「半句变灰」——都靠 `Span`。Text 不是只能装一串字符。

## Span：文字片段混排

```typescript
Text() {
  Span('全文 ').fontSize(14)
  Span('1280').fontSize(18).fontColor('#8A2BE2').fontWeight(FontWeight.Bold)
  Span(' 字').fontSize(14)
  Span(' · 约 5 分钟').fontSize(12).fontColor('#999999')
}
```

每个 `Span` 独立设置 `fontSize` / `fontColor` / `fontWeight` / `decoration`（删除线、下划线），基线自动对齐。

## ImageSpan：图文混排

```typescript
Text() {
  Span('标签 ')
  ImageSpan($r('sys.media.ohos_ic_public_tag'))
    .width(14)
    .height(14)
    .verticalAlign(ImageSpanAlignment.CENTER)    // 与文字基线对齐
  Span(' ArkTS')
}
```

图标、徽章、内嵌小图都可以，`verticalAlign` 控制对齐方式（TOP/CENTER/BOTTOM）。

## 可点击的 Span

```typescript
Text() {
  Span('阅读').fontSize(14)
  Span('《服务条款》')
    .fontColor('#007DFF')
    .decoration({ type: TextDecorationType.Underline })
    .onClick(() => {
      this.openTerms();
    })
}
```

协议、话题标签、链接——**点击粒度可以细到半句话**。

## 文本溢出省略

```typescript
Text(article.description)
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })   // 末尾省略号
  .lineHeight(22);
```

| 属性 | 说明 |
|---|---|
| `.maxLines(n)` | 超过 n 行截断 |
| `.textOverflow({ overflow })` | Ellipsis（省略号）/ Clip（硬切） |
| `.lineHeight(n)` | 行距，长文可读性的关键 |
| `.copyOption(CopyOptions.InApp)` | 允许复制（默认长按无反应） |

**配对使用**：只写 `textOverflow` 不写 `maxLines`，单行文本永远不会溢出。

## 什么时候别用 Span 堆

Span 是**行内混排**方案，越界即反模式：

- 结构化对齐（表格、键值对两栏）→ `Row` + `layoutWeight`；
- 多段独立点击的大块内容 → 拆多个 Text 或用 RichText 组件；
- Markdown 级复杂富文本（代码块、标题、列表）→ 上渲染组件（如本项目的 markdown 渲染库），手写 Span 拼装不可维护。

## 踩坑记录

1. `Text('直接字符串')` 与 `Text() { Span() }` 是两种用法，**字符串与 Span 混用**编译报错——Text 里要么纯字符串要么纯子组件；
2. ImageSpan 忘了 `verticalAlign`：图标底部贴基线，视觉下沉；
3. Span 的 onClick 抢焦点：整行可点击的卡片，外层 `.onClick` 与内层 Span 事件会同时触发，必要时用 `stopPropagation`；
4. 省略号在中文下不美观：`textOverflow` + 合理 `maxLines`，宁可 2 行也别 3 行挤 1 字。

## 一句话总结

**行内差异用 Span，结构差异用布局**：字号颜色点击混排找 Span，超过一行的排版需求就该换容器。
