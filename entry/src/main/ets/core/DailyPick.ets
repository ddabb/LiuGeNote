/**
 * 每日选文/选题：按日期哈希取模稳定选位。
 * 同一天内结果稳定、跨天自动轮换；纯本地计算，无网络、无时间权限。
 * 供学习页每日推荐 Banner 与桌面卡片（EntryFormAbility）共用。
 */

export class DailyPick {
  /** 本地日期键 yyyyMMdd（与 ReadingTracker 统计口径一致） */
  static todayKey(): string {
    const d: Date = new Date();
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const mm: string = month < 10 ? '0' + month : '' + month;
    const dd: string = day < 10 ? '0' + day : '' + day;
    return '' + d.getFullYear() + mm + dd;
  }

  /** 展示用日期标签：M月d日 周X */
  static dateLabel(): string {
    const d: Date = new Date();
    const week: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return `${d.getMonth() + 1}月${d.getDate()}日 周${week[d.getDay()]}`;
  }

  /** 日期哈希取模选位（length <= 0 返回 -1） */
  static pickIndex(length: number, dateKey: string): number {
    if (length <= 0) {
      return -1;
    }
    let h: number = 0;
    for (let i: number = 0; i < dateKey.length; i++) {
      h = (h * 131 + dateKey.charCodeAt(i)) % 1000003;
    }
    return h % length;
  }
}
