# Markdown 渲染引擎集成（@luvi/lv-markdown-in）

> 本文档记录脚手架引入工业级 Markdown 渲染引擎的方式、用法与注意事项。
> 前身方案（手写轻量解析器）的选型过程见
> [content/mdfiles/Markdown离线渲染选型与轻量解析器实现.md](../content/mdfiles/Markdown离线渲染选型与轻量解析器实现.md)。

## 1. 为什么引入

脚手架 v1 自写了约 400 行的轻量 Markdown 解析器（标题/段落/列表/代码块/引用/表格/行内样式），
满足了最小可用，但能力边界明显：

| 能力 | 手写解析器 | lv-markdown-in |
|---|---|---|
| 基础语法（标题/列表/表格/引用/代码） | ✅ | ✅ |
| 代码高亮 | ❌ | ✅（Prism） |
| 数学公式（LaTeX） | ❌ | ✅ |
| Mermaid 图表 | ❌ | ✅ |
| 脚注 / 任务列表 / 删除线 | ❌ | ✅ |
| HTML 常用标签（含 font 快速样式） | ❌ | ✅ |
| 流式渲染 / 懒渲染 / 子线程渲染 | ❌ | ✅（3.4.2+） |
| 深色模式样式 API | ❌ | ✅ |
| 自定义插件扩展语法 | ❌ | ✅（3.4.0+） |

内容应用是"读"的生意，渲染质量决定产品上限。引入成熟引擎后，手写解析器退役删除。

## 2. 依赖引入方式（重要：禁止硬编码磁盘路径）

### 2.1 正确方式：ohpm 注册表声明

`@luvi/lv-markdown-in` 发布在公共 ohpm 仓库（`https://ohpm.openharmony.cn/ohpm/`）。
在**根目录 `oh-package.json5`** 声明版本（与 PocketToolbox 工程一致的引用方式）：

```json5
{
  "dependencies": {
    "@luvi/lv-markdown-in": "3.4.5"
  }
}
```

然后安装：

```bash
ohpm install
```

ohpm 会自动拉取其传递依赖（`@luvi/html2md`、`@cangjie-tpc/formula_hybrid`、
`@cangjie-tpc/prism_hybrid`），并生成 `oh-package-lock.json5` 锁定版本。

### 2.2 错误方式（禁止）

```json5
// ❌ 绝对路径引用其他工程的 oh_modules —— 机器绑定、不可协作、升级失控
"@luvi/lv-markdown-in": "file:F:/autoagc/PocketToolbox/oh_modules/@luvi/lv-markdown-in"

// ❌ 拷贝别的工程 oh_modules 目录到本项目 —— 内含编译产物与缓存，状态不可靠
```

理由：

1. `oh_modules` 是**安装产物**不是**依赖源**，任何机器执行 `ohpm install` 都应能重建；
2. 绝对路径在本机之外立即失效，违背工程可迁移性；
3. 注册表 + lock 文件才是可复现构建的正确姿势。

### 2.3 版本升级

```bash
ohpm install @luvi/lv-markdown-in@<新版本>   # 或修改 oh-package.json5 后 ohpm install
```

升级前阅读包内 `CHANGELOG.md`（oh_modules/@luvi/lv-markdown-in/CHANGELOG.md）。

## 3. 组件 API 速查

`Markdown` 组件（`@Component`，v1+v2 装饰器混合，可在 v1/v2 工程中使用）：

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| controller | MarkdownController | 否 | 样式控制、图片/超链接点击拦截、懒渲染等 |
| text | string | 否 | Markdown 文本内容 |
| mode | 'text' \| 'rawfile' \| 'sandbox' | 否 | 加载模式，默认 text |
| context | Context | 条件 | mode=rawfile 时必填 |
| rawfilePath | string | 条件 | mode=rawfile 时必填 |
| sandboxPath | string | 条件 | mode=sandbox 时必填（沙箱完整路径） |
| callback | MdCallback | 否 | complete()/fail(code, message) 加载结果回调 |
| plugins | MarkdownPlugin[] | 否 | 自定义语法插件（3.4.0+） |

`MarkdownController` 常用能力（链式调用，在 aboutToAppear 配置）：

- 样式：`setTitleColor` / `setTextColor` / `setTextSize` / `setTitleSize` / `setQuoteBackgroundColor` …（70+ API）
- 性能：`setThreadRenderEnable`（子线程渲染）、`setLazyRender` + `setLazyPreloadBlockCount`（懒渲染，3.4.2+）
- 深色模式：通过 `$r('app.color.xxx')` 资源引用，随系统深浅色自动切换

## 4. 本项目接入点

- 接入位置：`entry/src/main/ets/pages/ArticleDetailPage.ets`（唯一的正文渲染入口）
- 数据流：`DataRepository.getArticleBody()` 从 rawfile 读取正文文本（front-matter 已剥离）
  → 以 `mode: 'text'` 交给 `Markdown` 组件 → 引擎解析渲染
- 未使用 `mode: 'rawfile'` 直读，原因：仓库层需要统一做缓存、fileId 拼装与错误处理

```typescript
import { Markdown } from '@luvi/lv-markdown-in';

Markdown({
  text: this.bodyText,
  mode: 'text',
  callback: {
    complete: () => {
    },
    fail: (code: number, message: string) => {
      this.loadError = `正文渲染失败（${code}）：${message}`;
    }
  }
})
```

## 5. 离线与体积注意

1. **离线安全**：引擎的 Mermaid（rawfile 内置 `mermaid.main.js`）、代码高亮等均为**包内本地资源**，
   无 CDN 依赖，断网可用 —— 与本应用"纯离线"定位兼容；
2. **体积成本**：HAR 为字节码包（byteCodeHar），附带约 4MB rawfile 资源
   （mermaid.js ≈ 3.3MB、图标若干），接入后 HAP 相应增大；正文内容不受影响；
3. **兼容性**：包声明 `compatibleSdkVersion: 12`（HarmonyOS），本项目 compatible 为 API 20，满足；
4. **资源隔离**：HAR 的 rawfile 资源运行在包自身命名空间，不会与本项目
   `rawfile/index.json`、`rawfile/articles/` 冲突。

## 6. 相关文档与链接

- 包主页：https://ohpm.openharmony.cn/#/cn/detail/@luvi%2Flv-markdown-in
- 源码仓库：https://gitee.com/luvi/lv-markdown-in.git
- 完整 API 文档：安装后阅读 `oh_modules/@luvi/lv-markdown-in/README.md`（2000+ 行，含深色模式、插件、锚点、图片代理等专题）
- 本项目设计文档：[design.md](design.md) 第 5 节"应用内数据流"
