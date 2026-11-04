/**
 * 成就徽章系统：10 枚徽章全部由本地数据即时派生（阅读数据来自 ReadingTracker、
 * 答题数据来自 QuizManager），无需额外存储；仅持久化"首次解锁时间"用于展示。
 * evaluate() 每次调用即时评估，新达成的徽章自动记录解锁时间戳。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ReadingTracker } from './ReadingTracker';
import { QuizManager } from './QuizManager';
import { DataRepository } from '../data/DataRepository';

/** 单枚成就定义与解锁状态 */
export class AchievementDef {
  id: string = '';
  name: string = '';
  desc: string = '';
  /** 首次解锁时间戳（0 = 未解锁） */
  unlockedAt: number = 0;
}

export class AchievementManager {
  private static readonly PREF_NAME: string = 'lg_achv';
  /** 解锁时间持久化键前缀 */
  private static readonly KEY_PREFIX: string = 'u_';

  private static store: preferences.Preferences | undefined = undefined;

  /** EntryAbility.onCreate 调用：打开偏好存储 */
  static init(context: common.Context): void {
    try {
      const opt: preferences.Options = { name: AchievementManager.PREF_NAME };
      AchievementManager.store = preferences.getPreferencesSync(context, opt);
    } catch (e) {
      console.error('[AchievementManager] init failed: ' + (e as Error).message);
    }
  }

  /**
   * 评估全部成就（顺序即展示顺序）：
   * 阅读 3 枚 / 坚持 2 枚 / 答题 2 枚 / 每日 1 枚 / 时长 1 枚 / 错题 1 枚。
   * 新达成的徽章首次调用时写入解锁时间戳。
   */
  static evaluate(): AchievementDef[] {
    const articles = DataRepository.getInstance().getAllArticles();
    const st = ReadingTracker.getStats(articles);
    const answered: number = QuizManager.getAnsweredTotal();
    const wrongCount: number = QuizManager.getWrongCount();
    const dailyEver: boolean = QuizManager.isDailyEverDone();
    const list: AchievementDef[] = [
      AchievementManager.check('done_1', '初窥门径', '读完 1 篇文章', st.doneCount >= 1),
      AchievementManager.check('done_5', '渐入佳境', '读完 5 篇文章', st.doneCount >= 5),
      AchievementManager.check('done_15', '博览群书', '读完 15 篇文章', st.doneCount >= 15),
      AchievementManager.check('streak_1', '坚持之始', '连续阅读 1 天', st.streakDays >= 1),
      AchievementManager.check('streak_7', '七日之约', '连续阅读 7 天', st.streakDays >= 7),
      AchievementManager.check('quiz_10', '小试牛刀', '累计答题 10 题', answered >= 10),
      AchievementManager.check('quiz_100', '百题斩', '累计答题 100 题', answered >= 100),
      AchievementManager.check('daily_once', '每日精进', '完成一次每日一题', dailyEver),
      AchievementManager.check('minutes_60', '学而不厌', '累计阅读 60 分钟', st.totalMinutes >= 60),
      AchievementManager.check('wrong_clear', '查漏补缺', '答过错题后清空错题本', answered >= 1 && wrongCount === 0)
    ];
    return list;
  }

  /** 已解锁数量 */
  static unlockedCount(list: AchievementDef[]): number {
    let n: number = 0;
    for (const d of list) {
      if (d.unlockedAt > 0) {
        n++;
      }
    }
    return n;
  }

  private static check(id: string, name: string, desc: string, ok: boolean): AchievementDef {
    const d: AchievementDef = new AchievementDef();
    d.id = id;
    d.name = name;
    d.desc = desc;
    if (ok) {
      d.unlockedAt = AchievementManager.unlockStamp(id);
    }
    return d;
  }

  /** 首次解锁时间戳：已持久化直接返回，否则记录当前时间并返回 */
  private static unlockStamp(id: string): number {
    const s = AchievementManager.store;
    if (s === undefined) {
      return Date.now();
    }
    const key: string = AchievementManager.KEY_PREFIX + id;
    const saved: number = s.getSync(key, 0) as number;
    if (saved > 0) {
      return saved;
    }
    const now: number = Date.now();
    try {
      s.putSync(key, now);
      s.flush();
    } catch (e) {
      console.error('[AchievementManager] persist unlock failed: ' + (e as Error).message);
    }
    return now;
  }
}
