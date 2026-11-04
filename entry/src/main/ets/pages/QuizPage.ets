/**
 * 知识问答页：每日一题 / 随机练习 / 错题重练 三模式。
 * - 单题卡片 + 四选项点选即时判分（对绿错红）+ 解析与原文直达入口
 * - 答题记录经 QuizManager 持久化（累计/答对/错题本/每日打卡）
 * - 结算页：得分 + 答题统计 + 成就点亮进度 + 再来一组/错题重练入口
 * - 每日一题已完成时进入"已打卡"结算态（防止重复刷计数）
 * - 路由参数：{ mode: QuizManager.MODE_DAILY | MODE_PRACTICE | MODE_WRONG }
 */
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { ToastUtil } from '../common/ToastUtil';
import { QuizManager } from '../core/QuizManager';
import { AchievementManager } from '../core/AchievementManager';
import { ArticleDetailParams, QuizPageParams, QuizQuestion } from '../model/ArticleModels';

@Entry
@Component
struct QuizPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State mode: string = QuizManager.MODE_PRACTICE;
  @State questions: QuizQuestion[] = [];
  @State current: number = 0;
  /** 已选选项下标（-1 未作答） */
  @State chosen: number = -1;
  @State correctCount: number = 0;
  @State finished: boolean = false;
  @State loadError: string = '';
  @State unlockedCount: number = 0;
  @State achievementTotal: number = 0;
  @State bankTotal: number = 0;
  @State wrongCount: number = 0;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as QuizPageParams;
    if (params !== undefined && params.mode !== '') {
      this.mode = params.mode;
    }
    this.loadQuestions();
  }

  /** 按模式加载题目；每日一题已打卡时直接进结算态 */
  private loadQuestions(): void {
    try {
      this.bankTotal = QuizManager.getBank().total;
      this.wrongCount = QuizManager.getWrongCount();
      if (this.mode === QuizManager.MODE_DAILY) {
        if (QuizManager.isDailyDone()) {
          this.questions = [];
          this.finished = true;
          return;
        }
        const q: QuizQuestion | undefined = QuizManager.dailyQuestion();
        this.questions = q !== undefined ? [q] : [];
      } else if (this.mode === QuizManager.MODE_WRONG) {
        this.questions = QuizManager.wrongQuestions();
      } else {
        this.mode = QuizManager.MODE_PRACTICE;
        this.questions = QuizManager.practiceQuestions(QuizManager.PRACTICE_COUNT);
      }
      if (this.questions.length === 0 && !this.finished) {
        this.loadError = this.mode === QuizManager.MODE_WRONG
          ? '错题本是空的，答错的题目会自动收进来'
          : '题库为空：请先运行 node scripts/publish.js 生成内容数据';
      }
    } catch (e) {
      this.loadError = `题目加载失败：${(e as Error).message}`;
    }
  }

  /** 当前题（调用处保证未越界） */
  private currentQuestion(): QuizQuestion {
    return this.questions[this.current];
  }

  /** 点选选项：即时判分并记录（每题只允许作答一次） */
  private chooseOption(index: number): void {
    if (this.chosen >= 0 || this.current >= this.questions.length) {
      return;
    }
    const q: QuizQuestion = this.currentQuestion();
    this.chosen = index;
    const ok: boolean = QuizManager.recordAnswer(q, index, this.mode);
    if (ok) {
      this.correctCount++;
    } else {
      ToastUtil.show(this.getUIContext(), '答错了，已收进错题本', 1200);
    }
    this.wrongCount = QuizManager.getWrongCount();
  }

  /** 下一题 / 最后一题进结算 */
  private nextQuestion(): void {
    if (this.chosen < 0) {
      return;
    }
    if (this.current + 1 >= this.questions.length) {
      this.finishQuiz();
      return;
    }
    this.current++;
    this.chosen = -1;
  }

  /** 结算：评估成就点亮进度 */
  private finishQuiz(): void {
    this.finished = true;
    const defs = AchievementManager.evaluate();
    this.unlockedCount = AchievementManager.unlockedCount(defs);
    this.achievementTotal = defs.length;
  }

  /** 再来一组（练习模式重抽题组） */
  private restart(): void {
    this.current = 0;
    this.chosen = -1;
    this.correctCount = 0;
    this.finished = false;
    this.loadError = '';
    this.loadQuestions();
  }

  private pageTitle(): string {
    if (this.mode === QuizManager.MODE_DAILY) {
      return '每日一题';
    }
    if (this.mode === QuizManager.MODE_WRONG) {
      return '错题重练';
    }
    return '随机练习';
  }

  private pageSubtitle(): string {
    if (this.finished) {
      return '';
    }
    if (this.mode === QuizManager.MODE_DAILY) {
      return this.bankTotal > 0 ? `题库共 ${this.bankTotal} 题` : '';
    }
    if (this.mode === QuizManager.MODE_WRONG) {
      return `共 ${this.questions.length} 道错题`;
    }
    return `随机 ${this.questions.length} 题 · 题库共 ${this.bankTotal} 题`;
  }

  private resultComment(): string {
    if (this.questions.length === 0) {
      return '';
    }
    const pct: number = this.correctCount / this.questions.length;
    if (pct >= 1) {
      return '全对！知识点掌握得很扎实';
    }
    if (pct >= 0.6) {
      return '不错，再接再厉';
    }
    return '别灰心，读读原文再战一轮';
  }

  build() {
    Column() {
      PageHeader({
        title: this.pageTitle(),
        subtitle: this.pageSubtitle(),
        showBack: true
      })
      if (this.loadError !== '') {
        this.errorView()
      } else if (this.finished) {
        this.resultView()
      } else {
        this.quizView()
      }
    }
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 答题主视图：进度 + 题干 + 选项 + 判分解析 */
  @Builder
  private quizView() {
    Scroll() {
      Column({ space: 14 }) {
        Text(`第 ${this.current + 1} / ${this.questions.length} 题`)
          .fontSize(11)
          .fontColor(this.palette().meta)
          .width('100%')
        Progress({
          value: (this.current + (this.chosen >= 0 ? 1 : 0)) * 100 / this.questions.length,
          total: 100,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(3)
          .color(this.palette().primary)

        Column() {
          Text(this.currentQuestion().question)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryDeep)
            .lineHeight(24)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(14)
        .backgroundColor(this.palette().cardBg)

        ForEach(this.currentQuestion().options, (opt: string, index: number) => {
          this.optionRow(opt, index)
        }, (opt: string, index: number) => `${this.current}_${index}_${opt}`)

        if (this.chosen >= 0) {
          this.judgePanel()
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 6, bottom: 24 })
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    .width('100%')
  }

  /** 单个选项行：未答时中性色，判分后正确项绿 / 所选错误项红 */
  @Builder
  private optionRow(opt: string, index: number) {
    Row({ space: 10 }) {
      Text(this.optionBadge(index))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.optionBadgeColor(index))
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .borderRadius(13)
        .backgroundColor(this.optionBadgeBg(index))
      Text(opt)
        .fontSize(14)
        .lineHeight(20)
        .fontColor(this.optionTextColor(index))
        .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .padding({ left: 12, right: 12, top: 11, bottom: 11 })
    .borderRadius(12)
    .backgroundColor(this.optionBgColor(index))
    .border({ width: 1, color: this.optionBorderColor(index) })
    .onClick(() => {
      this.chooseOption(index);
    })
  }

  /** 判分解析面板：结论 + 出处 + 原文入口 + 下一题 */
  @Builder
  private judgePanel() {
    Column({ space: 10 }) {
      Text(this.chosen === this.currentQuestion().answer ? '回答正确' : '回答错误')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.chosen === this.currentQuestion().answer ? '#2E7D32' : '#C62828')
      Text(this.currentQuestion().explanation)
        .fontSize(12)
        .fontColor(this.palette().desc)
        .width('100%')
      Text('查看原文 ›')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().primary)
        .onClick(() => {
          this.gotoArticle(this.currentQuestion().slug);
        })
      Button(this.current + 1 >= this.questions.length ? '查看结果' : '下一题')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .height(44)
        .backgroundColor(this.palette().primary)
        .borderRadius(12)
        .margin({ top: 4 })
        .onClick(() => {
          this.nextQuestion();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(14)
    .backgroundColor(this.palette().cardBg)
  }

  /** 结算视图：得分 + 统计 + 成就进度 + 后续动作 */
  @Builder
  private resultView() {
    Scroll() {
      Column({ space: 14 }) {
        if (this.mode === QuizManager.MODE_DAILY && this.questions.length === 0) {
          Text('今日一题已完成')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryDeep)
          Text('明天再来挑战新的知识点')
            .fontSize(13)
            .fontColor(this.palette().desc)
        } else {
          Text(`${this.correctCount} / ${this.questions.length}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primary)
          Text(this.resultComment())
            .fontSize(13)
            .fontColor(this.palette().desc)
          Column({ space: 6 }) {
            Text(`累计答题 ${QuizManager.getAnsweredTotal()} 题 · 答对 ${QuizManager.getCorrectTotal()} 题`)
              .fontSize(12)
              .fontColor(this.palette().meta)
            Text(`成就进度：已点亮 ${this.unlockedCount} / ${this.achievementTotal} 枚`)
              .fontSize(12)
              .fontColor(this.palette().meta)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .borderRadius(12)
          .backgroundColor(this.palette().tint)

          if (this.mode === QuizManager.MODE_PRACTICE) {
            this.primaryButton('再来一组', () => {
              this.restart();
            })
          }
          if (this.wrongCount > 0) {
            this.primaryButton(`重练错题本（${this.wrongCount} 题）`, () => {
              this.gotoWrongPractice();
            })
          }
        }
        this.plainButton('返回', () => {
          this.getUIContext().getRouter().back();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    .width('100%')
  }

  /** 空态/错误视图 */
  @Builder
  private errorView() {
    Column({ space: 8 }) {
      Text('暂不能答题')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().error)
      Text(this.loadError)
        .fontSize(13)
        .fontColor(this.palette().desc)
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
    .padding(24)
  }

  /** 主题色主按钮 */
  @Builder
  private primaryButton(label: string, onTap: () => void) {
    Button(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .height(44)
      .backgroundColor(this.palette().primary)
      .borderRadius(12)
      .onClick(() => {
        onTap();
      })
  }

  /** 浅色次按钮 */
  @Builder
  private plainButton(label: string, onTap: () => void) {
    Button(label)
      .fontSize(15)
      .width('100%')
      .height(44)
      .fontColor(this.palette().primaryDeep)
      .backgroundColor(this.palette().tint)
      .borderRadius(12)
      .onClick(() => {
        onTap();
      })
  }

  /* ---------------- 选项配色派生（判分状态驱动） ---------------- */

  private answered(): boolean {
    return this.chosen >= 0;
  }

  private isCorrectOption(index: number): boolean {
    return index === this.currentQuestion().answer;
  }

  private optionBadge(index: number): string {
    const letters: string = 'ABCD';
    if (!this.answered()) {
      return letters.charAt(index);
    }
    if (this.isCorrectOption(index)) {
      return '✓';
    }
    if (index === this.chosen) {
      return '✗';
    }
    return letters.charAt(index);
  }

  private optionBadgeColor(index: number): string {
    if (this.answered() && (this.isCorrectOption(index) || index === this.chosen)) {
      return '#FFFFFF';
    }
    if (!this.answered()) {
      return this.palette().primary;
    }
    return this.palette().meta;
  }

  private optionBadgeBg(index: number): string {
    if (this.answered() && this.isCorrectOption(index)) {
      return '#43A047';
    }
    if (this.answered() && index === this.chosen) {
      return '#C62828';
    }
    if (!this.answered()) {
      return this.palette().tint;
    }
    return '#ECEFF3';
  }

  private optionTextColor(index: number): string {
    if (this.answered() && this.isCorrectOption(index)) {
      return '#1B5E20';
    }
    if (this.answered() && index === this.chosen) {
      return '#B71C1C';
    }
    if (!this.answered()) {
      return this.palette().desc;
    }
    return this.palette().meta;
  }

  private optionBgColor(index: number): string {
    if (this.answered() && this.isCorrectOption(index)) {
      return '#EDF7ED';
    }
    if (this.answered() && index === this.chosen) {
      return '#FDECEA';
    }
    return this.palette().cardBg;
  }

  private optionBorderColor(index: number): string {
    if (this.answered() && this.isCorrectOption(index)) {
      return '#43A047';
    }
    if (this.answered() && index === this.chosen) {
      return '#C62828';
    }
    return '#ECEFF3';
  }

  /* ---------------- 跳转 ---------------- */

  private gotoArticle(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  private gotoWrongPractice(): void {
    const params: QuizPageParams = { mode: QuizManager.MODE_WRONG };
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/QuizPage', params: params });
  }
}
