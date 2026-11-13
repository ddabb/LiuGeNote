---
title: Image 组件与图片资源：加载、缩放与占位
tags: [ArkUI, Image, 图片加载, 占位图, 资源管理]
description: 讲解 Image 组件的资源来源三通道：资源表、网络与 PixelMap，objectFit 缩放模式选择、占位与加载失败处理、SVG 与深色模式适配，以及图片资源命名与目录规范。
---

# Image 组件与图片资源：加载、缩放与占位

图片展示看似一行代码，加载失败、拉伸变形、占位闪烁——每个坑都在等审美上线的那一刻。

## 资源来源三通道

```typescript
// 1. 资源表（随包内置：推荐默认）
Image($r('app.media.ic_bookmark'))

// 2. 网络（需 ohos.permission.INTERNET）
Image('https://example.com/cover.jpg')

// 3. 内存位图（代码生成/解码得到）
Image(this.pixelMap)
```

资源表规范：

- 文件放 `resources/base/media/`，仅小写字母数字下划线；
- `$r('app.media.xxx')` 名字必须真实存在——写错编译期就报错，这是资源表的优势；
- **不要发明 `sys.media.ohos_ic_public_*` 名字**：系统图标只用文档里确认存在的。

## objectFit：缩放模式决定气质

```typescript
Image($r('app.media.cover'))
  .width(96)
  .height(128)
  .objectFit(ImageFit.Cover)     // 关键属性
```

| 模式 | 行为 | 典型场景 |
|---|---|---|
| `Cover` | 填满容器，裁剪溢出 | 封面、头图 ★默认选它 |
| `Contain` | 完整显示，留白 | 图表、截图（不能裁） |
| `Fill` | 拉伸变形 | 几乎别用 |
| `Auto` | 原始尺寸 | 装饰小图标 |

**变形的头图十有八九是 objectFit 缺失**。固定尺寸容器 + Cover 是最稳组合。

## 占位与失败兜底

```typescript
Image(url)
  .alt($r('app.media.ic_placeholder'))    // 加载中占位图
  .onError(() => {
    this.coverFailed = true;               // 失败换默认图或降级 UI
  })
  .onComplete((msg: ImageLoadResult) => {
    console.info(`图片尺寸: ${msg.width}x${msg.height}`);
  })
```

列表场景：占位图尺寸与正式图一致，**避免加载完成后跳动**（layout 塌缩再弹开）。

## SVG 与深色适配

- SVG 放 media 目录直接支持，小图标优先 SVG（体积小、无损缩放）；
- 深色模式：`resources/dark/media/` 放同名深色版本，系统自动切换；
- 按密度适配：`base` + `xxhdpi` 等目录分发，或统一用高分辨率图让框架缩放。

## 性能与体积

1. **内置大图谨慎**：每张图直接进包体，封面类图片压缩到显示尺寸的两倍即可（Retina 余量）；
2. 列表图标用 `.interpolation(ImageInterpolation.None)` 之类属性按需调，默认配置已够用；
3. 相同图片复用同一资源名，别把同一张图存两份（`cover1.png` / `cover_2.png`）；
4. 网络图一定配占位 + 超时，弱网下裸 Image 是白块。

## 踩坑记录

| 症状 | 原因 |
|---|---|
| 图片拉伸变形 | 缺 `.objectFit(ImageFit.Cover)` |
| 编译报资源不存在 | `$r` 名字与 media 文件不匹配 |
| 网络图不显示 | 缺 INTERNET 权限或 URL 非 HTTPS |
| 加载后布局跳动 | 占位图 alt 尺寸与真实图不一致 |
| 系统图标不显示 | 猜的 `sys.media` 名不存在，查文档用真名 |

## 一句话总结

**资源表优先、Cover 保型、占位防跳**——三招覆盖图片展示九成的体面问题。
