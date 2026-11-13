---
title: AppStorage 与 AppStorageV2：全局状态容器对比实践
tags: [ArkTS, AppStorage, AppStorageV2, 全局状态, 状态管理]
description: 对比全局状态容器 AppStorage 与 AppStorageV2 的写入读取方式、与两代组件体系的配合关系、持久化能力差异，以及全局状态的设计边界。
---

# AppStorage 与 AppStorageV2：全局状态容器对比实践

页面间、Tab 间共享的「当前主题色」「阅读字号」，靠路由参数层层传不现实。两代状态体系各配了一个全局容器。

## V1：AppStorage

```typescript
// 写入（不存在则创建）
AppStorage.setOrCreate('themeColor', '#8A2BE2');
AppStorage.setOrCreate('fontSize', 17);

// 读取
const size: number = AppStorage.get<number>('fontSize') ?? 17;

// 组件内双向绑定
@Component
struct SettingToggle {
  @StorageLink('fontSize') fontSize: number = 17;   // 双向：改它即改全局
  @StorageProp('themeColor') theme: string = '';    // 单向：本地改不影响全局
}
```

| 绑定 | 语义 |
|---|---|
| `@StorageLink` | 本地与容器**双向同步**（设置页改字号，阅读页立刻变） |
| `@StorageProp` | 容器到本地**单向**（展示型页面用） |

## V2：AppStorageV2

```typescript
import { AppStorageV2 } from '@kit.ArkUI';

@ObservedV2
class Setting {
  @Trace fontSize: number = 17;
  @Trace themeColor: string = '#8A2BE2';
}

// 类型化连接：同类型同 key 共享同一实例
let setting: Setting = AppStorageV2.connect(Setting, 'setting', () => new Setting())!;

setting.fontSize = 18;   // 属性级精准刷新
```

差异：

- **按类型连接**而不是裸字符串键——同一个类的两个连接拿到同一个实例；
- 配合 `@Trace` 做**属性级**观察，刷新粒度更细；
- `PersistenceV2` 进一步把数据落盘（V1 时代要自己接 PersistentStorage）。

## 两代容器的铁律

1. **V1 容器不放 @ObservedV2 实例**：`AppStorage.setOrCreate` 塞 V2 对象，属性变化观察不到，静默失效；
2. **V2 容器不放 V1 对象**：同理，`@Observed` 类进 `AppStorageV2` 也建立不了观察；
3. **同款数据只选一个容器**：一半页面读 AppStorage、一半读 AppStorageV2，必然出现「改了这半边那半边不动」的事故。

## 设计边界：什么才配进全局容器

**该进**：

- 跨页面、跨 Tab 的用户偏好：主题、字号、语言；
- 会话级全局标志：登录态、首启完成标记。

**不该进**：

- 单页面私状态（放大版 @State 而已，徒增耦合）；
- 大体积数据（正文、题库——容器在内存，且刷新绑定 UI）；
- 需要落盘的业务数据（走 preferences / 数据库）。

## 一句话总结

**全局容器只放「小而热」的跨页状态**：V1 配 AppStorage + StorageLink，V2 配 AppStorageV2 + Trace，两代各用各的容器，永不混装。
