/**
 * 阅读统计仪表盘：今日阅读分钟 / 连续天数 / 已读篇数 三格横排。
 * 学习 Tab 与我的 Tab 共用；数据由父组件传入（ReadingTracker.getStats 派生）。
 * 注意：三格必须直接绑定 @Prop 字段渲染（不能经按值传参的 @Builder 中转，
 * 否则 @Prop 更新无法穿透 @Builder 值参数，面板会冻结在首次渲染值 —— 已踩坑修复）。
 */
import { AppTheme, ThemePalette } from './AppTheme';

@Component
export struct StatsDashboard {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @Prop todayMinutes: number = 0;
  @Prop streakDays: number = 0;
  @Prop doneCount: number = 0;
  @Prop totalCount: number = 0;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  build() {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text() {
          Span(`${this.todayMinutes}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primary)
          Span(' 分钟')
            .fontSize(10)
            .fontColor(this.palette().meta)
        }
        .maxLines(1)
        Text('今日阅读')
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(12)
      .backgroundColor(this.palette().cardBg)
      .border({ width: 1, color: this.palette().tint })

      Column({ space: 3 }) {
        Text() {
          Span(`${this.streakDays}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primary)
          Span(' 天')
            .fontSize(10)
            .fontColor(this.palette().meta)
        }
        .maxLines(1)
        Text('连续天数')
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(12)
      .backgroundColor(this.palette().cardBg)
      .border({ width: 1, color: this.palette().tint })

      Column({ space: 3 }) {
        Text() {
          Span(`${this.doneCount}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primary)
          Span(` /${this.totalCount} 篇`)
            .fontSize(10)
            .fontColor(this.palette().meta)
        }
        .maxLines(1)
        Text('已读文章')
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(12)
      .backgroundColor(this.palette().cardBg)
      .border({ width: 1, color: this.palette().tint })
    }
    .width('100%')
  }
}
