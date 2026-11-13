---
title: Transition 转场与共享元素动效：界面切换的高级感
tags: [ArkUI, 转场动画, Transition, 共享元素, 动效]
description: 讲解组件级转场动画：appear/disappear 的 Transition 用法、系统内置转场（Navigation 转场）、列表到详情的共享元素思路，以及转场与条件渲染的配合。
---

# Transition 转场与共享元素动效：界面切换的高级感

界面「啪一下」切换是功能，「丝滑地流过去」是体验。`Transition` 负责**组件出现/消失时的过渡**。

## 组件级转场

```typescript
@State showDetail: boolean = false;

if (this.showDetail) {
  DetailPanel()
    .transition({
      appear: {
        type: TransitionType.Appear,
        translate: { x: '100%' },        // 从右侧滑入
        opacity: 0                        // 同时淡入
      },
      disappear: {
        type: TransitionType.Disappear,
        translate: { x: '100%' },        // 向右滑出
        opacity: 0
      }
    })
    .animation({ duration: 300, curve: Curve.EaseOut })
}
```

核心机制：

- Transition 定义在**被切换的组件**上（配合 if 条件渲染）；
- `appear` = 从「这些值」补间到正常状态；`disappear` = 从正常状态补间到「这些值」；
- 配合 `.animation()` 或外层 `animateTo` 提供时长曲线。

## 常用转场组合

| 效果 | appear/disappear 参数 |
|---|---|
| 淡入淡出 | `opacity: 0` |
| 底部抽屉 | `translate: { y: '100%' }` |
| 侧滑面板 | `translate: { x: '100%' }` |
| 弹窗缩放 | `scale: { x: 0.8, y: 0.8 }` + `opacity: 0` |
| 上滑展开 | `translate: { y: 40 }` + `opacity: 0`（小幅位移更含蓄） |

组合原则：**一个位移 + 一个透明度**足矣，再加旋转就过了。

## 页面级转场：交给 Navigation

组件级 Transition 管「页内元素」；**页面之间的转场由 Navigation 系统自带**：

- 压栈：默认推入转场（新页从右侧进入）；
- 出栈：默认滑出；
- 自定义走 `customNavContentTransition` 事件，返回转场回调。

**不要自己拿 if 模拟页面切换**——路由栈、返回键、转场手势全都会丢。

## 共享元素思路：列表到详情

「点击卡片，卡片飞到详情页」的思路：

1. 转场期间在**目标页定位同款元素**（封面图、标题块），用相同的圆角/字号；
2. 用 `animateTo` 驱动 scale/translate 从卡片位置补间到详情位置；
3. 结束后切换为详情布局。

ArkUI 的共享元素转场（`geometryTransition`）即是这个机制的官方封装：两处组件标同一 id，转场时框架自动补间。

## 转场的分寸

1. **退场要比进场快**：退场 200ms、进场 300ms——用户对「离开」的耐心更短；
2. **转场期间交互可中断**：动画中允许点击返回，别锁操作；
3. **低端机保底**：转场动画帧率跟不上时宁可砍掉，卡顿比朴素更伤体验；
4. **动效成体系**：全应用统一「右进左出 + 淡入淡出」语言，别每页一个花样。

## 踩坑记录

1. Transition 写了不生效：组件切换没走 if 条件渲染，或没有配 `.animation()` 提供时长；
2. disappear 瞬间消失：`animateTo` 没包住状态切换，或时长写在了 transition 里（应在 animation）；
3. 转场期间布局跳动：容器没固定尺寸，组件消失瞬间父容器塌缩。

## 一句话总结

**组件转场用 Transition + if，页面转场交给 Navigation**：一移一淡、进慢退快，高级感来自克制。
