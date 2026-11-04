/**
 * 桌面卡片（每日知识点 2x2）FormExtensionAbility：
 * - 卡片进程独立运行：onCreate 自行向 DataRepository 注入 context
 * - 数据组装：按日期哈希选文（DailyPick），标题/摘要/日期/主题色（preferences 直读）
 * - 点击卡片 router 拉起 EntryAbility，want.parameters 携带 slug 直达文章详情
 * - 定时刷新（每日 08:30 前后）经 onUpdateForm 重新下发当日推荐
 */
import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DataRepository } from '../data/DataRepository';
import { DailyPick } from '../core/DailyPick';
import { AppTheme, ThemePalette } from '../common/AppTheme';

export default class EntryFormAbility extends FormExtensionAbility {
  onCreate(want: Want): void {
    // 卡片与主进程隔离：本进程内自行注入上下文（幂等）
    DataRepository.getInstance().init(this.context);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const data: Record<string, string> = this.buildData();
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string): void {
    const data: Record<string, string> = this.buildData();
    formProvider.updateForm(formId, formBindingData.createFormBindingData(data))
      .catch((err: BusinessError) => {
        console.error('[EntryFormAbility] updateForm failed: ' + JSON.stringify(err));
      });
  }

  onFormEvent(formId: string, message: string): void {
  }

  onRemoveForm(formId: string): void {
  }

  /** 组装卡片数据：日期哈希选文 + 主题色（卡片进程无 AppStorage，走 preferences 直读） */
  private buildData(): Record<string, string> {
    const data: Record<string, string> = {};
    try {
      const articles = DataRepository.getInstance().getAllArticles();
      const idx: number = DailyPick.pickIndex(articles.length, DailyPick.todayKey());
      const meta = idx >= 0 ? articles[idx] : undefined;
      const palette: ThemePalette = AppTheme.paletteFromPrefs(this.context);
      data['title'] = meta !== undefined ? meta.title : '行知';
      data['description'] = meta !== undefined ? meta.description : '每天一篇 ArkTS 构建手记';
      data['dateLabel'] = DailyPick.dateLabel();
      data['slug'] = meta !== undefined ? meta.slug : '';
      data['primary'] = palette.primary;
      data['primaryDeep'] = palette.primaryDeep;
    } catch (e) {
      console.error('[EntryFormAbility] buildData failed: ' + (e as Error).message);
      data['title'] = '行知';
      data['description'] = '内容加载中，请稍后';
      data['dateLabel'] = DailyPick.dateLabel();
      data['slug'] = '';
      data['primary'] = '#5C6BC0';
      data['primaryDeep'] = '#1A237E';
    }
    return data;
  }
}
