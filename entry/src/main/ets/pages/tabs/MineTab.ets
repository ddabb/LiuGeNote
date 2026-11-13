/**
 * 我的 Tab：阅读统计仪表盘 → 答题统计 → 成就徽章墙（10 枚，本地数据派生）
 * → 错题本 / 设置入口。
 * 数据刷新：Index.onPageShow 自增 refreshTick，经 @Prop @Watch 触发重载。
 */
import { PageHeader } from '../../common/PageHeader';
import { AppTheme, ThemePalette } from '../../common/AppTheme';
import { StatsDashboard } from '../../common/StatsDashboard';
import { AchievementDef, AchievementManager } from '../../core/AchievementManager';
import { ReadingStats, ReadingTracker } from '../../core/ReadingTracker';
import { QuizManager } from '../../core/QuizManager';
import { DataRepository } from '../../data/DataRepository';
import { ArticleMeta } from '../../model/ArticleModels';

@Component
export struct MineTab {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @Prop @Watch('onTickChange') refreshTick: number = 0;
  @State stats: ReadingStats = new ReadingStats();
  @State achievements: AchievementDef[] = [];
  @State answeredTotal: number = 0;
  @State correctTotal: number = 0;
  @State wrongCount: number = 0;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.reload();
  }

  private onTickChange(): void {
    this.reload();
  }

  private reload(): void {
    try {
      const articles: ArticleMeta[] = DataRepository.getInstance().getAllArticles();
      this.stats = ReadingTracker.getStats(articles);
      this.achievements = AchievementManager.evaluate();
      this.answeredTotal = QuizManager.getAnsweredTotal();
      this.correctTotal = QuizManager.getCorrectTotal();
      this.wrongCount = QuizManager.getWrongCount();
    } catch (e) {
      console.error('[MineTab] reload failed: ' + (e as Error).message);
    }
  }

  /** 已解锁成就数（页头副标题用） */
  private unlockedCount(): number {
    return AchievementManager.unlockedCount(this.achievements);
  }

  build() {
    Column() {
      Column() {
        PageHeader({
          title: '我的',
          subtitle: this.achievements.length > 0
            ? `已点亮 ${this.unlockedCount()} / ${this.achievements.length} 枚成就`
            : ''
        })
      }
      .width('100%')
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      Scroll() {
        Column({ space: 12 }) {
          StatsDashboard({
            todayMinutes: Math.round(this.stats.todaySeconds / 60),
            streakDays: this.stats.streakDays,
            doneCount: this.stats.doneCount,
            totalCount: this.stats.totalCount
          })

          Row() {
            Text(`累计答题 ${this.answeredTotal}`)
              .fontSize(12)
              .fontColor(this.palette().desc)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(`答对 ${this.correctTotal}`)
              .fontSize(12)
              .fontColor(this.palette().desc)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(`错题 ${this.wrongCount}`)
              .fontSize(12)
              .fontColor(this.palette().desc)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .backgroundColor(this.palette().cardBg)

          this.achievementWall()

          this.entryRow('错题本', this.wrongCount > 0 ? `${this.wrongCount} 道待消灭的错题` : '答错的题目会自动收进来', () => {
            this.gotoWrongBook();
          })
          this.entryRow('设置', '主题色 / 字体 / 阅读偏好', () => {
            this.gotoSettings();
          })
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
    .width('100%')
    .height('100%')
  }

  /** 成就徽章墙：两列 Flex Wrap（解锁主题色 / 未解锁置灰） */
  @Builder
  private achievementWall() {
    Column({ space: 10 }) {
      Text('成就徽章')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().meta)
        .width('100%')
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Start
      }) {
        ForEach(this.achievements, (d: AchievementDef) => {
          this.badgeCell(d)
        }, (d: AchievementDef) => `${d.id}_${d.unlockedAt}_${this.refreshTick}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  /** 单枚徽章：首字圆徽 + 名称 + 达成/未解锁说明 */
  @Builder
  private badgeCell(d: AchievementDef) {
    Row({ space: 10 }) {
      Text(d.name.charAt(0))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(d.unlockedAt > 0 ? '#FFFFFF' : this.palette().empty)
        .width(34)
        .height(34)
        .textAlign(TextAlign.Center)
        .borderRadius(17)
        .backgroundColor(d.unlockedAt > 0 ? this.palette().primary : '#ECEFF3')
      Column({ space: 2 }) {
        Text(d.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(d.unlockedAt > 0 ? this.palette().primaryDeep : this.palette().meta)
        Text(d.unlockedAt > 0 ? this.unlockDate(d.unlockedAt) : d.desc)
          .fontSize(10)
          .fontColor(d.unlockedAt > 0 ? this.palette().primary : this.palette().empty)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('49%')
    .padding(10)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({ width: 1, color: d.unlockedAt > 0 ? this.palette().tint : '#ECEFF3' })
  }

  /** 解锁时间展示：M月d日解锁 */
  private unlockDate(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getMonth() + 1}月${d.getDate()}日解锁`;
  }

  /** 通用入口行 */
  @Builder
  private entryRow(label: string, sub: string, onTap: () => void) {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryDeep)
        Text(sub)
          .fontSize(11)
          .fontColor(this.palette().meta)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(18)
        .fontColor(this.palette().meta)
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({ width: 1, color: this.palette().tint })
    .onClick(() => {
      onTap();
    })
  }

  private gotoWrongBook(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/WrongBookPage' });
  }

  private gotoSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
  }
}
