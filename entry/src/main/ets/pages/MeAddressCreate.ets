import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AddressItem } from '../models/MiniProgramModels';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { UserApi } from '../api/UserApi';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct MeAddressCreate {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State item: AddressItem = new AddressItem(0, '', '', '', '', false);

  async save(): Promise<void> {
    if (this.item.name.trim().length === 0 || this.item.phone.trim().length === 0 ||
      this.item.fullAddress.trim().length === 0) {
      ToastUtil.show('请填写完整的地址信息');
      return;
    }
    const addresses = await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', MockData.addresses());
    let maxId = 0;
    addresses.forEach((addr: AddressItem) => {
      if (addr.id > maxId) {
        maxId = addr.id;
      }
    });
    this.item.id = maxId + 1;
    const next: AddressItem[] = [];
    // 与小程序 address/store 一致：新地址置顶；设为默认时取消其它默认；
    // 若原本没有默认地址，新地址自动成为默认。
    if (this.item.isDefault) {
      addresses.forEach((addr: AddressItem) => {
        addr.isDefault = false;
        next.push(addr);
      });
    } else {
      let hasDefault = false;
      addresses.forEach((addr: AddressItem) => {
        if (addr.isDefault) {
          hasDefault = true;
        }
        next.push(addr);
      });
      if (!hasDefault) {
        this.item.isDefault = true;
      }
    }
    next.unshift(this.item);
    await CacheStore.setJson<AddressItem[]>(this.context, 'addresses', next);
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await UserApi.saveAddresses(token, next, env);
    } catch (_) {
    }
    router.back();
  }

  @Builder
  FormInput(label: string, placeholder: string, value: string, field: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(100)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1)
        .height(44)
        .fontSize(15)
        .textAlign(TextAlign.End)
        .backgroundColor('#FFFFFF')
        .onChange((text: string) => {
          if (field === 'alias') {
            this.item.alias = text;
          } else if (field === 'name') {
            this.item.name = text;
          } else if (field === 'phone') {
            this.item.phone = text;
          }
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  @Builder
  DetailInput() {
    Row() {
      Text('详细地址')
        .fontSize(15)
        .fontColor('#333333')
        .width(100)
      TextArea({ placeholder: '请输入详细地址，如街道、楼牌号等', text: this.item.fullAddress })
        .layoutWeight(1)
        .height(96)
        .fontSize(15)
        .backgroundColor('#FFFFFF')
        .onChange((text: string) => {
          this.item.fullAddress = text;
        })
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  @Builder
  DefaultSwitch() {
    Row() {
      Text('设为默认地址')
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.item.isDefault })
        .selectedColor('#007AFF')
        .onChange((isOn: boolean) => {
          this.item.isDefault = isOn;
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  build() {
    Column() {
      PageHeader({ title: '新增地址' })
      Scroll() {
        Column() {
          this.FormInput('地址别名', '如：家、学校', this.item.alias, 'alias')
          this.FormInput('收货人姓名', '请填写收货人姓名', this.item.name, 'name')
          this.FormInput('手机号码', '请填写收货人手机号', this.item.phone, 'phone')
          this.DetailInput()
          this.DefaultSwitch()
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 15, bottom: 100 })
      }
      .layoutWeight(1)
      Button('保存')
        .width('90%')
        .height(46)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(23)
        .margin({ bottom: 22 })
        .shadow({ radius: 8, color: '#4D007AFF', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          this.save();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}