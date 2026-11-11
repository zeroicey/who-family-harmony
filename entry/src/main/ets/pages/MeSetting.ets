import { bundleManager, common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { ApiConfig, ApiEnvironment } from '../api/ApiConfig';
import { ApiError } from '../api/HttpClient';
import { UserApi } from '../api/UserApi';
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
  @State environment: string = ApiEnvironment.PRODUCTION;
  @State isLocal: boolean = false;
  @State probing: boolean = false;
  private clearDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '清除缓存',
      message: '将清除本地页面缓存，登录状态保留。',
      confirmText: '清除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.clearNow();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });
  private resetDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '重置演示会话',
      message: '将清除缓存并重新加载演示数据，登录 token 保留。',
      confirmText: '重置',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.resetDemoSession();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.loadState();
  }

  async loadState(): Promise<void> {
    this.environment = await AuthStore.getApiEnvironment(this.context);
    this.isLocal = this.environment === ApiEnvironment.LOCAL;
  }

  private versionLabel(): string {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const name = info.versionName !== undefined && info.versionName.length > 0 ? info.versionName : '1.0.0';
      return `${name} (${info.versionCode})`;
    } catch (err) {
      LogUtil.warn('setting', `version read failed ${(err as Error).message}`);
      return '1.0.0';
    }
  }

  clear(): void {
    this.clearDialog.open();
  }

  /** 只清页面缓存；token / 环境选择保持不变。 */
  async clearNow(): Promise<void> {
    await CacheStore.clear(this.context);
    ToastUtil.show('缓存已清除');
  }

  resetSession(): void {
    this.resetDialog.open();
  }

  /** 演示会话重置：只清缓存，不清 token；回到首页重新拉取数据。 */
  async resetDemoSession(): Promise<void> {
    await CacheStore.clear(this.context);
    await AuthStore.clearCachedUser(this.context);
    AppStorage.setOrCreate<string>('avatarUrl', '');
    // 触发「我的」页重新拉取演示资料，再返回已存在的首页，避免重复实例。
    AppStorage.setOrCreate<string>('userRefreshAt', `${Date.now()}`);
    ToastUtil.show('演示会话已重置');
    if (Number(router.getLength()) > 1) {
      router.back();
    } else {
      router.replaceUrl({ url: 'pages/Index' });
    }
  }

  /** 切换后新请求立即走新地址（各页面每次请求都会读取 AuthStore）。 */
  async switchEnvironment(isOn: boolean): Promise<void> {
    const next = isOn ? ApiEnvironment.LOCAL : ApiEnvironment.PRODUCTION;
    await AuthStore.setApiEnvironment(this.context, next);
    this.environment = next;
    this.isLocal = isOn;
    ToastUtil.show(`已切换到${ApiConfig.environmentLabel(next)}`);
  }

  /** 连通性自检：用当前环境请求一次用户信息，验证切换即时生效。 */
  async probeEnvironment(): Promise<void> {
    if (this.probing) {
      return;
    }
    this.probing = true;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const user = await UserApi.getUserInfo(token, ApiConfig.DEMO_USER_ID, env);
      ToastUtil.show(`连接正常：${user.nickname}`);
    } catch (err) {
      LogUtil.warn('setting', `probe ${env} failed ${(err as Error).message}`);
      ToastUtil.show('连接失败，请检查后端是否可用');
    } finally {
      this.probing = false;
    }
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
  SettingRow(title: string, value: string = '', url: string = '', action: string = '') {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#333333')
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
      if (action === 'probe-env') {
        this.probeEnvironment();
      } else if (action === 'upload-check') {
        this.verifyUpload();
      } else if (url.length > 0) {
        this.open(url);
      }
    })
  }

  @Builder
  DangerRow(title: string, action: string) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#FF3B30')
        .layoutWeight(1)
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
      if (action === 'clear') {
        this.clear();
      } else {
        this.resetSession();
      }
    })
  }

  @Builder
  EnvironmentRow() {
    Row() {
      Text('当前环境')
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(ApiConfig.environmentLabel(this.environment))
        .fontSize(13)
        .fontColor('#999999')
        .margin({ right: 8 })
      Text('›')
        .fontSize(20)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F2F2F2' })
  }

  @Builder
  BackendAddressRow() {
    Row() {
      Text('当前后端地址')
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(ApiConfig.currentBaseUrl(this.environment))
        .fontSize(13)
        .fontColor('#999999')
        .margin({ right: 8 })
      Text('›')
        .fontSize(20)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F2F2F2' })
  }

  @Builder
  VersionRow() {
    Row() {
      Text('版本信息')
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(this.versionLabel())
        .fontSize(13)
        .fontColor('#999999')
        .margin({ right: 8 })
      Text('›')
        .fontSize(20)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F2F2F2' })
  }

  @Builder
  EnvSwitchRow() {
    Row() {
      Column() {
        Text('使用本地后端')
          .fontSize(15)
          .fontColor('#333333')
        Text('切换后新请求立即生效')
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.isLocal })
        .selectedColor('#07C160')
        .onChange((isOn: boolean) => {
          this.switchEnvironment(isOn);
        })
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F2F2F2' })
  }

  @Builder
  GroupCard() {
    Column() {
      Column() {
        this.SettingRow('个人资料', '', 'pages/MeProfile')
        this.SettingRow('收货地址', '', 'pages/MeAddress')
        this.SettingRow('我的订单', '', 'pages/MeOrder')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
      .margin({ bottom: 14 })

      Column() {
        this.SettingRow('关于互成一家', '', 'pages/MeAbout')
        this.SettingRow('用户协议', '', 'pages/AgreementUser')
        this.SettingRow('隐私政策', '', 'pages/AgreementPrivacy')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
      .margin({ bottom: 14 })

      Column() {
        this.EnvironmentRow()
        this.EnvSwitchRow()
        this.BackendAddressRow()
        this.SettingRow('检测连接', '', '', 'probe-env')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
      .margin({ bottom: 14 })

      Column() {
        this.VersionRow()
        this.SettingRow('应用标识', 'com.hcyj.harmony')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
      .margin({ bottom: 14 })

      Column() {
        this.DangerRow('清除缓存', 'clear')
        this.DangerRow('重置演示会话', 'reset')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
      .margin({ bottom: 14 })

      Column() {
        this.SettingRow('上传链路自检', '选图后 PUT', '', 'upload-check')
      }
      .width('100%')
      .borderRadius(10)
      .clip(true)
    }
    .width('100%')
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
            this.GroupCard()
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14, bottom: 30 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}