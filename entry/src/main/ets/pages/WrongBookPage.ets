/**
 * 错题本：答错的题目自动收录；重练答对自动移出（QuizManager 持久化，无网络）。
 * 列表项展示题干 / 正确答案 / 出处解析，支持直达原文与一键重练。
 */
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { QuizManager } from '../core/QuizManager';
import { ArticleDetailParams, QuizPageParams, QuizQuestion } from '../model/ArticleModels';

@Entry
@Component
struct WrongBookPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State wrongs: QuizQuestion[] = [];

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.reload();
  }

  /** 从答题页返回时刷新列表（重练移出的错题即时消失） */
  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.wrongs = QuizManager.wrongQuestions();
  }

  build() {
    Column() {
      PageHeader({
        title: '错题本',
        subtitle: this.wrongs.length > 0 ? `${this.wrongs.length} 道待消灭的错题` : '答错的题目会自动收进来',
        showBack: true
      })
      Scroll() {
        Column({ space: 12 }) {
          if (this.wrongs.length === 0) {
            Column({ space: 8 }) {
              Text('太棒了，错题本空空如也')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryDeep)
              Text('去「学习」页做一组随机练习，检验一下学习成果吧')
                .fontSize(12)
                .fontColor(this.palette().desc)
            }
            .padding(24)
            .width('100%')
          } else {
            ForEach(this.wrongs, (q: QuizQuestion) => {
              this.wrongCard(q)
            }, (q: QuizQuestion) => q.id)
            Button(`开始重练（${this.wrongs.length} 题）`)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .height(44)
              .backgroundColor(this.palette().primary)
              .borderRadius(12)
              .margin({ top: 4 })
              .onClick(() => {
                this.gotoPractice();
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 6, bottom: 24 })
        .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      }
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')
    }
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 错题卡：题干 + 正确答案 + 出处 + 原文直达 */
  @Builder
  private wrongCard(q: QuizQuestion) {
    Column({ space: 8 }) {
      Text(q.question)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().primaryDeep)
        .lineHeight(21)
        .width('100%')
      Column({ space: 5 }) {
        Text(`正确答案：${q.options[q.answer]}`)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#2E7D32')
        Text(q.explanation)
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(10)
      .borderRadius(10)
      .backgroundColor(this.palette().tint)
      Row() {
        Text(q.category)
          .fontSize(10)
          .fontColor(this.palette().primary)
        Blank()
        Text('查看原文 ›')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primary)
          .onClick(() => {
            this.gotoArticle(q.slug);
          })
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
  }

  private gotoArticle(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  private gotoPractice(): void {
    const params: QuizPageParams = { mode: QuizManager.MODE_WRONG };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/QuizPage', params: params });
  }
}
