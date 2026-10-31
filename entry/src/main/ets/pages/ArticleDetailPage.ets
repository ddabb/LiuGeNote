/**
 * 文章详情页：front-matter 元信息 + Markdown 正文离线渲染 + 导出/分享 + 阅读闭环。
 * - 阅读画布：主题/字体/阅读背景/字号/行距五维偏好驱动（AppStorage + @Watch 即时重配）
 *   导出/分享等低频动作收纳进页头"⋯"菜单，阅读区只保留分类/标签跳转
 * - 阅读闭环（Kindle/微信读书式）：
 *   · 进度记忆：滚动比例持久化（ReadingTracker），重开自动恢复到上次位置
 *   · 时长统计：onPageShow/onPageHide 会话计时，按日累计 + 连续天数
 *   · 进度反馈：页头下细进度条 + 右下悬浮胶囊（百分比 · 剩余分钟）
 *   · 读后引导：文末「下一篇」大卡片 + 相关阅读（同分类/标签推荐）
 * - 正文渲染：@luvi/lv-markdown-in 引擎，显式开启 Mermaid / HTML 预览 / 跨文本选择复制
 * - 导出：PDF（@kit.PDFKit 从零构建，内置字体沙箱化）/ Markdown 源文件，
 *   均经系统保存器（DocumentViewPicker）落盘到用户所选目录，免权限
 * - 分享：系统分享面板（@kit.ShareKit）分享沙箱 PDF
 * - 路由参数：{ slug: encodeURIComponent 后的文章 slug }
 */
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { common } from '@kit.AbilityKit';
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ReadingBg, ThemePalette } from '../common/AppTheme';
import { FontRegistry } from '../common/FontRegistry';
import { ToastUtil } from '../common/ToastUtil';
import { ReadingTracker } from '../core/ReadingTracker';
import { ArticlePdfExporter } from '../core/pdf/ArticlePdfExporter';
import { DataRepository } from '../data/DataRepository';
import {
  ArticleDetailParams,
  ArticleMeta,
  CategoryDetailParams,
  createEmptyArticleMeta,
  estReadingMinutes,
  TagDetailParams
} from '../model/ArticleModels';

@Entry
@Component
struct ArticleDetailPage {
  @StorageProp(AppTheme.STORAGE_THEME) @Watch('onStyleChange') themeId: number = 0;
  @StorageProp(AppTheme.STORAGE_FONT) @Watch('onStyleChange') fontId: number = 0;
  @StorageProp(AppTheme.STORAGE_READ_BG) @Watch('onStyleChange') readBgId: number = 0;
  @StorageProp(AppTheme.STORAGE_TEXT_SIZE) @Watch('onStyleChange') textSize: number = AppTheme.TEXT_SIZE_DEFAULT;
  @StorageProp(AppTheme.STORAGE_LINE_SPACING) @Watch('onStyleChange') lineSpacing: number = AppTheme.LINE_SPACING_DEFAULT;
  @State article: ArticleMeta = createEmptyArticleMeta();
  @State bodyText: string = '';
  @State loadError: string = '';
  @State isLoaded: boolean = false;
  @State exportingPdf: boolean = false;
  @State exportingMd: boolean = false;
  /** 阅读进度（0-100），驱动进度条/悬浮胶囊/持久化 */
  @State readPct: number = 0;
  /** 剩余阅读分钟数（按进度折算） */
  @State remainMinutes: number = 0;
  /** 下一篇（读后引导） */
  @State nextArticle: ArticleMeta | undefined = undefined;
  /** 相关阅读（同分类/标签推荐） */
  @State relatedArticles: ArticleMeta[] = [];

  private controller: MarkdownController = new MarkdownController();
  private menuItems: MenuElement[] = [];
  private scroller: Scroller = new Scroller();
  /** 阅读区视口高度（vp，Scroll 自身测得） */
  private viewportH: number = 0;
  /** 阅读内容总高度（vp，内容根节点测得） */
  private contentH: number = 0;
  /** 待恢复的上次阅读位置（渲染完成后 scrollTo） */
  private restorePending: boolean = false;
  private restoreRatio: number = 0;
  /** 本页阅读会话起点（ms），onPageShow/onPageHide 间累计 */
  private sessionStart: number = 0;
  /** 上次进度持久化时间（节流） */
  private lastSaveAt: number = 0;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  private readingBg(): ReadingBg {
    return AppTheme.readingBgOf(this.readBgId);
  }

