/**
 * 首页框架：底部三 Tab（学习 / 知识库 / 我的）。
 * - 学习：信息流改版（统计仪表盘/每日推荐/继续阅读/每日一题/分类速览/文章流）
 * - 知识库：分类行 + 标签云 + 全部文章
 * - 我的：统计 / 答题统计 / 成就徽章墙 / 错题本入口
 * 刷新机制：onPageShow 自增 refreshTick 下发各 Tab（@Prop @Watch 触发重载），
 * 文章卡 key 拼接 tick 强制重建以刷新已读状态。
 * 桌面卡片拉起：EntryAbility 将卡片携带的 slug 暂存 AppStorage，
 * onPageShow 消费后直达文章详情（消费即清空，防止重复跳转）。
 * 宽屏适配：内容整体限宽 CONTENT_MAX_WIDTH 居中。
 */
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { FontRegistry } from '../common/FontRegistry';
import { ArticleDetailParams, KEY_PENDING_ARTICLE } from '../model/ArticleModels';
import { LibraryTab } from './tabs/LibraryTab';
import { MineTab } from './tabs/MineTab';
import { StudyTab } from './tabs/StudyTab';

/** Tab 下标：学习 */
const TAB_STUDY: number = 0;
/** Tab 下标：知识库 */
const TAB_LIBRARY: number = 1;
/** Tab 下标：我的 */
const TAB_MINE: number = 2;

@Entry
@Component
struct Index {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State currentIndex: number = TAB_STUDY;
  /** 页面重新可见的自增标记：下发各 Tab 触发数据重载（@Prop @Watch） */
  @State refreshTick: number = 0;
  private tabsController: TabsController = new TabsController();

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    // 首页为应用入口：注册内置字体一次（幂等），供正文渲染与设置页预览使用
    FontRegistry.registerAll(this.getUIContext());
  }

  onPageShow(): void {
    this.refreshTick++;
    this.consumePendingArticle();
  }

  /** 消费桌面卡片拉起的待读文章（EntryAbility 暂存），直达详情后清空 */
  private consumePendingArticle(): void {
    const slug: string = AppStorage.get<string>(KEY_PENDING_ARTICLE) ?? '';
    if (slug === '') {
      return;
    }
    AppStorage.setOrCreate(KEY_PENDING_ARTICLE, '');
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
        TabContent() {
          StudyTab({ refreshTick: this.refreshTick })
        }
        .tabBar(this.tabBuilder('学习', TAB_STUDY))

        TabContent() {
          LibraryTab({ refreshTick: this.refreshTick })
        }
        .tabBar(this.tabBuilder('知识库', TAB_LIBRARY))

        TabContent() {
          MineTab({ refreshTick: this.refreshTick })
        }
        .tabBar(this.tabBuilder('我的', TAB_MINE))
      }
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
    }
    .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
    .backgroundColor(this.palette().pageBg)
    .width('100%')
    .height('100%')
  }

  /** 底部 Tab 项：文字 + 选中圆点指示器（主题色驱动） */
  @Builder
  private tabBuilder(title: string, index: number) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? this.palette().primary : this.palette().meta)
      Circle({ width: 5, height: 5 })
        .fill(this.palette().primary)
        .visibility(this.currentIndex === index ? Visibility.Visible : Visibility.Hidden)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
