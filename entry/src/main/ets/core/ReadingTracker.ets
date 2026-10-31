/**
 * 阅读闭环追踪：进度记忆 / 阅读时长 / 连续天数（纯本地 preferences，无任何网络与权限）。
 * - 进度：每篇一个整型键（0-100），重开文章恢复滚动位置；>= DONE_PCT 自动判定已读
 * - 时长：按日累计秒数（今日 + 总计），单次会话封顶 1 小时防异常累计
 * - 连续：最近活跃日链式判定（今日或昨日有阅读即延续，断链归零）
 * - 上次阅读：lastSlug 驱动首页「继续阅读」卡片
 * 借鉴 Kindle/微信读书：进度记忆 + 剩余时长 + 阅读激励，全部离线实现。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ArticleMeta } from '../model/ArticleModels';

/** 阅读统计汇总（首页副标题与继续阅读卡片用） */
export class ReadingStats {
  /** 今日阅读秒数 */
  todaySeconds: number = 0;
  /** 累计阅读分钟数 */
  totalMinutes: number = 0;
  /** 连续阅读天数（今日或昨日仍活跃时的链长，断链为 0） */
  streakDays: number = 0;
  /** 已读篇数（进度 >= DONE_PCT） */
  doneCount: number = 0;
  /** 总篇数 */
  totalCount: number = 0;
}

export class ReadingTracker {
  /** 已读判定阈值（滚动百分比 >= 此值视为读完） */
  static readonly DONE_PCT: number = 96;
  private static readonly PREF_NAME: string = 'lg_reading';
  private static readonly KEY_LAST: string = 'lastSlug';
  private static readonly KEY_TOTAL_SEC: string = 'totalSeconds';
  private static readonly KEY_STREAK_DAYS: string = 'streakDays';
  private static readonly KEY_STREAK_DATE: string = 'streakDate';
  private static readonly KEY_TODAY_SEC: string = 'todaySeconds';
  private static readonly KEY_TODAY_DATE: string = 'todayDate';
  private static readonly KEY_PROG_PREFIX: string = 'p_';
  /** 单次会话时长封顶（秒），防后台残留异常累计 */
  private static readonly SESSION_CAP_SEC: number = 3600;
  private static readonly DAY_MS: number = 86400000;

  private static store: preferences.Preferences | undefined = undefined;

  /** EntryAbility.onCreate 调用：打开偏好存储 */
  static init(context: common.Context): void {
    try {
      const opt: preferences.Options = { name: ReadingTracker.PREF_NAME };
      ReadingTracker.store = preferences.getPreferencesSync(context, opt);
    } catch (e) {
      console.error('[ReadingTracker] init failed: ' + (e as Error).message);
    }
  }

  private static num(key: string, def: number): number {
    const s = ReadingTracker.store;
    if (s === undefined) {
      return def;
    }
    return s.getSync(key, def) as number;
  }

  private static str(key: string, def: string): string {
    const s = ReadingTracker.store;
    if (s === undefined) {
      return def;
    }
    return s.getSync(key, def) as string;
  }

  private static put(key: string, value: number | string): void {
    const s = ReadingTracker.store;
    if (s === undefined) {
      return;
    }
    try {
      s.putSync(key, value);
      s.flush();
    } catch (e) {
      console.error('[ReadingTracker] persist failed: ' + (e as Error).message);
    }
  }

  /** 时间戳 -> yyyyMMdd 日键 */
  private static dateKey(ms: number): string {
    const d: Date = new Date(ms);
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const mm: string = month < 10 ? '0' + month : '' + month;
    const dd: string = day < 10 ? '0' + day : '' + day;
    return '' + d.getFullYear() + mm + dd;
  }

  /** 打开文章即登记（驱动首页「继续阅读」卡片） */
  static markOpen(slug: string): void {
    if (slug === '') {
      return;
    }
    ReadingTracker.put(ReadingTracker.KEY_LAST, slug);
  }

  /** 上次阅读的文章 slug */
  static getLastSlug(): string {
    return ReadingTracker.str(ReadingTracker.KEY_LAST, '');
  }