  aboutToAppear(): void {
    this.buildMenuItems();
    const params = this.getUIContext().getRouter().getParams() as ArticleDetailParams;
    const slug: string = params !== undefined ? decodeURIComponent(params?.slug ?? '') : '';
    if (slug === '') {
      this.loadError = '文章参数缺失';
      return;
    }
    try {
      const repo = DataRepository.getInstance();
      const meta: ArticleMeta | undefined = repo.getArticleMeta(slug);
      if (meta === undefined) {
        this.loadError = `未找到文章：${slug}`;
        return;
      }
      this.article = meta;
      // 正文为 front-matter 剥离后的 Markdown 文本，交给引擎解析渲染
      this.bodyText = repo.getArticleBody(meta);
      this.isLoaded = true;
      this.applyMarkdownStyles();
      // 阅读闭环：登记本次打开 + 恢复上次进度 + 预取读后引导
      ReadingTracker.markOpen(slug);
      this.readPct = ReadingTracker.getProgress(slug);
      this.remainMinutes = Math.max(1, Math.round(estReadingMinutes(meta.wordCount) * (100 - this.readPct) / 100));
      this.restoreRatio = this.readPct / 100;
      this.restorePending = this.readPct > 0;
      this.nextArticle = repo.getNextArticle(slug);
      this.relatedArticles = repo.getRelatedArticles(slug, 3);
      this.sessionStart = Date.now();
    } catch (e) {
      this.loadError = `文章加载失败：${(e as Error).message}`;
    }
  }

  onPageShow(): void {
    // 页面重新可见（含路由返回/回前台）：续起会话计时
    this.sessionStart = Date.now();
  }

  onPageHide(): void {
    // 页面不可见（跳其他页/回后台）：结算本次阅读会话
    this.saveSession();
  }

  aboutToDisappear(): void {
    this.saveSession();
  }

  /** 结算阅读会话：累计时长（封顶防异常）并持久化进度 */
  private saveSession(): void {
    if (!this.isLoaded || this.sessionStart === 0) {
      return;
    }
    const elapsed: number = Math.round((Date.now() - this.sessionStart) / 1000);
    this.sessionStart = Date.now();
    if (elapsed > 0) {
      ReadingTracker.addSeconds(elapsed);
    }
    this.persistProgress();
  }

  /** 进度持久化（ReadingTracker 内部只进不退） */
  private persistProgress(): void {
    if (!this.isLoaded) {
      return;
    }
    ReadingTracker.setProgress(this.article.slug, this.readPct);
    this.lastSaveAt = Date.now();
  }

  /** 滚动回调：更新进度展示 + 节流持久化（5s） */
  private onScrollChange(): void {
    this.updateProgress();
    if (Date.now() - this.lastSaveAt > 5000) {
      this.persistProgress();
    }
  }

  /** 依据滚动位置换算阅读百分比 */
  private updateProgress(): void {
    const maxExtent: number = this.contentH - this.viewportH;
    if (maxExtent <= 0) {
      // 内容不超一屏：整篇可视即读完
      this.setPct(100);
      return;
    }
    const y: number = this.scroller.currentOffset().yOffset;
    const ratio: number = Math.max(0, Math.min(1, y / maxExtent));
    this.setPct(Math.round(ratio * 100));
  }

  /** 更新进度与剩余分钟（值变化才刷新状态） */
  private setPct(pct: number): void {
    const v: number = Math.max(0, Math.min(100, pct));
    if (v === this.readPct) {
      return;
    }
    this.readPct = v;
    const totalMin: number = estReadingMinutes(this.article.wordCount);
    this.remainMinutes = Math.max(0, Math.round(totalMin * (100 - v) / 100));
  }

  /** 正文渲染完成：延迟取最终布局后恢复上次阅读位置（或整篇可视直接判读完） */
  private onRenderComplete(): void {
    setTimeout(() => {
      this.attemptRestore();
      if (!this.restorePending && this.contentH > 0 && this.contentH - this.viewportH <= 0) {
        this.setPct(100);
        this.persistProgress();
      }
    }, 300);
  }

  /** 尝试恢复滚动位置（布局高度就绪后一次性执行） */
  private attemptRestore(): void {
    if (!this.restorePending || this.contentH <= 0 || this.viewportH <= 0) {
      return;
    }
    this.restorePending = false;
    const maxExtent: number = this.contentH - this.viewportH;
    if (maxExtent > 0 && this.restoreRatio > 0) {
      this.scroller.scrollTo({ xOffset: 0, yOffset: this.restoreRatio * maxExtent });
      this.updateProgress();
    }
  }

