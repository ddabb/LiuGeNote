---
title: hilog 分级日志：从 console.log 到正式日志体系
tags: [ArkTS, 日志, hilog, PerformanceAnalysisKit, 调试]
description: 用 @kit.PerformanceAnalysisKit 的 hilog 替代 console 打日志：级别选择、domain/tag 规划、format 参数与隐私字段脱敏，以及一份日志分级落地规范。
---

# hilog 分级日志：从 console.log 到正式日志体系

开发期随手 `console.log`，上架后日志就成了一锅粥——过滤不了、分不了级、还可能把用户数据打进系统日志。`hilog` 是官方的正式日志方案。

## 基本用法

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;        // 0x0000~0xFFFF，应用内自定义
const TAG = 'ReaderPage';

hilog.info(DOMAIN, TAG, '文章打开: %{public}s 用时 %{public}d ms', slug, cost);
hilog.warn(DOMAIN, TAG, '题库加载失败，降级空题库');
hilog.error(DOMAIN, TAG, 'rawfile 读取异常: %{public}s', message);
```

## 级别怎么选

| 级别 | 用途 | 上架后保留 |
|---|---|---|
| debug | 开发期细节，变量快照 | ❌ |
| info | 关键业务节点：页面进入、操作完成 | ✅ |
| warn | 可自动恢复的异常：降级、兜底生效 | ✅ |
| error | 需要人介入的失败：文件损坏、初始化失败 | ✅ |
| fatal | 崩溃级，一般交给系统 | — |

判断标准：**这条日志将来排查线上问题时会不会看？** 不会看就是 debug，别进正式包。

## 隐私格式符：public 与 private

```typescript
// %{public}s  明文输出
// %{private}s 默认输出 <private>，需要 hilog 隐私开关才显示
hilog.info(DOMAIN, TAG, '用户搜索: %{private}s', keyword);
```

用户输入、设备标识这类数据用 `%{private}s`，默认脱敏。反过来，排障必需的 slug、耗时、计数用 `%{public}s`，否则线上日志全是 `<private>` 没法用。

## domain 与 tag 的规划

- **domain**：整个应用统一一个（如 0x0001），过滤「这个应用的所有日志」靠它；
- **tag**：按模块分：`ReaderPage`、`QuizMgr`、`DataRepo`、`PdfExport`……定位问题时 `hdc shell hilog | grep PdfExport` 一击即中；
- 别用魔法字符串散落各处，常量收拢在一个文件里。

## 三个实践习惯

1. **耗时打点成对出现**：进入/完成各一条 info，带上耗时毫秒数，性能问题有据可查；
2. **catch 里必打 error**：静默吞异常是线上黑盒的根源，至少留下错误消息；
3. **日志内容自解释**：`'加载失败: ' + e.message` 优于裸 `'error'`，半年后的你会感谢现在的你。

## 一句话总结

hilog 三件套：**domain 定应用、tag 定模块、%{private} 保隐私**。日志是写给「未来的排障者」的，分级和脱敏就是体面。
