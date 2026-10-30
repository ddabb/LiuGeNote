/**
 * 主题色配置：预设色板 + 阅读偏好 + 用户偏好持久化（preferences）+ AppStorage 全局共享。
 * - 色板：6 套预设（靛蓝默认 / 湛蓝 / 青碧 / 松绿 / 暖橙 / 绛紫）
 * - 阅读背景：纸白 / 羊皮纸 / 护眼 / 暗夜（仅作用于文章阅读区）
 * - 阅读排版：正文字号（14-22fp）与行距倍率（1.3-2.0）
 * - 持久化：themeId / fontId / readBgId / textSize / lineSpacing 写入应用沙箱 preferences
 * - 共享：AppStorage 同名键，页面经 @StorageProp 订阅，即时刷新
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/** 主题色板（中性色 + 主色系） */
export class ThemePalette {
  id: number = 0;
  name: string = '';
  /** 主色：按钮 / 选中态 / 进度 */
  primary: string = '#5C6BC0';
  /** 深主色：标题 / 强调文字 */
  primaryDeep: string = '#1A237E';
  /** 柔和主色：次级强调文字 / 计数徽章 */
  primarySoft: string = '#5C6BC0';
  /** 主色浅底：徽章 / chip 背景 */
  tint: string = '#E8EAF6';
  /** 页面背景 */
  pageBg: string = '#F4F6F8';
  /** 卡片背景 */
  cardBg: string = '#FFFFFF';
  /** 页头标题色 */
  headerTitle: string = '#102027';
  /** 页头副标题色 */
  headerSub: string = '#78909C';
  /** 描述文字 */
  desc: string = '#546E7A';
  /** 元信息文字 */
  meta: string = '#90A4AE';
  /** 错误提示 */
  error: string = '#C62828';
  /** 空态提示 */
  empty: string = '#9E9E9E';
}

/** 阅读背景方案：作用于文章详情页阅读区（正文底色 / 文字 / 引用 / 徽章配色） */
export class ReadingBg {
  id: number = 0;
  name: string = '';
  /** 阅读区底色 */
  contentBg: string = '#FFFFFF';
  /** 正文字色 */
  bodyText: string = '#37474F';
  /** 引用块文字色 */
  quoteText: string = '#546E7A';
  /** 引用块底色 */
  quoteBg: string = '#F5F7F9';
  /** 元信息徽章底色 */
  chipBg: string = '#F0F3F5';
  /** 分割线颜色 */
  lineColor: string = '#E0E0E0';
  /** 是否暗色方案（影响标题/表格等派生配色） */
  dark: boolean = false;
}

export class AppTheme {
  /** AppStorage 键：主题色 id（对外常量，页面 @StorageProp 引用） */
  static readonly STORAGE_THEME: string = 'themeId';
  /** AppStorage 键：正文字体 id */
  static readonly STORAGE_FONT: string = 'fontId';
  /** AppStorage 键：阅读背景 id */
  static readonly STORAGE_READ_BG: string = 'readBgId';
  /** AppStorage 键：正文字号（fp） */
  static readonly STORAGE_TEXT_SIZE: string = 'textSize';
  /** AppStorage 键：行距倍率 */
  static readonly STORAGE_LINE_SPACING: string = 'lineSpacing';

  /** 平板/宽屏下页面内容最大宽度（vp），超出居中收窄保证可读性 */
  static readonly CONTENT_MAX_WIDTH: number = 720;
  /** 正文字号默认/最小/最大（fp） */
  static readonly TEXT_SIZE_DEFAULT: number = 16;
  static readonly TEXT_SIZE_MIN: number = 14;
  static readonly TEXT_SIZE_MAX: number = 22;
  /** 行距倍率默认/最小/最大 */
  static readonly LINE_SPACING_DEFAULT: number = 1.6;
  static readonly LINE_SPACING_MIN: number = 1.3;
  static readonly LINE_SPACING_MAX: number = 2.0;

  private static prefStore: preferences.Preferences | undefined = undefined;
  private static readonly PREF_NAME: string = 'lg_settings';
  private static readonly KEY_THEME: string = 'themeId';
  private static readonly KEY_FONT: string = 'fontId';
  private static readonly KEY_READ_BG: string = 'readBgId';
  private static readonly KEY_TEXT_SIZE: string = 'textSize';
  private static readonly KEY_LINE_SPACING: string = 'lineSpacing';