  /** 页头"⋯"菜单：导出/分享收纳于此（低频动作不占阅读首屏） */
  private buildMenuItems(): void {
    const pdf: MenuElement = {
      value: '导出 PDF',
      action: () => {
        this.exportPdf();
      }
    };
    const md: MenuElement = {
      value: '导出 Markdown',
      action: () => {
        this.exportMarkdown();
      }
    };
    const share: MenuElement = {
      value: '分享 PDF',
      action: () => {
        this.sharePdf();
      }
    };
    this.menuItems = [pdf, md, share];
  }

  /** 主题/字体/阅读背景/字号/行距变化（含设置页返回）时重配渲染引擎样式 */
  private onStyleChange(): void {
    if (this.isLoaded) {
      this.applyMarkdownStyles();
    }
  }

  /** 按当前全部阅读偏好配置 Markdown 渲染样式（链式，官方建议 aboutToAppear 配置） */
  private applyMarkdownStyles(): void {
    const p: ThemePalette = this.palette();
    const bg: ReadingBg = this.readingBg();
    const family: string = FontRegistry.familyOf(this.fontId);
    const size: number = Math.round(this.textSize);
    const lineHeight: number = Math.round(size * this.lineSpacing);
    this.controller.setTextColor(bg.bodyText)
      .setTextSize(size)
      .setTextLineHeight(lineHeight)
      .setTitleColor(bg.dark ? p.primarySoft : p.primaryDeep)
      .setTitleSize(this.scaledTitleSizes(size))
      .setTitleLineHeight(this.scaledTitleLineHeights(size))
      .setQuoteTextColor(bg.quoteText)
      .setQuoteBorderColor(bg.dark ? p.primarySoft : p.primary)
      .setQuoteBackgroundColor(bg.quoteBg)
      .setLineColor(bg.lineColor)
      .setHyperlinkTextColor(bg.dark ? p.primarySoft : p.primary)
      // 内容能力：Mermaid / HTML 预览开满，正文支持跨文本选择复制
      .setMermaidEnable(true)
      .setHtmlPreviewEnable(true)
      .setTextSelectionEnable(true);
    if (bg.dark) {
      // 暗夜阅读下的代码/表格配色补偿（浅色方案沿用引擎默认）
      this.controller.setInlineCodeColor('#E6EDF3')
        .setInlineCodeBackgroundColor('#2E3339')
        .setTableBackgroundColor('#262A30')
        .setTableTitleBackgroundColor('#2C3138')
        .setTableTitleTextColor('#D5DAE0')
        .setTableInterleaveBackgroundColor('#22262B')
        .setTableOuterBorderColor('#3A3F45')
        .setTableInnerBorderColor('#3A3F45');
      // 注意：以下两个 API 返回 void，需独立调用不能链式
      this.controller.setTableNormalTextColor('#C6CCD4');
      this.controller.setTableInterleaveTextColor('#C6CCD4');
    }
    if (family !== '') {
      this.controller.setTextFontFamily(family);
      this.controller.setTitleFontFamily([family, family, family, family, family, family]);
    }
  }

  /** 标题字号随正文字号等比缩放（1-6 级） */
  private scaledTitleSizes(base: number): [number, number, number, number, number, number] {
    const ratios: number[] = [1.9, 1.5, 1.28, 1.12, 1.0, 0.92];
    const sizes: number[] = ratios.map((r: number) => Math.round(base * r));
    return [sizes[0], sizes[1], sizes[2], sizes[3], sizes[4], sizes[5]];
  }

  /** 标题行高随标题字号派生（1-6 级） */
  private scaledTitleLineHeights(base: number): [number, number, number, number, number, number] {
    const ratios: number[] = [1.9, 1.5, 1.28, 1.12, 1.0, 0.92];
    const heights: number[] = ratios.map((r: number) => Math.round(base * r * 1.35));
    return [heights[0], heights[1], heights[2], heights[3], heights[4], heights[5]];
  }

