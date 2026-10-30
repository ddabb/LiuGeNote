/**
 * 内置字体注册与供给：
 * - ArkUI 通道：getFont().registerFont + $rawfile —— 供 Text/fontFamily 与 lv-markdown-in 使用
 * - 图形文本通道：text.FontCollection.loadFontSync —— 供 ArkGraphics2D 文本引擎使用
 * - PDF 供给：rawfile 字体拷贝到沙箱 filesDir/fonts，返回文件路径供 pdfService.FontInfo 使用
 * 字体来源：rawfile/font/（思源黑体 / 霞鹜文楷，均为 TTF，PDF 兼容）。
 */
import { text } from '@kit.ArkGraphics2D';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';

/** 字体条目（id 与 AppTheme.STORAGE_FONT 的取值一致） */
export class FontEntry {
  id: number = 0;
  /** 设置页展示名 */
  label: string = '';
  /** 注册 familyName（系统默认为空串） */
  familyName: string = '';
  /** rawfile 相对路径（系统默认为空串） */
  fileName: string = '';

  constructor(id: number, label: string, familyName: string, fileName: string) {
    this.id = id;
    this.label = label;
    this.familyName = familyName;
    this.fileName = fileName;
  }
}

export class FontRegistry {
  private static registered: Set<string> = new Set<string>();

  /** 可选字体清单（id=0 为系统默认） */
  static readonly ENTRIES: FontEntry[] = [
    new FontEntry(0, '系统默认', '', ''),
    new FontEntry(1, '思源黑体', 'SourceHanSansSC', 'font/SourceHanSansSC-Regular.ttf'),
    new FontEntry(2, '霞鹜文楷', 'LXGWWenKaiLite', 'font/LXGWWenKaiLite-Regular.ttf')
  ];

  /** 按 id 取字体条目；越界回退系统默认 */
  static entryOf(id: number): FontEntry {
    if (id < 0 || id >= FontRegistry.ENTRIES.length) {
      return FontRegistry.ENTRIES[0];
    }
    return FontRegistry.ENTRIES[id];
  }

  /** 按 id 取 familyName（系统默认返回空串，调用方无需设置 fontFamily） */
  static familyOf(id: number): string {
    return FontRegistry.entryOf(id).familyName;
  }

  /**
   * 注册全部内置字体（幂等）。
   * 在首个页面（Index）aboutToAppear 调用一次即可；
   * lv-markdown-in 正文与普通 Text 均可直接以 familyName 引用。
   */
  static registerAll(uiCtx: UIContext): void {
    for (let i = 0; i < FontRegistry.ENTRIES.length; i++) {
      const entry: FontEntry = FontRegistry.ENTRIES[i];
      if (entry.fileName === '' || FontRegistry.registered.has(entry.familyName)) {
        continue;
      }
      try {
        text.FontCollection.getGlobalInstance().loadFontSync(entry.familyName, 'rawfile/' + entry.fileName);
      } catch (e) {
        console.error('[FontRegistry] loadFontSync failed: ' + entry.familyName + ' ' + (e as Error).message);
      }
      try {
        uiCtx.getFont().registerFont({
          familyName: entry.familyName,
          familySrc: $rawfile(entry.fileName)
        });
        FontRegistry.registered.add(entry.familyName);
      } catch (e) {
        console.error('[FontRegistry] registerFont failed: ' + entry.familyName + ' ' + (e as Error).message);
      }
    }
  }

  /**
   * 供 PDF 导出：把 rawfile 字体拷贝到沙箱 filesDir/fonts/（幂等），返回沙箱绝对路径。
   * rawfile 不能以文件路径直接访问，pdfService.FontInfo.fontPath 需要真实文件路径
   * （参考 PocketToolbox PdfComposer：PDFKit 资源必须沙箱路径，URI/rawfile 均不可用）。
   */
  static sandboxFontPath(context: common.Context, id: number): string {
    const entry: FontEntry = FontRegistry.entryOf(id);
    if (entry.fileName === '') {
      return '';
    }
    const dir: string = context.filesDir + '/fonts';
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir, true);
    }
    const slash: number = entry.fileName.lastIndexOf('/');
    const base: string = slash >= 0 ? entry.fileName.substring(slash + 1) : entry.fileName;
    const dest: string = dir + '/' + base;
    if (fs.accessSync(dest)) {
      return dest;
    }
    try {
      const buf: Uint8Array = context.resourceManager.getRawFileContentSync(entry.fileName);
      const file: fs.File = fs.openSync(dest, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, buf.buffer);
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      console.error('[FontRegistry] copy font failed: ' + entry.fileName + ' ' + (e as Error).message);
      return '';
    }
    return dest;
  }
}
