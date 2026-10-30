---
title: DevEco Studio 工程创建与 hvigor 构建缓存问题排查
category: 环境与工程配置
tags: [DevEco, hvigor, 构建缓存]
description: 记录本脚手架初始化阶段遇到的 hvigor 构建缓存污染、增量构建失败等问题的排查过程与解决方案，涵盖 .hvigor 目录清理时机与 clean 构建的正确用法。
---

# DevEco Studio 工程创建与 hvigor 构建缓存问题排查

本脚手架初始化阶段，最先踩到的不是代码问题，而是工程构建链路的问题。本文记录 `hvigor` 构建缓存相关的完整排查过程。

## 问题一：增量构建莫名失败

### 现象

修改一处 `.ets` 文件后执行增量构建，报出与本次改动**完全无关**的编译错误，比如某个早已删除的文件仍在报错：

```
ERROR: File not found: entry/src/main/ets/pages/OldPage.ets
```

### 排查过程

1. 反复检查源码目录，确认 `OldPage.ets` 早已不存在；
2. `git status` 显示工作区干净，不存在幽灵文件；
3. 怀疑是构建产物缓存了旧的页面清单。

### 根因

hvigor 的增量构建依赖 `.hvigor` 与 `entry/build` 下的缓存索引。当文件被删除或重命名后，缓存中的**页面注册表**（`main_pages.json` 的展开产物）未同步失效，导致编译器仍尝试拉取旧文件。

### 解决方案

- 日常改动：坚持**增量构建**，速度最快；
- 仅当增量构建报出"与改动无关的错误"时，执行一次 **clean 全量构建**：

```bash
hvigorw clean
hvigorw assembleHap
```

> 经验：不要每次都 clean。全量构建耗时数倍于增量，只有在缓存污染时才值得。

## 问题二：构建产物占用与 .gitignore

脚手架初始化时忘配 `.gitignore`，导致 `build/`、`.hvigor/`、`oh_modules/` 全部进入版本库，仓库体积迅速膨胀。正确的忽略清单应包含：

```
/.hvigor/
/.idea/
/build/
/entry/build/
/oh_modules/
**/build/
**/.preview/
local.properties
```

## 问题三：多工程间 SDK 版本不一致

同一台机器上打开多个工程时，若 `build-profile.json5` 中 `compileSdkVersion` 与本机 SDK 不匹配，会出现只在特定工程复现的编译错误。建议：

1. 以 DevEco Studio 当前安装的 SDK 为准，不要手写更高的 API 版本；
2. 团队协作时在文档中**显式声明** API 版本（见 `docs/design.md`）；
3. 升级 SDK 后对老工程做一次全量 clean 构建。

## 总结

| 问题 | 触发时机 | 解法 |
|---|---|---|
| 增量构建报无关错误 | 删除/重命名文件后 | clean 全量构建 |
| 仓库体积膨胀 | 缺 .gitignore | 补齐忽略清单 |
| SDK 版本错配 | 多工程共用机器 | 声明 API 版本 + 升级后 clean |

构建链路的稳定性是脚手架的地基。先把构建问题钉死，再谈业务代码。