  private static build(id: number, name: string, primary: string, deep: string,
    soft: string, tint: string): ThemePalette {
    const p: ThemePalette = new ThemePalette();
    p.id = id;
    p.name = name;
    p.primary = primary;
    p.primaryDeep = deep;
    p.primarySoft = soft;
    p.tint = tint;
    return p;
  }

  private static readonly PALETTES: ThemePalette[] = [
    AppTheme.build(0, '靛蓝', '#5C6BC0', '#1A237E', '#5C6BC0', '#E8EAF6'),
    AppTheme.build(1, '湛蓝', '#1E88E5', '#0D47A1', '#42A5F5', '#E3F2FD'),
    AppTheme.build(2, '青碧', '#00897B', '#004D40', '#26A69A', '#E0F2F1'),
    AppTheme.build(3, '松绿', '#43A047', '#1B5E20', '#66BB6A', '#E8F5E9'),
    AppTheme.build(4, '暖橙', '#FB8C00', '#E65100', '#FFA726', '#FFF3E0'),
    AppTheme.build(5, '绛紫', '#8E24AA', '#4A148C', '#AB47BC', '#F3E5F5')
  ];

  private static buildReadingBg(id: number, name: string, contentBg: string, bodyText: string,
    quoteText: string, quoteBg: string, chipBg: string, lineColor: string, dark: boolean): ReadingBg {
    const b: ReadingBg = new ReadingBg();
    b.id = id;
    b.name = name;
    b.contentBg = contentBg;
    b.bodyText = bodyText;
    b.quoteText = quoteText;
    b.quoteBg = quoteBg;
    b.chipBg = chipBg;
    b.lineColor = lineColor;
    b.dark = dark;
    return b;
  }

  private static readonly READING_BGS: ReadingBg[] = [
    AppTheme.buildReadingBg(0, '纸白', '#FFFFFF', '#37474F', '#546E7A', '#F5F7F9', '#F0F3F5', '#E0E0E0', false),
    AppTheme.buildReadingBg(1, '羊皮纸', '#F6EFDF', '#55432A', '#6B5738', '#EEE5D0', '#EDE4CE', '#DFD5BC', false),
    AppTheme.buildReadingBg(2, '护眼', '#E7EED9', '#33402A', '#4A5A3E', '#DCE7C9', '#DEE8CB', '#CBD8B5', false),
    AppTheme.buildReadingBg(3, '暗夜', '#1F2328', '#C6CCD4', '#9AA3AD', '#2A2E34', '#2C3036', '#3A3F45', true)
  ];

  /** EntryAbility.onCreate 调用：加载持久化偏好并播种 AppStorage */
  static init(context: common.Context): void {
    try {
      const opt: preferences.Options = { name: AppTheme.PREF_NAME };
      AppTheme.prefStore = preferences.getPreferencesSync(context, opt);
    } catch (e) {
      console.error('[AppTheme] init preferences failed: ' + (e as Error).message);
    }
    let themeId: number = 0;
    let fontId: number = 0;
    let readBgId: number = 0;
    let textSize: number = AppTheme.TEXT_SIZE_DEFAULT;
    let lineSpacing: number = AppTheme.LINE_SPACING_DEFAULT;
    if (AppTheme.prefStore !== undefined) {
      themeId = AppTheme.prefStore.getSync(AppTheme.KEY_THEME, 0) as number;
      fontId = AppTheme.prefStore.getSync(AppTheme.KEY_FONT, 0) as number;
      readBgId = AppTheme.prefStore.getSync(AppTheme.KEY_READ_BG, 0) as number;
      textSize = AppTheme.prefStore.getSync(AppTheme.KEY_TEXT_SIZE, AppTheme.TEXT_SIZE_DEFAULT) as number;
      lineSpacing = AppTheme.prefStore.getSync(AppTheme.KEY_LINE_SPACING, AppTheme.LINE_SPACING_DEFAULT) as number;
    }
    AppStorage.setOrCreate(AppTheme.STORAGE_THEME, themeId);
    AppStorage.setOrCreate(AppTheme.STORAGE_FONT, fontId);
    AppStorage.setOrCreate(AppTheme.STORAGE_READ_BG, readBgId);
    AppStorage.setOrCreate(AppTheme.STORAGE_TEXT_SIZE, AppTheme.clamp(textSize, AppTheme.TEXT_SIZE_MIN, AppTheme.TEXT_SIZE_MAX, AppTheme.TEXT_SIZE_DEFAULT));
    AppStorage.setOrCreate(AppTheme.STORAGE_LINE_SPACING, AppTheme.clamp(lineSpacing, AppTheme.LINE_SPACING_MIN, AppTheme.LINE_SPACING_MAX, AppTheme.LINE_SPACING_DEFAULT));
  }

