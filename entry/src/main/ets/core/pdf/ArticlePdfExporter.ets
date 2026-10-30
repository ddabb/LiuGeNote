/**
 * 文章导出 PDF（@kit.PDFKit 从零构建）：
 * - 链路（PocketToolbox PdfComposer 真机实证）：
 *   new PdfDocument() → createDocument(A4) → insertBlankPage(inserted,A4)
 *   → addTextObject(行文本) → deletePage(inserted,1) 初始空页 → saveDocument → releaseDocument
 * - 字体：rawfile 内置字体拷贝沙箱后经 FontInfo.fontPath 使用（PDFKit 资源必须沙箱真实路径）
 * - 排版：markdown 逐行解析为带样式行（标题/引用/列表/代码块/表格/分隔线），
 *   按字符宽度估算换行、按页高自动分页；标题与 h1/h2 使用主题深色
 * - 落盘：filesDir 生成 → DocumentViewPicker.save 由用户选择位置（免权限）
 */
import { pdfService } from '@kit.PDFKit';
import { fileIo as fs, fileUri, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { ArticleMeta } from '../../model/ArticleModels';
import { FontRegistry } from '../../common/FontRegistry';

/** A4 短边（pt）。PDF 单位 72dpi，1 英寸 = 72pt */
const A4_W: number = 595;
/** A4 长边（pt） */
const A4_H: number = 842;
const MARGIN_LEFT: number = 52;
const MARGIN_RIGHT: number = 52;
const MARGIN_TOP: number = 56;
const MARGIN_BOTTOM: number = 56;

const COLOR_BODY: number = 0x212121;
const COLOR_META: number = 0x90A4AE;
const COLOR_QUOTE: number = 0x78909C;
const COLOR_CODE: number = 0x37474F;
const COLOR_SPLIT: number = 0xB0BEC5;

/** 单行排版单元 */
class PdfLine {
  text: string = '';
  size: number = 11;
  bold: boolean = false;
  color: number = COLOR_BODY;
  indentPt: number = 0;
  spaceBefore: number = 0;

  lineHeight(): number {
    return Math.round(this.size * 1.7);
  }
}

export class PdfExportResult {
  ok: boolean = false;
  path: string = '';
  errMsg: string = '';
}

export class ArticlePdfExporter {
  /** 行工厂（避免类字面量缺字段问题） */
  private static line(text: string, size: number, bold: boolean, color: number,
    indentPt: number, spaceBefore: number): PdfLine {
    const l: PdfLine = new PdfLine();
    l.text = text;
    l.size = size;
    l.bold = bold;
    l.color = color;
    l.indentPt = indentPt;
    l.spaceBefore = spaceBefore;
    return l;
  }

  /** '#RRGGBB' → 0xRRGGBB；非法回退正文色 */
  private static colorFromHex(hex: string): number {
    const h: string = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length !== 6) {
      return COLOR_BODY;
    }
    return parseInt(h, 16);
  }

  /** 单字符宽度估算（pt）：CJK 全角≈字号，ASCII≈0.5 字号 */
  private static charWidth(ch: string, size: number): number {
    const code: number = ch.charCodeAt(0);
    if (code > 0x2E80) {
      return size;
    }
    if (ch === ' ') {
      return size * 0.3;
    }
    if (ch >= 'A' && ch <= 'Z') {
      return size * 0.66;
    }
    if (ch >= '0' && ch <= '9') {
      return size * 0.52;
    }
    return size * 0.5;
  }

  /** 按估算宽度软换行（中文逐字断行） */
  private static wrapText(text: string, size: number, maxWidth: number): string[] {
    const out: string[] = [];
    let cur: string = '';
    let curW: number = 0;
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      const w: number = ArticlePdfExporter.charWidth(ch, size);
      if (curW + w > maxWidth && cur !== '') {
        out.push(cur);
        cur = ch === ' ' ? '' : ch;
        curW = ch === ' ' ? 0 : w;
        continue;
      }
      cur += ch;
      curW += w;
    }
    if (cur !== '') {
      out.push(cur);
    }
    if (out.length === 0) {
      out.push('');
    }
    return out;
  }

  /** 行内语法剥离：链接/图片保留文字，去除加粗/斜体/行内代码记号 */
  private static stripInline(src: string): string {
    let out: string = '';
    let i: number = 0;
    while (i < src.length) {
      const c: string = src.charAt(i);
      if (c === '!' && i + 1 < src.length && src.charAt(i + 1) === '[') {
        const closeParen: number = src.indexOf(')', i);
        i = closeParen > 0 ? closeParen + 1 : i + 2;
        continue;
      }
      if (c === '[') {
        const closeBracket: number = src.indexOf('](', i);
        if (closeBracket > 0) {
          const closeParen: number = src.indexOf(')', closeBracket);
          if (closeParen > 0) {
            out += src.substring(i + 1, closeBracket);
            i = closeParen + 1;
            continue;
          }
        }
      }
      if (c === '*' || c === '_' || c === '`') {
        i++;
        continue;
      }
      out += c;
      i++;
    }
    return out;
  }

  /** 文件名清洗：slug 本身已清洗过，这里兜底替换剩余非法字符 */
  private static safeName(name: string): string {
    const n: string = name.replace(new RegExp('[\\\\/:*?"<>|]', 'g'), '-').trim();
    return n !== '' ? n : 'article';
  }

  /**
   * markdown 正文 → 排版行序列。
   * 支持：标题分级、引用、有序/无序列表（含嵌套缩进）、围栏代码块、表格行、分隔线、空行段落距。
   */
  private static mdToLines(article: ArticleMeta, body: string, themeDeep: number): PdfLine[] {
    const lines: PdfLine[] = [];
    const tagText: string = article.tags.length > 0 ? article.tags.join(' / ') : '无标签';
    const dateText: string = article.updateTime.length >= 10 ? article.updateTime.substring(0, 10) : article.updateTime;
    lines.push(ArticlePdfExporter.line(article.title, 20, true, themeDeep, 0, 0));
    lines.push(ArticlePdfExporter.line(
      `${article.category} · ${tagText} · ${article.wordCount} 字 · ${dateText}`, 9.5, false, COLOR_META, 0, 6));
    lines.push(ArticlePdfExporter.line('────────────────────────────', 9, false, COLOR_SPLIT, 0, 8));

    const rawLines: string[] = body.split('\n');
    let inCode: boolean = false;
    let pendingSpace: number = 0;
    for (let i = 0; i < rawLines.length; i++) {
      const raw: string = rawLines[i];
      const t: string = raw.trim();
      if (t.startsWith('```')) {
        inCode = !inCode;
        pendingSpace = inCode ? 6 : 6;
        continue;
      }
      if (inCode) {
        if (raw !== '') {
          lines.push(ArticlePdfExporter.line(raw, 9.5, false, COLOR_CODE, 10, pendingSpace));
          pendingSpace = 0;
        }
        continue;
      }
      if (t === '') {
        pendingSpace = 5;
        continue;
      }
      if (t.startsWith('#')) {
        let level: number = 0;
        while (level < t.length && t.charAt(level) === '#') {
          level++;
        }
        const content: string = t.substring(level).trim();
        if (content !== '' && level <= 6) {
          let size: number = 12;
          if (level === 1) {
            size = 16;
          } else if (level === 2) {
            size = 14.5;
          } else if (level === 3) {
            size = 13;
          }
          const color: number = level <= 2 ? themeDeep : COLOR_BODY;
          lines.push(ArticlePdfExporter.line(content, size, true, color, 0, Math.max(pendingSpace, 8)));
          pendingSpace = 0;
          continue;
        }
      }
      if (t.startsWith('>')) {
        const content: string = ArticlePdfExporter.stripInline(t.substring(1).trim());
        lines.push(ArticlePdfExporter.line(content, 10.5, false, COLOR_QUOTE, 14, Math.max(pendingSpace, 3)));
        pendingSpace = 0;
        continue;
      }
      const leadSpaces: number = raw.length - raw.trimStart().length;
      if (t.startsWith('- ') || t.startsWith('* ') || t.startsWith('+ ')) {
        const indent: number = 12 + Math.min(leadSpaces, 6) * 5;
        const content: string = ArticlePdfExporter.stripInline(t.substring(2).trim());
        lines.push(ArticlePdfExporter.line(`•  ${content}`, 11, false, COLOR_BODY, indent, Math.max(pendingSpace, 3)));
        pendingSpace = 0;
        continue;
      }
      let digitEnd: number = -1;
      for (let k = 0; k < t.length && k < 4; k++) {
        const ch: string = t.charAt(k);
        if (ch >= '0' && ch <= '9') {
          digitEnd = k;
        } else {
          break;
        }
      }
      if (digitEnd >= 0 && digitEnd + 2 < t.length && t.charAt(digitEnd + 1) === '.' && t.charAt(digitEnd + 2) === ' ') {
        const indent: number = 12 + Math.min(leadSpaces, 6) * 5;
        const content: string = ArticlePdfExporter.stripInline(t);
        lines.push(ArticlePdfExporter.line(content, 11, false, COLOR_BODY, indent, Math.max(pendingSpace, 3)));
        pendingSpace = 0;
        continue;
      }
      if (t.startsWith('|')) {
        const isSplitRow: boolean = t.indexOf('---') >= 0;
        if (!isSplitRow) {
          lines.push(ArticlePdfExporter.line(t, 9.5, false, COLOR_CODE, 4, Math.max(pendingSpace, 3)));
        }
        pendingSpace = 0;
        continue;
      }
      if (t === '---' || t === '***' || t === '___') {
        lines.push(ArticlePdfExporter.line('────────────────────────────', 9, false, COLOR_SPLIT, 0,
          Math.max(pendingSpace, 8)));
        pendingSpace = 0;
        continue;
      }
      lines.push(ArticlePdfExporter.line(ArticlePdfExporter.stripInline(t), 11, false, COLOR_BODY, 0,
        Math.max(pendingSpace, 4)));
      pendingSpace = 0;
    }
    return lines;
  }

  /**
   * 导出主流程：markdown → A4 PDF，输出到应用沙箱 filesDir。
   * @param fontId 用户所选正文字体 id（0=系统默认时回退内置思源黑体）
   * @param themeDeepHex 主题深色 '#RRGGBB'（标题/h1/h2 用色）
   */
  static exportToSandbox(context: common.Context, article: ArticleMeta, body: string,
    fontId: number, themeDeepHex: string): PdfExportResult {
    const result: PdfExportResult = new PdfExportResult();
    let fontPath: string = FontRegistry.sandboxFontPath(context, fontId);
    if (fontPath === '') {
      fontPath = FontRegistry.sandboxFontPath(context, 1);
    }
    if (fontPath === '') {
      result.errMsg = '字体准备失败';
      return result;
    }
    const fontInfo: pdfService.FontInfo = new pdfService.FontInfo();
    fontInfo.fontPath = fontPath;
    fontInfo.fontName = '';

    const doc: pdfService.PdfDocument = new pdfService.PdfDocument();
    if (!doc.createDocument(A4_W, A4_H)) {
      result.errMsg = '创建文档失败';
      return result;
    }
    try {
      const themeDeep: number = ArticlePdfExporter.colorFromHex(themeDeepHex);
      const lines: PdfLine[] = ArticlePdfExporter.mdToLines(article, body, themeDeep);
      let inserted: number = 0;
      let page: pdfService.PdfPage = doc.insertBlankPage(inserted, A4_W, A4_H);
      inserted++;
      let yTop: number = MARGIN_TOP;
      for (let i = 0; i < lines.length; i++) {
        const line: PdfLine = lines[i];
        const lh: number = line.lineHeight();
        const maxWidth: number = A4_W - MARGIN_LEFT - MARGIN_RIGHT - line.indentPt;
        const wrapped: string[] = ArticlePdfExporter.wrapText(line.text, line.size, maxWidth);
        for (let j = 0; j < wrapped.length; j++) {
          if (j === 0) {
            yTop += line.spaceBefore;
          }
          if (yTop + lh > A4_H - MARGIN_BOTTOM) {
            page = doc.insertBlankPage(inserted, A4_W, A4_H);
            inserted++;
            yTop = MARGIN_TOP;
          }
          if (wrapped[j] !== '') {
            const style: pdfService.TextStyle = {
              fontInfo: fontInfo,
              textSize: line.size,
              textColor: line.color,
              isBold: line.bold
            };
            page.addTextObject(wrapped[j], MARGIN_LEFT + line.indentPt, A4_H - yTop - line.size, style);
          }
          yTop += lh;
        }
      }
      // createDocument 自带一张初始空页，被 insertBlankPage 顶到 inserted 位置，删除之
      const total: number = doc.getPageCount();
      if (total === inserted + 1) {
        doc.deletePage(inserted, 1);
      }
      const outPath: string = context.filesDir + '/' + ArticlePdfExporter.safeName(article.slug) + '.pdf';
      if (!doc.saveDocument(outPath)) {
        result.errMsg = '保存 PDF 失败';
        return result;
      }
      result.ok = true;
      result.path = outPath;
      return result;
    } finally {
      doc.releaseDocument();
    }
  }

  /** 系统保存器：沙箱 PDF → 用户选择的目录（免权限）。用户取消返回 false */
  static async savePdfToDocuments(context: common.UIAbilityContext, sandboxPath: string,
    fileName: string): Promise<boolean> {
    const opts: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    opts.newFileNames = [fileName];
    opts.fileSuffixChoices = ['.pdf'];
    const dp: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await dp.save(opts);
    if (uris.length === 0) {
      return false;
    }
    const src: fs.File = fs.openSync(sandboxPath, fs.OpenMode.READ_ONLY);
    const dst: fs.File = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      fs.copyFileSync(src.fd, dst.fd);
    } finally {
      fs.closeSync(src);
      fs.closeSync(dst);
    }
    return true;
  }

  /** 系统保存器：markdown 源文件 → 用户选择的目录 */
  static async saveMdToDocuments(context: common.UIAbilityContext, mdText: string,
    fileName: string): Promise<boolean> {
    const opts: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    opts.newFileNames = [fileName];
    opts.fileSuffixChoices = ['.md'];
    const dp: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await dp.save(opts);
    if (uris.length === 0) {
      return false;
    }
    const dst: fs.File = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(dst.fd, mdText);
    } finally {
      fs.closeSync(dst);
    }
    return true;
  }

  /** 系统分享面板分享沙箱 PDF */
  static sharePdf(context: common.UIAbilityContext, sandboxPath: string): void {
    const uriStr: string = fileUri.getUriFromPath(sandboxPath);
    const utdId: string = utd.getUniformDataTypeByFilenameExtension('.pdf');
    const shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdId,
      uri: uriStr
    });
    const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.on('dismiss', () => {
    });
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.SINGLE
    });
  }
}
