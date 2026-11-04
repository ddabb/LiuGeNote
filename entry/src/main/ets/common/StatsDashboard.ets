/**
 * 阅读统计仪表盘：今日阅读分钟 / 连续天数 / 已读篇数 三格横排。
 * 学习 Tab 与我的 Tab 共用；数据由父组件传入（ReadingTracker.getStats 派生）。
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
      this.statCell('今日阅读', `${this.todayMinutes}`, '分钟')
      this.statCell('连续天数', `${this.streakDays}`, '天')
      this.statCell('已读文章', `${this.doneCount}`, `/${this.totalCount} 篇`)
    }
    .width('100%')
  }

  /** 单格统计：数值（大）+ 单位（小）+ 标签 */
  @Builder
  private statCell(label: string, value: string, unit: string) {
    Column({ space: 3 }) {
      Text() {
        Span(value)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primary)
        Span(` ${unit}`)
          .fontSize(10)
          .fontColor(this.palette().meta)
      }
      .maxLines(1)
      Text(label)
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
}
