/**
 * 通用文章卡片：首页 / 标签详情 / 分类详情 共用的列表项组件。
 * 只依赖 ArticleMeta 模型；跳转行为由父页面通过回调注入。
 */
import { ArticleMeta, createEmptyArticleMeta } from '../model/ArticleModels';

const COLOR_TITLE = '#1A237E';
const COLOR_DESC = '#546E7A';
const COLOR_META = '#90A4AE';
const COLOR_CATEGORY = '#0D47A1';
const COLOR_CATEGORY_BG = '#E3F2FD';
const COLOR_TAG = '#546E7A';
const COLOR_TAG_BG = '#F0F3F5';
const CARD_BG = '#FFFFFF';

@Component
export struct ArticleCard {
  @Prop article: ArticleMeta = createEmptyArticleMeta();
  onTap: () => void = () => {
  };
  onTagTap: (tag: string) => void = () => {
  };
  onCategoryTap: (category: string) => void = () => {
  };

  build() {
    Column({ space: 10 }) {
      // 标题 + 摘要（点击进详情）
      Column({ space: 6 }) {
        Text(this.article.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TITLE)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.article.description)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(COLOR_DESC)
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
          .fontColor(COLOR_CATEGORY)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(COLOR_CATEGORY_BG)
          .borderRadius(10)
          .margin({ right: 6, bottom: 4 })
          .onClick(() => this.onCategoryTap(this.article.category))
        ForEach(this.article.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontColor(COLOR_TAG)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(COLOR_TAG_BG)
            .borderRadius(10)
            .margin({ right: 6, bottom: 4 })
            .onClick(() => this.onTagTap(tag))
        }, (tag: string) => tag)
      }
      .width('100%')

      // 元信息
      Text(`${this.article.wordCount} 字 · 更新于 ${this.datePart(this.article.updateTime)}`)
        .fontSize(11)
        .fontColor(COLOR_META)
    }
    .padding(14)
    .borderRadius(12)
    .backgroundColor(CARD_BG)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** ISO 时间取日期部分 */
  private datePart(iso: string): string {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }
}