  /** 阅读进度（0-100 整数） */
  static getProgress(slug: string): number {
    const v: number = ReadingTracker.num(ReadingTracker.KEY_PROG_PREFIX + slug, 0);
    if (!Number.isFinite(v) || v < 0) {
      return 0;
    }
    return v > 100 ? 100 : Math.round(v);
  }

  /** 更新进度（只进不退：重开向上翻不丢最深阅读位置） */
  static setProgress(slug: string, pct: number): void {
    if (slug === '') {
      return;
    }
    const v: number = Math.round(Math.min(100, Math.max(0, pct)));
    const cur: number = ReadingTracker.getProgress(slug);
    if (v < cur && cur < 100) {
      return;
    }
    ReadingTracker.put(ReadingTracker.KEY_PROG_PREFIX + slug, v);
  }

  /** 是否已读（进度达到 DONE_PCT） */
  static isDone(slug: string): boolean {
    return ReadingTracker.getProgress(slug) >= ReadingTracker.DONE_PCT;
  }

  /** 累计一段阅读时长（秒）：今日/总计/连续天数联动更新 */
  static addSeconds(sec: number): void {
    if (sec <= 0) {
      return;
    }
    const s: number = Math.min(sec, ReadingTracker.SESSION_CAP_SEC);
    const now: number = Date.now();
    const today: string = ReadingTracker.dateKey(now);
    // 今日累计（跨日自动清零）
    let todaySec: number = ReadingTracker.num(ReadingTracker.KEY_TODAY_SEC, 0);
    const todayDate: string = ReadingTracker.str(ReadingTracker.KEY_TODAY_DATE, '');
    if (todayDate !== today) {
      todaySec = 0;
      ReadingTracker.put(ReadingTracker.KEY_TODAY_DATE, today);
    }
    ReadingTracker.put(ReadingTracker.KEY_TODAY_SEC, todaySec + s);
    // 累计总计
    ReadingTracker.put(ReadingTracker.KEY_TOTAL_SEC, ReadingTracker.num(ReadingTracker.KEY_TOTAL_SEC, 0) + s);
    // 连续天数：跨日时，昨日活跃则续链，否则重新起链
    const streakDate: string = ReadingTracker.str(ReadingTracker.KEY_STREAK_DATE, '');
    if (streakDate !== today) {
      const yesterday: string = ReadingTracker.dateKey(now - ReadingTracker.DAY_MS);
      const streak: number = streakDate === yesterday
        ? ReadingTracker.num(ReadingTracker.KEY_STREAK_DAYS, 0) + 1
        : 1;
      ReadingTracker.put(ReadingTracker.KEY_STREAK_DAYS, streak);
      ReadingTracker.put(ReadingTracker.KEY_STREAK_DATE, today);
    }
  }

  /** 汇总统计（传入全量文章用于已读计数） */
  static getStats(articles: ArticleMeta[]): ReadingStats {
    const st: ReadingStats = new ReadingStats();
    const now: number = Date.now();
    const today: string = ReadingTracker.dateKey(now);
    if (ReadingTracker.str(ReadingTracker.KEY_TODAY_DATE, '') === today) {
      st.todaySeconds = ReadingTracker.num(ReadingTracker.KEY_TODAY_SEC, 0);
    }
    st.totalMinutes = Math.floor(ReadingTracker.num(ReadingTracker.KEY_TOTAL_SEC, 0) / 60);
    const streakDate: string = ReadingTracker.str(ReadingTracker.KEY_STREAK_DATE, '');
    if (streakDate === today || streakDate === ReadingTracker.dateKey(now - ReadingTracker.DAY_MS)) {
      st.streakDays = ReadingTracker.num(ReadingTracker.KEY_STREAK_DAYS, 0);
    }
    st.totalCount = articles.length;
    for (const a of articles) {
      if (ReadingTracker.isDone(a.slug)) {
        st.doneCount++;
      }
    }
    return st;
  }
}