  /** 沙箱上下文（导出/保存/分享用） */
  private abilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  build() {
    Column() {
      PageHeader({
        title: this.isLoaded ? this.article.title : '文章详情',
        subtitle: this.isLoaded
          ? `${this.article.category} · ${this.article.wordCount} 字 · 约 ${estReadingMinutes(this.article.wordCount)} 分钟 · ${this.datePart(this.article.updateTime)}`
          : '',
        showBack: true,
        onDark: this.readingBg().dark,
        menuItems: this.menuItems
      })

      // 细进度条：阅读进度即时反馈（0 时不可见，100 时满格）
      Progress({ value: this.readPct, total: 100, type: ProgressType.Linear })
        .height(2)
        .width('100%')
        .color(this.readingBg().dark ? this.palette().primarySoft : this.palette().primary)
        .backgroundColor('#00000000')
        .visibility(this.isLoaded ? Visibility.Visible : Visibility.None)

      if (this.loadError !== '') {
        Column({ space: 8 }) {
          Text('无法打开文章')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().error)
          Text(this.loadError)
            .fontSize(13)
            .fontColor(this.palette().desc)
        }
        .padding(24)
        .width('100%')
      } else if (!this.isLoaded) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(this.palette().primary)
          Text('加载中...')
            .fontSize(13)
            .fontColor(this.palette().empty)
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%')
      } else {
        // 悬浮胶囊锚定的 Stack：Scroll 主体 + 右下阅读进度胶囊
        Stack({ alignContent: Alignment.BottomEnd }) {
          Scroll(this.scroller) {
            // 阅读画布：阅读背景作为画布底色，宽度收窄居中保证行长可读
            Column({ space: 0 }) {
              Column({ space: 14 }) {
                // 元信息行：分类 + 标签（可跳转）
                Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                  Text(this.article.category)
                    .fontSize(12)
                    .fontColor(this.readingBg().dark ? this.palette().primarySoft : this.palette().primary)
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .backgroundColor(this.readingBg().dark ? this.readingBg().chipBg : this.palette().tint)
                    .borderRadius(11)
                    .margin({ right: 6, bottom: 6 })
                    .onClick(() => {
                      this.gotoCategoryDetail(this.article.category);
                    })
                  ForEach(this.article.tags, (tag: string) => {
                    Text(`# ${tag}`)
                      .fontSize(12)
                      .fontColor(this.readingBg().dark ? this.readingBg().bodyText : this.palette().desc)
                      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                      .backgroundColor(this.readingBg().chipBg)
                      .borderRadius(11)
                      .margin({ right: 6, bottom: 6 })
                      .onClick(() => {
                        this.gotoTagDetail(tag);
                      })
                  }, (tag: string) => tag)
                }
                .width('100%')

                // Markdown 正文：lv-markdown-in 引擎渲染（五维阅读偏好经 controller 配置）
                Markdown({
                  controller: this.controller,
                  text: this.bodyText,
                  mode: 'text',
                  callback: {
                    complete: () => {
                      this.onRenderComplete();
                    },
                    fail: (code: number, message: string) => {
                      this.loadError = `正文渲染失败（${code}）：${message}`;
                    }
                  }
                })
                  .padding({ top: 2, bottom: 16 })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 8 })
              .borderRadius(16)
              .backgroundColor(this.readingBg().contentBg)
              .border({
                width: 1,
                color: this.readingBg().dark ? '#00000000' : '#ECEFF3'
              })

              // 读后引导：下一篇 + 相关阅读（读完自然衔接，replaceUrl 保持栈浅）
              Column({ space: 12 }) {
                if (this.nextArticle !== undefined) {
                  this.nextArticleCard(this.nextArticle)
                }
                if (this.relatedArticles.length > 0) {
                  Text('相关阅读')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().meta)
                  ForEach(this.relatedArticles, (rel: ArticleMeta) => {
                    this.relatedRow(rel)
                  }, (rel: ArticleMeta) => rel.slug)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding({ top: 16, bottom: 8 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 32 })
            .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
            .onAreaChange((oldArea: Area, newArea: Area) => {
              this.contentH = newArea.height as number;
              this.attemptRestore();
            })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .onScroll((xOffset: number, yOffset: number) => {
            this.onScrollChange();
          })
          .onAreaChange((oldArea: Area, newArea: Area) => {
            this.viewportH = newArea.height as number;
            this.attemptRestore();
          })
          .width('100%')
          .height('100%')

          // 阅读进度悬浮胶囊：百分比 + 剩余分钟（0/100 时隐藏）
          if (this.readPct > 0 && this.readPct < 100) {
            Text(this.readPct < ReadingTracker.DONE_PCT
              ? `${this.readPct}% · 剩约 ${Math.max(1, this.remainMinutes)} 分钟`
              : `${this.readPct}%`)
              .fontSize(11)
              .fontColor(this.readingBg().bodyText)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(`${this.readingBg().chipBg}E6`)
              .borderRadius(14)
              .margin(16)
          }
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .backgroundColor(this.readingBg().dark ? '#17191C' : this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 下一篇大卡片：读完自然衔接（replaceUrl 保持路由栈浅） */
  @Builder
  private nextArticleCard(next: ArticleMeta) {
    Column({ space: 8 }) {
      Text('下一篇')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.readingBg().dark ? this.palette().primarySoft : this.palette().primary)
      Text(next.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryDeep)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(`${next.category} · ${next.wordCount} 字 · 约 ${estReadingMinutes(next.wordCount)} 分钟`)
        .fontSize(11)
        .fontColor(this.palette().meta)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({
      width: 1,
      color: this.readingBg().dark ? '#2C3036' : '#ECEFF3'
    })
    .onClick(() => {
      this.gotoReplace(next.slug);
    })
  }

  /** 相关阅读行：标题 + 字数，点击替换当前页 */
  @Builder
  private relatedRow(rel: ArticleMeta) {
    Row({ space: 8 }) {
      Text(rel.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.readingBg().dark ? '#C6CCD4' : this.palette().desc)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(`${rel.wordCount} 字`)
        .fontSize(11)
        .fontColor(this.palette().meta)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 4, right: 4 })
    .onClick(() => {
      this.gotoReplace(rel.slug);
    })
  }

  /** ISO 时间取日期部分 */
  private datePart(iso: string): string {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  /** 导出 PDF：引擎生成沙箱文件 → 系统保存器由用户选择位置 */
  private async exportPdf(): Promise<void> {
    if (this.exportingPdf || this.exportingMd) {
      return;
    }
    this.exportingPdf = true;
    ToastUtil.show(this.getUIContext(), '正在生成 PDF...', 1200);
    try {
      const ctx: common.UIAbilityContext = this.abilityContext();
      const result = ArticlePdfExporter.exportToSandbox(
        ctx, this.article, this.bodyText, this.fontId, this.palette().primaryDeep);
      if (!result.ok) {
        console.error(`[ArticleDetail] pdf gen failed: ${result.errMsg}`);
        ToastUtil.show(this.getUIContext(), `导出失败：${result.errMsg}`, 2000);
        return;
      }
      const saved: boolean = await ArticlePdfExporter.savePdfToDocuments(
        ctx, result.path, `${this.article.slug}.pdf`);
      ToastUtil.show(this.getUIContext(), saved ? 'PDF 已保存' : '已取消保存', 1500);
    } catch (e) {
      console.error(`[ArticleDetail] pdf export error: ${(e as Error).message}\n${(e as Error).stack}`);
      ToastUtil.show(this.getUIContext(), `导出失败：${(e as Error).message}`, 2000);
    }
    this.exportingPdf = false;
  }

  /** 导出 Markdown 源文件（front-matter 已剥离的正文） */
  private async exportMarkdown(): Promise<void> {
    if (this.exportingMd || this.exportingPdf) {
      return;
    }
    this.exportingMd = true;
    try {
      const ctx: common.UIAbilityContext = this.abilityContext();
      const saved: boolean = await ArticlePdfExporter.saveMdToDocuments(
        ctx, this.bodyText, `${this.article.slug}.md`);
      ToastUtil.show(this.getUIContext(), saved ? 'Markdown 已保存' : '已取消保存', 1500);
    } catch (e) {
      ToastUtil.show(this.getUIContext(), `导出失败：${(e as Error).message}`, 2000);
    }
    this.exportingMd = false;
  }

  /** 分享 PDF：生成沙箱文件后拉起系统分享面板 */
  private sharePdf(): void {
    try {
      const ctx: common.UIAbilityContext = this.abilityContext();
      const result = ArticlePdfExporter.exportToSandbox(
        ctx, this.article, this.bodyText, this.fontId, this.palette().primaryDeep);
      if (!result.ok) {
        console.error(`[ArticleDetail] pdf gen failed: ${result.errMsg}`);
        ToastUtil.show(this.getUIContext(), `生成失败：${result.errMsg}`, 2000);
        return;
      }
      ArticlePdfExporter.sharePdf(ctx, result.path);
    } catch (e) {
      console.error(`[ArticleDetail] pdf share error: ${(e as Error).message}\n${(e as Error).stack}`);
      ToastUtil.show(this.getUIContext(), `分享失败：${(e as Error).message}`, 2000);
    }
  }

  /** 跳转：读后引导替换当前页（先结算本篇会话） */
  private gotoReplace(slug: string): void {
    this.saveSession();
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  /** 跳转：标签详情 */
  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }

  /** 跳转：分类详情 */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
