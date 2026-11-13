---
title: List 与 Scroller：滚动控制与回顶按钮实现
tags: [ArkUI, List, Scroller, 滚动, 回顶]
description: 讲解 List 容器的 Scroller 控制器用法：scrollTo 回顶、scrollEdge 定位边缘、scrollIndex 跳转条目、currentOffset 读取偏移，以及双击回顶按钮的完整实现与滚动事件节流。
---

# List 与 Scroller：滚动控制与回顶按钮实现

长列表读起来，用户最大的痛点是「翻了几屏想回去」。`Scroller` 是给 List 装的方向盘。

## 绑定控制器

```typescript
@State scroller: Scroller = new Scroller();
@State showBackTop: boolean = false;

List({ scroller: this.scroller }) {
  // 列表内容
}
.onReachStart(() => this.showBackTop = false)
.onWillScroll((offset: number) => {
  // 滚动偏移超过一屏时显示回顶按钮
  this.showBackTop = this.scroller.currentOffset().yOffset > 600;
})
.scrollBar(BarState.Auto);
```

## Scroller 的四个常用方法

```typescript
this.scroller.scrollTo({                    // 滚到指定偏移
  xOffset: 0,
  yOffset: 0,
  animation: { duration: 300, curve: Curve.EaseOut }   // 平滑滚动
});

this.scroller.scrollEdge(Edge.Top);          // 滚到边缘（Top/Bottom）
this.scroller.scrollIndex(5);                // 滚到第 5 项（部分滚入即可）
const pos = this.scroller.currentOffset();   // 读当前偏移 {xOffset, yOffset}
```

## 双击回顶按钮

```typescript
Stack({ alignContent: Alignment.BottomEnd }) {
  List({ scroller: this.scroller }) { /* ... */ }

  if (this.showBackTop) {
    Button('回顶')
      .onClick(() => {
        this.scroller.scrollTo({
          xOffset: 0,
          yOffset: 0,
          animation: { duration: 300, curve: Curve.EaseOut }
        });
      })
      .margin(20)
      .circleButton()
  }
}
```

交互细节：

- 出现时机用**偏移阈值**（如 600vp）而不是 `onReachEnd`，用户一离屏就有回顶预期；
- 滚动动画 300ms + `EaseOut`，快速但不突兀；
- `scrollEdge(Edge.Top)` 是无动画瞬移，适合「无感重置」场景。

## 滚动事件与节流

`onScroll`/`onWillScroll` 每帧触发，回调里**只做轻量判断**：

```typescript
// ❌ 每帧都写状态 + 持久化
.onScroll(() => { this.saveProgress(); })

// ✅ 阈值判断 + 阈值外不写状态
.onWillScroll((offset: number) => {
  const y: number = this.scroller.currentOffset().yOffset;
  const shouldShow: boolean = y > 600;
  if (shouldShow !== this.showBackTop) {     // 状态变化才写
    this.showBackTop = shouldShow;
  }
})
```

## List 与其它容器的配合

| 需求 | 写法 |
|---|---|
| 纵向长列表 | `List` + `ListItem` |
| 吸顶分组头 | `List` + `ListItemGroup({ header })` |
| 横滑卡片行 | `List` + `.listDirection(Axis.Horizontal)` |
| 网格 | 换 `Grid` 容器 |
| 多方向嵌套滚动 | 外层 `Scroll` 内层 `List`（注意嵌套滚动冲突） |

## 踩坑记录

1. `List` 直接放非 `ListItem` 子节点报错——**内容必须包 ListItem**；
2. `Scroller` 绑定前调用方法无效（还没关联容器）；
3. 嵌套滚动（Scroll 套 List）手势冲突：内层加 `.nestedScroll()` 控制；
4. 滚动位置不保存：页面返回后想恢复，把 `currentOffset().yOffset` 存起来，`onAppear` 时 `scrollTo` 恢复。

## 一句话总结

Scroller 是 List 的方向盘：**scrollTo 管动画定位，currentOffset 管状态判断**，回顶按钮只是它最小的应用。
