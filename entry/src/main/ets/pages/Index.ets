/**
 * 首页框架：底部三 Tab（学习 / 知识库 / 我的）。
 * - 学习：信息流改版（统计仪表盘/每日推荐/继续阅读/每日一题/分类速览/文章流）
 * - 知识库：分类行 + 标签云 + 全部文章
 * - 我的：统计 / 答题统计 / 成就徽章墙 / 错题本入口
 * 刷新机制：onPageShow 自增 refreshTick 下发各 Tab（@Prop @Watch 触发重载），
 * 文章卡 key 拼接 tick 强制重建以刷新已读状态。
 * 桌面卡片拉起：EntryAbility 将卡片携带的 slug 暂存 AppStorage，
 * onPageShow 消费后直达文章详情（消费即清空，防止重复跳转）。
 * 宽屏适配：窗口宽度达到 BREAKPOINT_WIDE（平板/2in1 横屏）时切换为
 * 左侧导航栏 + 内容区布局；窄屏保持底部三 Tab。内容列由各页面
 * 限宽 CONTENT_MAX_WIDTH 后居中，避免宽屏左右留白失衡。
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
/** 宽屏左侧导航栏宽度（vp） */
const NAV_RAIL_WIDTH: number = 240;

@Entry
@Component
struct Index {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State currentIndex: number = TAB_STUDY;
  /** 页面重新可见的自增标记：下发各 Tab 触发数据重载（@Prop @Watch） */
  @State refreshTick: number = 0;
  /** 宽屏模式：窗口宽度达到断点后启用左侧导航栏布局 */
  @State isWide: boolean = false;
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
    Row() {
      if (this.isWide) {
        this.navRail()
      }
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
      .barHeight(this.isWide ? 0 : 56)
      .scrollable(!this.isWide)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .layoutWeight(1)
      .height('100%')
    }
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.isWide = (newArea.width as number) >= AppTheme.BREAKPOINT_WIDE;
    })
    .backgroundColor(this.palette().pageBg)
    .width('100%')
    .height('100%')
  }

  /** 宽屏左侧导航栏：应用名 + 学习/知识库/我的 导航项 */
  @Builder
  private navRail() {
    Column() {
      Text('行知')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().headerTitle)
        .width('100%')
        .padding({ left: 20, top: 30, bottom: 26 })
      this.navItem('学习', TAB_STUDY)
      this.navItem('知识库', TAB_LIBRARY)
      this.navItem('我的', TAB_MINE)
    }
    .width(NAV_RAIL_WIDTH)
    .height('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.palette().cardBg)
  }

  /** 导航项：选中主题浅底 + 深主色加粗（下标为常量，选中态直读 @State） */
  @Builder
  private navItem(title: string, index: number) {
    Text(title)
      .fontSize(16)
      .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.currentIndex === index ? this.palette().primaryDeep : this.palette().desc)
      .width('100%')
      .height(52)
      .maxLines(1)
      .textAlign(TextAlign.Start)
      .padding({ left: 16 })
      .borderRadius(14)
      .backgroundColor(this.currentIndex === index ? this.palette().tint : Color.Transparent)
      .margin({ bottom: 4 })
      .onClick(() => {
        this.currentIndex = index;
        this.tabsController.changeIndex(index);
      })
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
