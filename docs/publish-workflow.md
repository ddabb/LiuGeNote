# 发布流程（publish-workflow）

> 对标 `F:\SelfJob\vercel-ci\publish.js`：把 `content/mdfiles/*.md` 渲染为应用离线数据
> `entry/src/main/resources/rawfile/`。**纯 Node 内置模块实现，无需 npm install。**

## 1. 用法

```bash
node scripts/publish.js
# 可选参数：
#   --content <dir>   md 源目录（默认 content/mdfiles）
#   --out <dir>       输出目录（默认 entry/src/main/resources/rawfile）
#   --watch           监听源目录变化自动重发布
```

## 2. publish.js 能力清单（对标 vercel-ci/publish.js）

| # | 参考项目能力 | 本脚本实现 |
|---|---|---|
| 1 | 扫描 mdfiles 目录，过滤 `.md` | ✅ 递归扫描、过滤、跳过 `_` 开头文件 |
| 2 | 解析 front-matter（title/description/category/tags/goodsName） | ✅ 自实现 YAML 子集解析（无 js-yaml 依赖）；goodsName 不适用离线应用，忽略 |
| 3 | 字数统计（去空白后计数） | ✅ 同口径 `wordCount` |
| 4 | 按 mtime 降序排序 + order 序号 | ✅ 同口径 |
| 5 | `taxonomy` 分类/标签计数（generateTaxonomy） | ✅ 输出 `taxonomy.json`（数组形式：name+count） |
| 6 | `jsons/mdfiles.json` 元数据索引 | ✅ 输出 `rawfile/index.json` |
| 7 | `sanitizeFileName` 非法字符清洗 | ✅ 同规则 `/ \ ? % * : \| " < >` → `-`，slug 稳定 |
| 8 | EJS 渲染 标签/分类 列表+详情 HTML | ➡ 改由应用内页面承担（离线应用无 HTML 产物），数据已就绪 |
| 9 | md2html 正文转换 | ➡ 正文剥离 front-matter 后存 `rawfile/articles/<slug>.md`，应用内原生渲染 |
| 10 | check.json / Excel / RSS / Sitemap / SEO 检查 | ⛔ Web 专属产物，离线应用不适用；如需留存可按需扩展 |
| 11 | 无描述文章清单（NoDescriptionLists） | ✅ 控制台警告输出，便于补稿 |
| 12 | 全流程 try/catch + 退出码 | ✅ 失败 `process.exit(1)`，可接入 CI |

## 3. 输出产物

```
entry/src/main/resources/rawfile/
├── index.json          # { meta, files:[{slug,fileId,title,description,category,tags,wordCount,createTime,updateTime,order}] }
├── taxonomy.json       # { generatedAt, tags:[{name,count}], categories:[{name,count}] }
└── articles/
    └── <fileId>.md     # 每篇文章正文（front-matter 已剥离；fileId=slug 的 FNV-1a 哈希，ASCII 文件名）
```

- 发布前会**清空**输出目录下的 `articles/`，再全量重写（对标 publish.js 的 emptyDirectory），保证幂等。
- `index.json`/`taxonomy.json` 直接覆盖写。

## 4. 典型工作流

```bash
# 首次/日常写作
# 1. 新增 content/mdfiles/我的新文章.md（带 front-matter）
# 2. 发布
node scripts/publish.js
# 3. 构建运行查看效果（DevEco Studio 或 CLI）
```

## 5. 扩展指南

- **新增元数据字段**：在 front-matter 中加字段 → `extractFrontMatter` 的解析白名单补充该 key →
  `index.json` 的映射对象补充输出。
- **图片等静态资源**：可在 publish.js 中把 `content/assets/` 拷贝到 `rawfile/assets/`，
  应用内用 `resourceManager.getRawFileContent('assets/xx.png')` 加载。
- **文章分组/合集**：front-matter 加 `series` 字段，参考 tags 的统计逻辑在 publish.js 扩展。
- **接入 CI**：`node scripts/publish.js && hvigorw assembleHap`，发布失败即中断（退出码非 0）。

## 6. 与参考项目的差异总结

1. 产物形态：HTML 静态站 → ArkUI 原生页面 + rawfile 数据（离线）。
2. 依赖：js-yaml/ejs/xlsx → 零依赖（Node 内置 fs/path）。
3. 渲染时机：EJS 构建期渲染 HTML → 构建期仅做数据整形，正文在运行期由应用解析渲染。
4. SEO 类产物（RSS/Sitemap/SEO检查/Excel）在离线应用场景无意义，未迁移。
