/**
 * 轻提示工具：统一走 UIContext.getPromptAction()（禁止使用已废弃的全局 promptAction）。
 */
import { UIContext } from '@kit.ArkUI';

export class ToastUtil {
  static show(uiCtx: UIContext, message: string, duration: number): void {
    try {
      uiCtx.getPromptAction().showToast({
        message: message,
        duration: duration,
        bottom: '35%'
      });
    } catch (e) {
      console.error('[ToastUtil] show failed: ' + (e as Error).message);
    }
  }
}
