
# Windows 文件名非法字符与文章 slug 清洗方案

文章正文存为 `rawfile/articles/<slug>.md`，slug 直接由 md 文件名派生。在 Windows 上踩了文件系统的坑。

## 问题：标题里的冒号进不了文件名

演示文档的标题起名 `ArkTS 严格模式：高频报错与改写`，其中文冒号没问题，
但如果用**英文冒号**（如 `rawfile: Uint8Array 解码`），`fs.writeFile` 直接报错：

```
Error: ENOENT: no such file or directory, open '...articles\rawfile: Uint8Array 解码.md'
```

Windows 文件名禁止 `\ / : * ? " < > |` 九个字符，其中 `:` 和 `?` 在技术文档标题里出现频率极高。

## 解决：对标参考项目的 sanitizeFileName

`vercel-ci/publish.js` 早有预案：

```javascript
function sanitizeFileName(name) {
  return name.replace(/[\/\\?%*:|"<>]/g, '-');
}
```

本脚手架完整沿用，并把清洗提前到 **slug 生成**阶段：

1. md 文件名 → 去 `.md` 扩展名 → `sanitizeFileName` → **slug**（稳定 ID）；
2. slug 同时用于 `index.json` 的 `slug` 字段与 `articles/<slug>.md` 的文件名；
3. 路由跳转只传 slug，slug 即文章身份。

## slug 稳定性设计

重跑 `publish.js` 会全量重写 `articles/`，slug 必须保证**跨版本稳定**：

| 变更 | slug 是否变化 | 影响 |
|---|---|---|
| 修改文章内容 | 否 | 无 |
| 修改 front-matter 标签 | 否 | 无 |
| 重命名 md 文件 | **是** | 等价于删旧文发新文，历史引用失效 |

因此写作规约写进 `docs/publish-workflow.md`：**发布过的文章不要改文件名**，
改内容、改元数据随意。

## 跨平台差异提醒

| 平台 | 额外限制 |
|---|---|
| Windows | `: * ? " < > |` 全部非法；结尾的点号与空格会被资源管理器吞掉 |
| Linux | 仅 `/` 非法，但换行符等控制字符易引发脚本事故 |
| HarmonyOS rawfile | 经 ZIP 打包，规则趋同 Windows |

清洗规则取三者交集最安全 —— 参考项目的正则正是这个思路（`%` 也一并清洗，
因为 `%` 在 URL 编码场景有歧义）。

## 一个隐蔽 bug：同名清洗冲突

两个标题 `问题: A` 与 `问题? A` 清洗后都变成 `问题- A`，slug 撞车后一篇会覆盖另一篇。
`publish.js` 在写 `articles/` 前做 slug 查重，撞车直接 `process.exit(1)` 并打印两处来源文件，
把冲突消灭在发布期而不是运行期。
