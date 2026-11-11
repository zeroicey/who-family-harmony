import { promptAction } from '@kit.ArkUI';

export class ToastUtil {
  static show(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2200,
      bottom: 80
    });
  }

  static demoData(): void {
    ToastUtil.show('网络开小差了，已显示本地缓存');
  }
}
