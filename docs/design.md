# 设计说明（Design）

## 1. 工程目录结构

```
lgnote2/                                # HarmonyOS 工程根（bundleName: com.ddabb.lgnote）
├── docs/                               # 需求与设计文档（本目录）
│   ├── README.md                       # 文档索引
│   ├── requirements.md                 # 需求说明
│   ├── design.md                       # 本文件：结构与数据设计
│   └── publish-workflow.md             # 发布流程与 publish.js 用法
├── content/
│   └── mdfiles/                        # ★ 内容源：Markdown 文档（带 front-matter）
├── scripts/
│   └── publish.js                      # ★ 发布脚本：md → rawfile（对标 vercel-ci/publish.js）
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets
│   │   ├── model/
│   │   │   └── ArticleModels.ets       # 数据模型：ArticleMeta / Taxonomy / MdNode 等
│   │   ├── data/
│   │   │   └── DataRepository.ets      # 数据仓库：读 rawfile、缓存、过滤查询
│   │   ├── common/
│   │   │   ├── MarkdownParser.ets      # 轻量 Markdown 解析器（离线，无依赖）
│   │   │   ├── MarkdownRenderer.ets    # MdNode → ArkUI 渲染 Builder
│   │   │   └── ArticleCard.ets        # 通用文章卡片组件（各列表页复用）
│   │   └── pages/
│   │       ├── Index.ets               # 首页：文章列表 + 标签/分类入口
│   │       ├── TagListPage.ets         # 标签列表页
│   │       ├── TagDetailPage.ets       # 标签详情页
│   │       ├── CategoryListPage.ets    # 分类列表页
│   │       ├── CategoryDetailPage.ets  # 分类详情页
│   │       └── ArticleDetailPage.ets   # 文章详情页（Markdown 渲染）
│   └── resources/rawfile/              # ★ publish.js 的输出目标（应用离线数据）
│       ├── index.json                  # 文章元数据索引（含 meta.totalFiles）
│       ├── taxonomy.json               # 标签/分类统计
│       └── articles/
│           └── <slug>.md               # 每篇文章正文（front-matter 已剥离）
```

## 2. Markdown 文档源约定（content/mdfiles/*.md）

```markdown
---
title: 文章标题（缺省时取文件名去扩展名）
category: 分类名（缺省 "未分类"）
tags: [标签1, 标签2]        # 或逗号分隔字符串
description: 摘要（缺省取正文前 80 字）
---

# 正文（Markdown）...
```

- front-matter 解析规则对标 `publish.js`：`---` 围栏、YAML 子集（title/category/tags/description）。
- 正文字数统计：剥离所有空白字符后计数（与 publish.js 的 wordCount 口径一致）。
- slug：文件名去 `.md` 并清洗非法字符（`/ \ ? % * : | " < >` → `-`），是文章稳定 ID。

## 3. rawfile 数据格式（publish.js 输出）

### 3.1 `index.json` —— 文章索引

```json
{
  "meta": { "generatedAt": "ISO时间", "totalFiles": 10, "generator": "lgnote publish.js" },
  "files": [
    {
      "slug": "arkts-严格模式踩坑",
      "fileId": "0feb380f",
      "title": "…", "description": "…",
      "category": "工程与语言",
      "tags": ["ArkTS", "严格模式"],
      "wordCount": 1234,
      "createTime": "…", "updateTime": "…",
      "order": 1
    }
  ]
}
```

- `files` 按 `updateTime` 降序（对标 publish.js 排序），`order` 为序号。
- `slug`：中文名，用于路由与展示（稳定 ID）；`fileId`：slug 的 FNV-1a 32 位哈希（8 位十六进制），
  是正文文件的存储 ID —— 规避 rawfile 中文路径在不同设备上的兼容性风险（本项目踩坑预防）。
- slug 撞车与 fileId 哈希撞车在发布期直接失败（退出码 1）。

### 3.2 `taxonomy.json` —— 标签/分类统计

```json
{
  "generatedAt": "…",
  "tags":       [{ "name": "ArkTS", "count": 3 }],
  "categories": [{ "name": "工程与语言", "count": 4 }]
}
```

- 与 publish.js 的 `taxonomy` 语义一致：值为文章计数；tags 按计数降序，categories 按名称排序。

### 3.3 `articles/<fileId>.md` —— 正文

front-matter 剥离后的纯 Markdown 正文（`fileId` 见 3.1），应用内由 `MarkdownParser` 解析渲染。

## 4. 页面导航设计

```
                 ┌──────────────┐
                 │ Index 首页    │◄────────────────────┐
                 │ 文章列表      │                      │
                 └──┬────┬────┬──┘                      │
        router.pushUrl│    │    │                       │
      ┌───────────────┘    │    └────────────────┐      │
      ▼                    ▼                     ▼      │
┌───────────┐      ┌──────────────┐      ┌───────────┐  │
│TagListPage│      │CategoryList  │      │Article    │  │
│标签列表    │      │Page 分类列表 │      │DetailPage │  │
└─────┬─────┘      └──────┬───────┘      │文章详情    │  │
      │ pushUrl(tag)      │ pushUrl(cat) └──┬───┬────┘  │
      ▼                   ▼                │   │        │
┌─────────────┐   ┌────────────────┐       │   │        │
│TagDetailPage│   │CategoryDetail  │       │   │        │
│标签详情      │   │Page 分类详情   │       │   │        │
└──────┬──────┘   └───────┬────────┘       │   │        │
       │  点击文章卡片      │ 点击文章卡片     │   │        │
       └──────────┬───────┴────────────────┘   │        │
                  ▼  pushUrl(slug)              │        │
          ArticleDetailPage ◄───────────────────┘        │
          （文内标签/分类可跳详情；返回键/返回按钮逐级回退）─┘
```

- 路由参数统一为字符串：`{ slug: '…' }` / `{ tag: '…' }` / `{ category: '…' }`。
- 中文参数经 `encodeURIComponent` 编码传递，页面侧 `decodeURIComponent` 还原（规避历史踩坑）。

## 5. 应用内数据流

1. `DataRepository`（单例）在首次访问时通过 `resourceManager.getRawFileContent`
   读取 `index.json` / `taxonomy.json`，`util.TextDecoder` 以 UTF-8 解码后反序列化为模型，
   进程内缓存；文章正文按需加载、LRU 缓存。
2. 列表页向 `DataRepository` 查询：全部文章 / 按标签过滤 / 按分类过滤 / 标签统计 / 分类统计。
3. `ArticleDetailPage` 取正文 md → `MarkdownParser.parse()` 得到 `MdNode[]`
   → `MarkdownRenderer` 逐节点渲染为 ArkUI 组件（标题/段落/列表/代码块/引用/粗斜体/行内代码）。

## 6. 关键技术决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 内容存储 | rawfile 静态文件 | 离线、随包分发、构建期可校验；对标 Web 静态资源 |
| 渲染方式 | 原生 ArkUI 渲染 md | 不引入 Web 组件，无网络依赖、体积小、风格统一 |
| md 存储格式 | 纯文本 md（非预渲染 HTML） | 保持内容源中立，应用侧解析；与 publish.js 剥离 front-matter 后产物一致 |
| 路由 | `@ohos.router` 多页面 | 脚手架结构清晰、每页独立注册（main_pages.json），便于裁剪扩展 |
| 构建脚本 | 纯 Node 内置模块 | 零安装成本，任何环境可发布（参考项目需 js-yaml/ejs/xlsx 依赖） |
