---
title: ohpm 与 oh-package.json5：依赖管理的正确姿势
tags: [ohpm, oh-package.json5, 依赖管理, 工程配置]
description: 讲解鸿蒙包管理器 ohpm 的使用：oh-package.json5 的依赖声明、版本号语义、安装与锁定文件 oh-package-lock.json5 的作用、依赖审计与常见安装失败排查。
---

# ohpm 与 oh-package.json5：依赖管理的正确姿势

npm 之于前端，ohpm 之于鸿蒙。`oh-package.json5` 写错一个版本号，团队里每个人构建结果都不一样。

## oh-package.json5 的结构

```json5
{
  "name": "entry",
  "version": "1.1.0",
  "description": "行知阅读应用",
  "main": "Index.ets",
  "author": "",
  "license": "Apache-2.0",
  "dependencies": {           // 运行时依赖
    "@luvi/lv-markdown-in": "^3.4.5"
  },
  "devDependencies": {        // 开发期依赖（不进产物）
    "@ohos/hypium": "1.0.25"
  }
}
```

## 版本号语义

| 写法 | 含义 | 风险 |
|---|---|---|
| `3.4.5` | 精确锁定 | 最稳，升级要手动 |
| `^3.4.5` | 兼容 3.x（≥3.4.5 <4.0.0） | 常用默认 |
| `~3.4.5` | 只升补丁（3.4.x） | 保守 |
| `latest` / `*` | 任意版本 | ❌ 禁用：构建不可复现 |

**版本号 + lock 文件（oh-package-lock.json5）双保险**：lock 锁住整棵依赖树，没有 lock 的「每个人 install 结果不同」是经典事故。

## 常用命令

```bash
ohpm install                     # 按 lock 安装全部依赖
ohpm install @luvi/lv-markdown-in   # 安装并写入 dependencies
ohpm install --save-dev @ohos/hypium   # 写入 devDependencies
ohpm ls                          # 查看依赖树（审计入口）
ohpm uninstall xxx               # 卸载
```

## 三条工程纪律

1. **lock 文件必须进版本库**——它就是「依赖树快照」；
2. **升级是显式动作**：改 version → `ohpm install` → 全量回归 → 单独提交，别顺手升级；
3. **装前先看必要性**：每个依赖都是体积、构建时长、安全面三重负债——能 30 行代码自己写的工具函数，不值得引入一个库。

## 安装失败排查

| 报错 | 原因 | 处理 |
|---|---|---|
| `REQUEST_ERROR` | 网络问题/仓库地址错误 | 换源：`ohpm config set registry https://ohpm.openharmony.cn/ohpm/` |
| 版本不存在 | 版本号笔误 | `ohpm info xxx` 查真实版本 |
| peer 冲突 | 依赖间版本互斥 | 对齐主版本 |
| 权限错误 | 管理员目录 | 换用户目录或修权限 |

离线/受限网络环境，可用本地路径依赖过渡：`"@my/lib": "file:../mylib"`，但**发布前必须换回正式源**。

## dependencies vs devDependencies

- `dependencies`：打进产物，用户设备上要用——渲染库、状态管理库；
- `devDependencies`：只在开发机用——测试框架（hypium）、mock 工具。

放错位置的代价：测试框架进了 dependencies，包体白白多几百 KB。

## 一句话总结

**依赖声明要精确、lock 文件要提交、升级动作要显式**——三条纪律守住，构建可复现。
