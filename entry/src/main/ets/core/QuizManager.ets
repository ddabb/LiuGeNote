/**
 * 知识问答状态管理：题库访问 / 每日一题 / 随机练习 / 错题本（纯本地 preferences，无网络）。
 * - 题库来自 rawfile/quiz.json（手工维护的题库，经 DataRepository 读取缓存）
 * - 答题记录：累计答题数 / 答对数 / 每日一题完成日期与历史标记 / 错题 id 列表
 * - 每日一题：按日期哈希稳定选题，答完即打卡（对错都算完成，防止重复刷计数）
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { QuizBank, QuizQuestion } from '../model/ArticleModels';
import { DataRepository } from '../data/DataRepository';
import { DailyPick } from './DailyPick';

export class QuizManager {
  /** 答题模式：每日一题 */
  static readonly MODE_DAILY: string = 'daily';
  /** 答题模式：随机练习 */
  static readonly MODE_PRACTICE: string = 'practice';
  /** 答题模式：错题重练 */
  static readonly MODE_WRONG: string = 'wrong';
  /** 随机练习每组题数 */
  static readonly PRACTICE_COUNT: number = 5;

  private static readonly PREF_NAME: string = 'lg_quiz';
  private static readonly KEY_ANSWERED: string = 'answeredTotal';
  private static readonly KEY_CORRECT: string = 'correctTotal';
  private static readonly KEY_DAILY_DATE: string = 'dailyDoneDate';
  private static readonly KEY_DAILY_EVER: string = 'dailyEverDone';
  private static readonly KEY_WRONG_IDS: string = 'wrongIds';

  private static store: preferences.Preferences | undefined = undefined;

  /** EntryAbility.onCreate 调用：打开偏好存储 */
  static init(context: common.Context): void {
    try {
      const opt: preferences.Options = { name: QuizManager.PREF_NAME };
      QuizManager.store = preferences.getPreferencesSync(context, opt);
    } catch (e) {
      console.error('[QuizManager] init failed: ' + (e as Error).message);
    }
  }

  /** 题库（rawfile/quiz.json，DataRepository 缓存） */
  static getBank(): QuizBank {
    return DataRepository.getInstance().getQuiz();
  }

  static getAnsweredTotal(): number {
    return QuizManager.num(QuizManager.KEY_ANSWERED, 0);
  }

  static getCorrectTotal(): number {
    return QuizManager.num(QuizManager.KEY_CORRECT, 0);
  }

  /** 今日一题是否已打卡 */
  static isDailyDone(): boolean {
    return QuizManager.str(QuizManager.KEY_DAILY_DATE, '') === DailyPick.todayKey();
  }

  /** 是否完成过至少一次每日一题（成就「每日精进」用） */
  static isDailyEverDone(): boolean {
    return QuizManager.num(QuizManager.KEY_DAILY_EVER, 0) > 0;
  }

  /** 今日一题（按日期哈希稳定选题） */
  static dailyQuestion(): QuizQuestion | undefined {
    const qs: QuizQuestion[] = QuizManager.getBank().questions;
    const idx: number = DailyPick.pickIndex(qs.length, DailyPick.todayKey());
    return idx >= 0 ? qs[idx] : undefined;
  }

  /** 随机练习题组（Fisher-Yates 洗牌后取前 count 题） */
  static practiceQuestions(count: number): QuizQuestion[] {
    const qs: QuizQuestion[] = QuizManager.getBank().questions.slice();
    for (let i: number = qs.length - 1; i > 0; i--) {
      const j: number = Math.floor(Math.random() * (i + 1));
      const t: QuizQuestion = qs[i];
      qs[i] = qs[j];
      qs[j] = t;
    }
    return qs.slice(0, Math.min(count, qs.length));
  }

  /** 错题列表（按题库顺序回捞） */
  static wrongQuestions(): QuizQuestion[] {
    const out: QuizQuestion[] = [];
    const ids: Set<string> = QuizManager.wrongIdSet();
    if (ids.size === 0) {
      return out;
    }
    for (const q of QuizManager.getBank().questions) {
      if (ids.has(q.id)) {
        out.push(q);
      }
    }
    return out;
  }

  /** 错题数量 */
  static getWrongCount(): number {
    return QuizManager.wrongIdSet().size;
  }

  /**
   * 记录一次作答：累计计数 + 错题本维护 + 每日打卡；返回是否答对。
   * 错题本规则：答错自动收录；错题重练模式下答对自动移出。
   */
  static recordAnswer(q: QuizQuestion, chosen: number, mode: string): boolean {
    const correct: boolean = chosen === q.answer;
    QuizManager.put(QuizManager.KEY_ANSWERED, QuizManager.num(QuizManager.KEY_ANSWERED, 0) + 1);
    if (correct) {
      QuizManager.put(QuizManager.KEY_CORRECT, QuizManager.num(QuizManager.KEY_CORRECT, 0) + 1);
    }
    const wrongs: Set<string> = QuizManager.wrongIdSet();
    if (!correct) {
      wrongs.add(q.id);
    } else if (mode === QuizManager.MODE_WRONG) {
      wrongs.delete(q.id);
    }
    QuizManager.saveWrongIds(wrongs);
    if (mode === QuizManager.MODE_DAILY) {
      QuizManager.put(QuizManager.KEY_DAILY_DATE, DailyPick.todayKey());
      QuizManager.put(QuizManager.KEY_DAILY_EVER, 1);
    }
    return correct;
  }

  /** 错题 id 集合（逗号分隔持久化） */
  private static wrongIdSet(): Set<string> {
    const s: Set<string> = new Set<string>();
    const raw: string = QuizManager.str(QuizManager.KEY_WRONG_IDS, '');
    if (raw !== '') {
      for (const id of raw.split(',')) {
        if (id !== '') {
          s.add(id);
        }
      }
    }
    return s;
  }

  private static saveWrongIds(ids: Set<string>): void {
    const arr: string[] = [];
    ids.forEach((id: string) => {
      arr.push(id);
    });
    QuizManager.put(QuizManager.KEY_WRONG_IDS, arr.join(','));
  }

  private static num(key: string, def: number): number {
    const s = QuizManager.store;
    if (s === undefined) {
      return def;
    }
    return s.getSync(key, def) as number;
  }

  private static str(key: string, def: string): string {
    const s = QuizManager.store;
    if (s === undefined) {
      return def;
    }
    return s.getSync(key, def) as string;
  }

  private static put(key: string, value: number | string): void {
    const s = QuizManager.store;
    if (s === undefined) {
      return;
    }
    try {
      s.putSync(key, value);
      s.flush();
    } catch (e) {
      console.error('[QuizManager] persist failed: ' + (e as Error).message);
    }
  }
}