  private static clamp(value: number, min: number, max: number, fallback: number): number {
    if (!Number.isFinite(value) || value < min || value > max) {
      return fallback;
    }
    return value;
  }

  /** 全部预设色板（设置页渲染用，勿修改元素） */
  static allPalettes(): ThemePalette[] {
    return AppTheme.PALETTES;
  }

  /** 按 id 取色板；越界回退默认靛蓝 */
  static paletteOf(id: number): ThemePalette {
    if (id < 0 || id >= AppTheme.PALETTES.length) {
      return AppTheme.PALETTES[0];
    }
    return AppTheme.PALETTES[id];
  }

  /** 切换主题色：更新 AppStorage（页面即时刷新）并持久化 */
  static setThemeId(id: number): void {
    if (id < 0 || id >= AppTheme.PALETTES.length) {
      return;
    }
    AppStorage.setOrCreate(AppTheme.STORAGE_THEME, id);
    AppTheme.persist(AppTheme.KEY_THEME, id);
  }

  /** 切换正文字体：更新 AppStorage 并持久化 */
  static setFontId(id: number): void {
    AppStorage.setOrCreate(AppTheme.STORAGE_FONT, id);
    AppTheme.persist(AppTheme.KEY_FONT, id);
  }

  /** 全部阅读背景方案（设置页渲染用，勿修改元素） */
  static allReadingBgs(): ReadingBg[] {
    return AppTheme.READING_BGS;
  }

  /** 按 id 取阅读背景；越界回退纸白 */
  static readingBgOf(id: number): ReadingBg {
    if (id < 0 || id >= AppTheme.READING_BGS.length) {
      return AppTheme.READING_BGS[0];
    }
    return AppTheme.READING_BGS[id];
  }

  /** 切换阅读背景：更新 AppStorage 并持久化 */
  static setReadBgId(id: number): void {
    if (id < 0 || id >= AppTheme.READING_BGS.length) {
      return;
    }
    AppStorage.setOrCreate(AppTheme.STORAGE_READ_BG, id);
    AppTheme.persist(AppTheme.KEY_READ_BG, id);
  }

  /** 调整正文字号（fp，越界截断到合法区间） */
  static setTextSize(size: number): void {
    const v: number = Math.round(AppTheme.clamp(size, AppTheme.TEXT_SIZE_MIN, AppTheme.TEXT_SIZE_MAX, AppTheme.TEXT_SIZE_DEFAULT));
    AppStorage.setOrCreate(AppTheme.STORAGE_TEXT_SIZE, v);
    AppTheme.persist(AppTheme.KEY_TEXT_SIZE, v);
  }

  /** 调整行距倍率（越界截断到合法区间） */
  static setLineSpacing(spacing: number): void {
    const v: number = AppTheme.clamp(spacing, AppTheme.LINE_SPACING_MIN, AppTheme.LINE_SPACING_MAX, AppTheme.LINE_SPACING_DEFAULT);
    AppStorage.setOrCreate(AppTheme.STORAGE_LINE_SPACING, v);
    AppTheme.persist(AppTheme.KEY_LINE_SPACING, v);
  }

  private static persist(key: string, value: number): void {
    const store = AppTheme.prefStore;
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(key, value);
      store.flush();
    } catch (e) {
      console.error('[AppTheme] persist failed: ' + (e as Error).message);
    }
  }
}
