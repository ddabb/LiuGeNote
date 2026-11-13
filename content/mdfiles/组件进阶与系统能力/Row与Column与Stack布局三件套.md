---
title: Row、Column、Stack：三大布局容器的分寸
tags: [ArkUI, 布局, Row, Column, Stack, Flex]
description: 讲解 ArkUI 三大布局容器的主轴交叉轴概念、对齐属性配对关系（justifyContent 与 alignItems）、space 与 weight 的分配逻辑，以及 Stack 层叠的 z 序控制。
---

# Row、Column、Stack：三大布局容器的分寸

ArkUI 页面骨架九成由这三个容器搭出来：`Row`（横）、`Column`（竖）、`Stack`（叠）。各自的属性配对是有讲究的，用错属性是新手第一类报错。

## 主轴与交叉轴

| 容器 | 主轴 | 主轴对齐 | 交叉轴对齐 |
|---|---|---|---|
| Row | 水平 | `.justifyContent()` | `.alignItems()` |
| Column | 垂直 | `.justifyContent()` | `.alignItems()` |
| Stack | — | `.alignContent()`（九宫格定位） | — |

`.alignContent()` 是 Stack 的专属，**搬到 Row 上不存在**；反过来 Stack 也没有 `justifyContent`。

## Row / Column：线性排布

```typescript
Row({ space: 12 }) {                    // space 是构造参数，不是链式属性
  Text('标签').fontSize(14)
  Blank()                               // 撑开中间，两端分布
  Text('6 篇').fontColor('#999')
}
.justifyContent(FlexAlign.SpaceBetween) // 主轴分布
.alignItems(VerticalAlign.Center)       // 交叉轴居中
.width('100%')
.padding(16);
```

要点：

- **`space` 写在构造参数里**：`Row({ space: 12 })`，不是 `.space()`；
- `Blank()` 是弹性占位，比手写 `layoutWeight` 更直观的「两端分布」；
- 子项均分剩余空间用 `.layoutWeight(1)`，weight 子项不再需要固定宽高。

## 主轴对齐枚举速查

```
FlexAlign.Start          靠头
FlexAlign.Center         居中
FlexAlign.End            靠尾
FlexAlign.SpaceBetween   两端贴边，中间均分
FlexAlign.SpaceAround    每项两侧等距（边缘间距是项间距的一半）
FlexAlign.SpaceEvenly    全部等距
```

## Stack：层叠与九宫格

```typescript
Stack({ alignContent: Alignment.BottomEnd }) {
  Image($r('app.media.cover'))
    .width(96).height(128)
  Text('NEW')
    .fontSize(10)
    .padding(4)
    .backgroundColor('#E03030')
    .borderRadius(4)
}
.width(96).height(128);
```

- `alignContent` 支持 `Alignment` 九个方位（TopStart、BottomEnd、Center…）；
- **后写的子组件在上层**（z 序按声明顺序）；
- 角标、封面压字、播放按钮压画面，都是 Stack 的主场。

## 嵌套的分寸

1. **先外后内**：外层定页面骨架（Column），中层定区块（Row），内层定条目——别一上来就五层嵌套；
2. **宽高交给父级**：容器没约束、子项没尺寸，界面会塌成 0——根因几乎总是「父没给宽高」；
3. 复杂等分/换行才上 `Flex`，常规排布 Row/Column 更轻；
4. `Scroll` 内套 `Column` 才能滚动，Row/Column 本身不滚动。

## 踩坑记录

| 症状 | 原因 |
|---|---|
| `justifyContent` 不生效 | 用在了 Stack 上（Stack 用 alignContent） |
| space 属性报不存在 | 当链式属性写（应写在构造参数） |
| 子项挤成一团 | 父容器没设 width('100%') |
| Blank 不起作用 | Row 没有 100% 宽，没有剩余空间可占 |

## 一句话总结

**Row/Column 管排布，Stack 管层叠**；对齐看轴，间距进构造参数，宽高给足——布局的三分寸。
