---
title: preferences 轻量持久化：阅读进度记忆的落地方案
tags: [ArkTS, 数据持久化, preferences, @kit.ArkData]
description: 用 @kit.ArkData 的 preferences 实现阅读进度、主题偏好等轻量数据的本地持久化：同步 API 的取舍、flush 时机、异常兜底，以及一份可直接复用的存储封装思路。
---

# preferences 轻量持久化：阅读进度记忆的落地方案

应用里的「上次读到哪」「主题色选了哪个」这类数据，不值得上数据库——`preferences` 键值存储就是为它们准备的。

## 初始化：同步一次，全局复用

```typescript
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

let store: preferences.Preferences | undefined = undefined;

export function initStore(context: common.Context): void {
  const opt: preferences.Options = { name: 'reader_prefs' };
  store = preferences.getPreferencesSync(context, opt);
}
```

要点：

- 在 `EntryAbility.onCreate` 里完成，之后所有页面共用这个实例；
- 同步版 `getPreferencesSync` 一次磁盘 IO，之后读写全在内存，`flush` 时才落盘；
- 异步版 `getPreferences` 适合启动路径不敏感的场景，别混用两套。

## 读写：四则基本操作

```typescript
// 读（带默认值，避免 undefined 传染）
const percent: number = store.getSync('readPercent', 0) as number;
const slug: string = store.getSync('lastSlug', '') as string;

// 写
store.putSync('readPercent', 42);
store.flush();   // 真正落盘
```

`putSync` 只改内存，**忘记 flush 等于白写**——进程被杀后数据丢失。推荐「写后即 flush」：轻量数据量小，flush 开销可忽略，换来最坏情况只丢最后一次操作的可靠性。

## 支持的值类型

仅 `number | string | boolean`，以及元素为这些类型的一维 `Array`。想存对象：

```typescript
// ❌ 直接存对象：触发类型错误或序列化异常
store.putSync('user', { name: 'li', age: 18 });

// ✅ 存 JSON 字符串，读出后走显式类型解析
interface UserPref { name: string; age: number }
store.putSync('user', JSON.stringify({ name: 'li', age: 18 } as UserPref));
const raw: string = store.getSync('user', '') as string;
const user: UserPref = raw !== '' ? JSON.parse(raw) as UserPref : { name: '', age: 0 };
```

数组同理：`join(',')` 存字符串，读出 `split` 回捞——错题本 id 列表就是这么存的。

## 异常兜底三件套

1. **init 失败**：读操作返回默认值、写操作静默跳过，页面绝不能因存储不可用而崩溃；
2. **值类型漂移**：版本升级后旧值可能是 number 新代码按 string 读，`getSync` 后做一次 `typeof` 校验再使用；
3. **容量意识**：preferences 面向轻量数据（官方建议单条不超过若干 KB），文章正文、题库这类大块内容放 rawfile 或关系型数据库，不要塞进偏好存储。

## 什么时候该换方案

| 场景 | 方案 |
|---|---|
| 偏好、进度、小标记 | preferences |
| 结构化数据、需要查询 | @kit.ArkData relationalStore |
| 只读内置内容 | rawfile |

## 一句话总结

preferences 是「**内存 map + 显式落盘**」：init 一次、写后 flush、类型自己兜底，三件事做对就稳了。
