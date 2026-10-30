---
title: rawfile 资源读取：Uint8Array 解码与资源管理器缓存实践
category: 数据与渲染
tags: [rawfile, 资源管理, 编码, UTF-8, 缓存]
description: 记录离线应用读取 rawfile 数据的完整踩坑过程：getRawFileContent 返回 Uint8Array 的解码、TextDecoder 指定 UTF-8 避免 BOM 乱码、大文件按需加载与内存缓存策略。
---

# rawfile 资源读取：Uint8Array 解码与资源管理器缓存实践

本应用是纯离线应用，所有内容数据都打包在 `resources/rawfile/` 中。读取过程踩了三个坑。

## 坑一：getRawFileContent 返回的不是字符串

### 现象

```typescript
const buf = context.resourceManager.getRawFileContent('index.json');
JSON.parse(buf);   // ❌ 编译报错：Uint8Array 不能赋给 string
```

`getRawFileContent` 返回 `Uint8Array`，必须显式解码。同步接口 `getRawFileContent` 之外还有异步的 `getRawFileContentAsync`，数据量大时用异步避免阻塞 UI。

### 解决

```typescript
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

function readText(context: Context, path: string): string {
  const buf: Uint8Array = context.resourceManager.getRawFileContent(path);
  const textDecoder = util.TextDecoder.create('utf-8', {
    ignoreBOM: false   // 显式吞掉 BOM，避免首字符出现 \uFEFF
  });
  return textDecoder.decodeToString(buf);
}
```

## 坑二：UTF-8 BOM 导致 JSON.parse 失败

Windows 下用 Node 写文件时，若内容以 `\uFEFF` 开头，`JSON.parse` 会直接抛 `SyntaxError`。两道保险：

1. 读取端：`TextDecoder` 的 `ignoreBOM: false` 会**自动剥离** BOM；
2. 写入端：`publish.js` 统一用 `fs.writeFile(path, str, 'utf8')`，绝不手拼 BOM。

参考项目 `publish.js` 的 front-matter 正则里也有 `(\uFEFF)?` 这样的容错，说明这是跨平台内容处理的通病。

## 坑三：重复读取带来的性能抖动

首页、标签页、分类页都会读 `index.json`。最初每个页面 `aboutToAppear` 各读一次，页面切换时出现可感知的卡顿。

### 解决：DataRepository 进程级缓存

```typescript
export class DataRepository {
  private static instance: DataRepository | null = null;
  private indexCache: ArticleIndex | null = null;
  private articleCache: Map<string, string> = new Map();  // slug -> 正文

  static getInstance(): DataRepository {
    if (!DataRepository.instance) {
      DataRepository.instance = new DataRepository();
    }
    return DataRepository.instance;
  }
}
```

- `index.json` / `taxonomy.json`：首读缓存，之后零 IO；
- 文章正文：按需加载 + `Map` 缓存，配合容量上限防止长会话内存膨胀；
- rawfile 本身随 HAP 打包，读取走本地文件系统，无需任何权限声明。

## 读取路径速查

| 数据 | rawfile 路径 | 加载时机 |
|---|---|---|
| 文章索引 | `index.json` | 首页 aboutToAppear，缓存 |
| 标签/分类统计 | `taxonomy.json` | 列表页首次进入，缓存 |
| 文章正文 | `articles/<fileId>.md` | 打开详情页时按需 |

一个预防性设计：slug 是中文（用于展示与路由），但正文文件名不用 slug 而用
**slug 的 FNV-1a 哈希（fileId）** —— rawfile 本质是 HAP 内的 zip 条目，
中文路径在不同设备/版本上缺乏一致的兼容性承诺。构建脚本让 slug 稳定 ⇒ fileId 稳定，
路由继续传中文 slug，存储层只见 ASCII，两头都安全。slug 撞车与哈希撞车都在发布期报错拦截。

离线不是难在"读"，而是难在**把读取路径收拢到一处**，让缓存、解码、容错只写一遍。
