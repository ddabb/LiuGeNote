---
title: animateTo 与曲线动画：显式动画入门
tags: [ArkUI, 动画, animateTo, Curve, 属性动画]
description: 讲解 ArkUI 显式动画 animateTo 的驱动方式：状态变化包裹动画、Curve 曲线体系、时长与延迟参数、局部 vs 全局动画，以及哪些属性可以参与动画。
---

# animateTo 与曲线动画：显式动画入门

ArkUI 动画的门把手是 `animateTo`：**把状态变化包起来，框架自动对受影响的属性做补间**。

## 基本用法

```typescript
@State radius: number = 8;
@State expanded: boolean = false;

Button('展开')
  .borderRadius(this.radius)
  .onClick(() => {
    this.getUIContext().animateTo(
      { duration: 300, curve: Curve.EaseOut },   // 动画参数
      () => {
        this.radius = 24;                        // 状态变化写在这里
        this.expanded = true;
      }
    );
  })
```

执行逻辑：回调里改状态 → 框架捕获哪些 UI 属性因此变化 → 在 `duration` 内从旧值补间到新值。

不包 `animateTo` 的状态变化是**瞬变**（直接跳到新值）；包了就是**渐变**。

## 曲线体系

```
Curve.Linear        匀速（机械感，慎用）
Curve.Ease          慢入慢出（默认，通用）
Curve.EaseIn        慢入快出（离场：滑出、淡出）
Curve.EaseOut       快入慢出（进场：弹出、展开）★ UI 动画首选
Curve.Friction      摩擦减速（物理感：回弹停住）
Curve.Smooth        更平缓的慢入慢出
```

**弹簧效果**不在 Curve 里，要从 `@ohos.curves` 拿：

```typescript
import { curves } from '@kit.ArkUI';

this.getUIContext().animateTo({
  duration: 1,                                   // springCurve 自管时长
  curve: curves.springCurve(0.2, 1, 200, 20),    // 速度/质量/刚度/阻尼
}, () => { this.scale = 1.1; })
```

## 动画参数速查

```typescript
{
  duration: 300,          // 时长 ms
  curve: Curve.EaseOut,   // 曲线
  delay: 100,             // 延迟启动
  iterations: 1,          // 次数（-1 无限）
  playMode: PlayMode.Normal,   // Normal/Alternate（往返）
  onFinish: () => {}      // 结束回调（无限循环不触发）
}
```

## 可动画的属性

尺寸（width/height/radius）、位置（offset/position）、变换（scale/rotate/translate）、透明度 opacity、颜色类（backgroundColor/borderColor）、阴影——**离散值（文字内容、flexDirection）不可动画**。

判定技巧：属性值能**连续插值**的才能动。数字、颜色、坐标可以；枚举、字符串内容不行。

## 实践节奏建议

| 场景 | duration | curve |
|---|---|---|
| 按钮反馈（缩放/高亮） | 100~200ms | EaseOut |
| 展开/收起面板 | 250~350ms | EaseOut |
| 页面元素进场 | 300~400ms | EaseOut |
| 退场（淡出/滑出） | 200~300ms | EaseIn |

超过 500ms 的 UI 动画几乎必然拖沓——**动画是调味料，不是主菜**。

## 踩坑记录

1. 状态变化必须写在 animateTo 的**回调里**，回调外改状态不参与动画；
2. 无限循环动画忘关：页面销毁前重置状态，别让后台一直烧帧；
3. 用 `this.getUIContext().animateTo` 替代全局静态调用，多实例窗口下更稳；
4. 低端机掉帧时优先砍动画时长，别砍帧率监听逻辑。

## 一句话总结

**animateTo = 动画参数 + 状态变化回调**：曲线选 EaseOut、时长 300ms、可插值属性才参与——三条记住，动效就有了分寸。
