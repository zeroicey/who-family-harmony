import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { ApiConfig } from '../api/ApiConfig';
import { ApiError } from '../api/HttpClient';
import { PickedFile, UploadService } from '../services/UploadService';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { PageHeader } from '../components/common/PageHeader';
import { SectionCard } from '../components/common/SectionCard';
@Entry
@Component
struct MeSetting {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private clearDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '清除缓存',
      message: '将清除本地用户信息和页面缓存。',
      confirmText: '清除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.clearNow();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  clear(): void {
    this.clearDialog.open();
  }

  async clearNow(): Promise<void> {
    await CacheStore.clear(this.context);
    await AuthStore.clear(this.context);
    ToastUtil.show('缓存已清除');
    router.replaceUrl({ url: 'pages/Index' });
  }

  open(url: string): void {
    router.pushUrl({ url: url });
  }

  /**
   * 上传链路自检（M2）：选图 → 读取 → HttpClient.putBinary 直传 → 记录状态。
   * 演示 token 无效时，会明确收到 401，而不是静默失败。
   */
  async verifyUpload(): Promise<void> {
    // 相册为空或取消时，用内置 1x1 PNG 继续探测网络层，保证 PUT 链路可执行。
    let file: PickedFile | null = null;
    try {
      const picked = await UploadService.pickImages(1);
      if (picked.length > 0) {
        file = picked[0];
      }
    } catch (err) {
      LogUtil.info('upload-check', `picker skipped ${(err as Error).message}`);
    }
    if (file === null) {
      const bytes = new util.Base64Helper().decodeSync(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=');
      file = new PickedFile('builtin-probe', 'probe.png', 'image/png', bytes.byteLength,
        bytes.buffer as ArrayBuffer);
      ToastUtil.show('相册不可用，使用内置测试图');
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    const probeUrl = `${ApiConfig.currentBaseUrl(env)}/community/img-uploaded`;
    try {
      await UploadService.uploadToUrl(probeUrl, token, file, env);
      ToastUtil.show('上传链路自检：请求成功');
    } catch (err) {
      const apiError = err as ApiError;
      if (apiError instanceof ApiError && apiError.statusCode > 0) {
        LogUtil.warn('upload-check', `PUT reached server status=${apiError.statusCode}`);
        ToastUtil.show(`上传链路自检：HTTP ${apiError.statusCode}（请求已发出）`);
      } else {
        LogUtil.warn('upload-check', `PUT failed ${apiError.message}`);
        ToastUtil.show(`上传链路自检失败：${apiError.message}`);
      }
    }
  }

  @Builder
  SettingRow(title: string, value: string = '', danger: boolean = false, url: string = '', action: string = '') {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(danger ? '#FF3B30' : '#333333')
        .layoutWeight(1)
      if (value.length > 0) {
        Text(value)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ right: 8 })
      }
      Text('›')
        .fontSize(20)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F2F2F2' })
    .onClick(() => {
      if (danger) {
        this.clear();
      } else if (action === 'upload-check') {
        this.verifyUpload();
      } else if (url.length > 0) {
        this.open(url);
      }
    })
  }

  build() {
    Column() {
      PageHeader({ title: '设置' })
      Scroll() {
        Column() {
          SectionCard({
            cardBg: '#00000000',
            showShadow: false,
            cardPadding: 0
          }) {
            Column() {
              Column() {
                this.SettingRow('个人资料', '', false, 'pages/MeProfile')
                this.SettingRow('收货地址', '', false, 'pages/MeAddress')
                this.SettingRow('我的订单', '', false, 'pages/MeOrder')
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)
              .margin({ bottom: 14 })

              Column() {
                this.SettingRow('关于互成一家', '', false, 'pages/MeAbout')
                this.SettingRow('用户协议', '', false, 'pages/AgreementUser')
                this.SettingRow('隐私政策', '', false, 'pages/AgreementPrivacy')
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)
              .margin({ bottom: 14 })

              Column() {
                this.SettingRow('清除缓存', '', true)
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)
              .margin({ bottom: 14 })

              Column() {
                this.SettingRow('上传链路自检', '选图后 PUT', false, '', 'upload-check')
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
