---
title: ohpm 依赖安装失败与离线内容脚手架的零依赖设计
tags: [ohpm, 依赖管理, 离线应用, Node]
description: 记录脚手架构建脚本在 ohpm/npm 依赖安装失败背景下的零依赖改造过程：用 Node 内置模块替代 js-yaml、ejs 等第三方库，实现任何环境可运行的 publish.js。
---

# ohpm 依赖安装失败与离线内容脚手架的零依赖设计

参考项目 `vercel-ci` 的 `publish.js` 依赖了 `js-yaml`、`ejs`、`xlsx` 三个 npm 包。迁移到鸿蒙脚手架时，我们在内网环境装依赖屡屡失败，于是干脆做了一次**零依赖改造**。

## 问题一：内网环境 ohpm/npm 安装超时

### 现象

```
npm install js-yaml --registry=https://registry.npmjs.org
# ETIMEDOUT / ECONNREFUSED
```

内网无法直连公网 registry，配置公司私服后又遇到部分包**镜像同步缺失**（`xlsx` 的可选依赖二进制包未同步）。

### 思考：真的需要这些依赖吗

回到 `publish.js` 的实际用量逐个审视：

| 依赖 | 参考项目中的用途 | 是否可替代 |
|---|---|---|
| `js-yaml` | 解析 front-matter | 只用到 `title/category/tags/description` 四个字段的扁平 YAML，可手写 ~60 行解析器 |
| `ejs` | 渲染 HTML 列表/详情页 | 离线应用改为原生页面渲染，**构建期不再需要模板引擎** |
| `xlsx` | 导出文章信息 Excel | 内容校验产物，Web 运营场景专属，离线应用不需要 |

结论：**全部可以去掉**。构建脚本只用 Node 内置的 `fs`、`path` 模块即可。

## 零依赖 front-matter 解析器设计

参考项目的 front-matter 只有一层扁平结构，我们实现一个 YAML 子集解析：

1. 用正则匹配 `---` 围栏区域：`/^---\r?\n([\s\S]*?)\r?\n---/`；
2. 逐行按第一个冒号切分 key 与 value；
3. value 形如 `[a, b]` 的解析为标签数组；`true/false/数字` 做类型推断；其余按字符串处理；
4. 容错：非法行直接跳过并警告，不中断发布（对标参考项目的 `console.warn` 行为）。

```javascript
function parseValue(raw) {
  const s = raw.trim();
  if (s.startsWith('[') && s.endsWith(']')) {
    return s.slice(1, -1).split(',').map(x => x.trim()).filter(Boolean);
  }
  if (s === 'true') return true;
  if (s === 'false') return false;
  return s.replace(/^['"]|['"]$/g, '');
}
```

## 零依赖带来的收益

1. **任何有 Node 的机器都能发布内容**：无需 `npm install`，克隆即用；
2. **供应链安全**：不引入第三方代码，构建脚本可整体审计；
3. **速度**：省去依赖解析，`publish.js` 毫秒级完成；
4. **CI 友好**：发布步骤退化为 `node scripts/publish.js`，无需缓存 node_modules。

## 反思

"先把依赖装上再说"是惯性思维。做脚手架时应该先问：**这个依赖的哪 10% 功能被我用到了？** 尤其是构建脚本这种一次性运行的工具，零依赖往往并不困难。
