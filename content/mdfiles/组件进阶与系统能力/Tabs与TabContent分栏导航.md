---
title: Tabs 与 TabContent：应用内分栏导航实战
tags: [ArkUI, Tabs, TabContent, 页签, 底部导航]
description: 讲解 Tabs 容器的三种页签位置（底部/顶部/侧边）、TabContent 与 tabBar 的配置、BottomTabBarStyle 的图标文字样式、页签切换事件与懒加载，以及 Tabs 与 Navigation 的组合架构。
---

# Tabs 与 TabContent：应用内分栏导航实战

底部三页签（学习/知识库/我的）这类主界面导航，ArkUI 的标准答案就是 `Tabs`——不需要自己拿三个按钮 + 状态切换硬拼。

## 基本结构

```typescript
Tabs({ barPosition: BarPosition.End }) {      // End = 底部；Start = 顶部
  TabContent() {
    StudyTab()                                 // 每个页签一个内容区
  }
  .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_book'), '学习'))

  TabContent() {
    LibraryTab()
  }
  .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_folder'), '知识库'))

  TabContent() {
    MineTab()
  }
  .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_user'), '我的'))
}
.barWidth('100%')
.barHeight(56)
.onChange((index: number) => {
  console.info(`切换到页签 ${index}`);
});
```

结构铁律：**Tabs 只能包 TabContent，TabContent 必须配 `.tabBar()`**，缺了 tabBar 页签不显示。

## tabBar 的三种风格

| 风格 | 位置 | 用法 |
|---|---|---|
| `BottomTabBarStyle(icon, text)` | 底部 | 主导航标配：图标 + 文字 |
| `SubTabBarStyle(text)` | 顶部 | 内容子分类（如「全部/待读/已读」） |
| 自定义 Builder | 任意 | 特殊样式：角标、动效 |

页签样式定制走**构造参数**：`new BottomTabBarStyle(icon, text)`，选中色/文字样式在 Tabs 上统一配：

```typescript
.barMode(BarMode.Fixed)             // 平分；Scrollable 可滑动
.vertical(false)                    // true 时页签放侧边（平板常用）
```

注意：**没有 `.barActiveColor()` 这种链式属性**——样式都在 BarStyle 与 Tabs 属性里，写错属性名直接编译报错。

## 切换控制与懒加载

```typescript
@State current: number = 0;

Tabs({ index: this.current, barPosition: BarPosition.End }) {
  // TabContent 们
}
.onChange((index: number) => {
  this.current = index;
})
```

1. **受控切换**：`index` 传状态进去，`onChange` 同步回来，外部按钮也能切页签；
2. **懒加载**：TabContent 默认首切才创建——重内容页（统计、题库）放在非默认页签里，冷启动不背这个包袱；
3. **切换钩子**：`onChange` 里做轻逻辑（打点、刷新标题），重活交给页签组件自己的 `aboutToAppear`。

## Tabs + Navigation 的标准架构

```
Navigation（页面路由层）
 └── Tabs（主界面分栏）
      ├── TabContent: 学习页
      ├── TabContent: 知识库页
      └── TabContent: 我的页
```

- **Tabs 管平级分栏**（三个平级主页）；
- **Navigation 管层级跳转**（主页 → 详情/设置/搜索）；
- 别用 Tabs 的页签去模拟「返回」语义——层级导航交给路由栈。

## 踩坑记录

| 症状 | 原因 |
|---|---|
| 页签不显示 | TabContent 缺 `.tabBar()` |
| 图标不显示 | 资源名写错，或用了不存在的 `sys.media` 名 |
| 底部页签跑顶部 | `barPosition` 没设 `BarPosition.End` |
| 切换时白屏 | 页签内容未懒加载就加载超大列表 |

## 一句话总结

**Tabs 管平级，Navigation 管层级**：底部导航交给 BottomTabBarStyle，切页状态交给 index 受控，主界面架构一次到位。
