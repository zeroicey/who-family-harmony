import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct MeSetting {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  clear(): void {
    AlertDialog.show({
      title: '清除缓存',
      message: '将清除本地用户信息和页面缓存。',
      primaryButton: {
        value: '清除',
        action: () => {
          this.clearNow();
        }
      },
      secondaryButton: { value: '取消', action: () => {} }
    });
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

  @Builder
  SettingRow(title: string, value: string = '', danger: boolean = false, url: string = '') {
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
