import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DataRepository } from '../data/DataRepository';
import { AppTheme } from '../common/AppTheme';
import { ReadingTracker } from '../core/ReadingTracker';
import { QuizManager } from '../core/QuizManager';
import { AchievementManager } from '../core/AchievementManager';
import { KEY_PENDING_ARTICLE } from '../model/ArticleModels';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    // 注入上下文，供 DataRepository 离线读取 rawfile 数据
    DataRepository.getInstance().init(this.context);
    // 加载主题/字体偏好并播种 AppStorage（页面 @StorageProp 依赖）
    AppTheme.init(this.context);
    // 阅读闭环：进度记忆/时长统计/连续天数（纯本地 preferences）
    ReadingTracker.init(this.context);
    // 知识问答：答题记录 / 错题本 / 每日打卡（纯本地 preferences）
    QuizManager.init(this.context);
    // 成就徽章：解锁时间戳持久化
    AchievementManager.init(this.context);
    // 桌面卡片携带文章 slug 拉起：暂存 AppStorage，首页 onPageShow 消费直达详情
    this.stashCardArticle(want);
  }

  /** 单实例热启动（桌面卡片再次点击）：同样暂存待读文章 */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.stashCardArticle(want);
  }

  /** 从 want.parameters 提取卡片点击携带的 slug 暂存 AppStorage（首页消费） */
  private stashCardArticle(want: Want): void {
    const params = want.parameters;
    if (params === undefined) {
      return;
    }
    const slug = params['slug'];
    if (typeof slug === 'string' && slug !== '') {
      AppStorage.setOrCreate(KEY_PENDING_ARTICLE, slug);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}