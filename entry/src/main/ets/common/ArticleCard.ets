/**
 * 通用文章卡片：首页 / 标签详情 / 分类详情 共用的列表项组件。
 * 只依赖 ArticleMeta 模型；跳转行为由父页面通过回调注入。
 * 主题色经 @StorageProp 订阅 AppStorage，设置页切换即时刷新。
 * 阅读状态（已读/已读百分比）由 ReadingTracker 本地进度派生，随卡片创建时读取。
 */
import { AppTheme, ThemePalette } from './AppTheme';
import { ArticleMeta, createEmptyArticleMeta, estReadingMinutes } from '../model/ArticleModels';
import { ReadingTracker } from '../core/ReadingTracker';

@Component
export struct ArticleCard {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @Prop article: ArticleMeta = createEmptyArticleMeta();
  /** 阅读进度（0-100），创建时从本地阅读记录读取 */
  @State readPct: number = 0;
  onTap: () => void = () => {
  };
  onTagTap: (tag: string) => void = () => {
  };
  onCategoryTap: (category: string) => void = () => {
  };

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.readPct = ReadingTracker.getProgress(this.article.slug);
  }

  build() {
    Column({ space: 10 }) {
      // 标题 + 摘要（点击进详情）
      Column({ space: 6 }) {
        Text(this.article.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryDeep)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.article.description)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(this.palette().desc)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .onClick(() => this.onTap())

      // 分类 + 标签（各自可点击）
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
        Text(this.article.category)
          .fontSize(11)
          .fontColor(this.palette().primary)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.palette().tint)
          .borderRadius(10)
          .margin({ right: 6, bottom: 4 })
          .onClick(() => this.onCategoryTap(this.article.category))
        ForEach(this.article.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontColor(this.palette().desc)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#F0F3F5')
            .borderRadius(10)
            .margin({ right: 6, bottom: 4 })
            .onClick(() => this.onTagTap(tag))
        }, (tag: string) => tag)
      }
      .width('100%')

      // 元信息：字数 · 预计时长 · 更新时间 · 阅读状态
      Text(this.metaLine())
        .fontSize(11)
        .fontColor(this.palette().meta)
    }
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** 元信息行：字数/预计时长/更新时间 + 已读标记（已读或已读百分比） */
  private metaLine(): string {
    let line: string = `${this.article.wordCount} 字 · 约 ${estReadingMinutes(this.article.wordCount)} 分钟`
      + ` · 更新于 ${this.datePart(this.article.updateTime)}`;
    if (this.readPct >= ReadingTracker.DONE_PCT) {
      line += ' · ✓ 已读';
    } else if (this.readPct > 0) {
      line += ` · 已读 ${this.readPct}%`;
    }
    return line;
  }

  /** ISO 时间取日期部分 */
  private datePart(iso: string): string {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }
}
