import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AddressItem } from '../models/MiniProgramModels';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { UserApi } from '../api/UserApi';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct MeAddress {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State addresses: AddressItem[] = MockData.addresses();

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const remote = await UserApi.loadAddresses(token, env);
      this.addresses = remote.length > 0 ? remote : await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', MockData.addresses());
    } catch (_) {
      this.addresses = await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', MockData.addresses());
    }
  }

  openCreate(): void {
    router.pushUrl({ url: 'pages/MeAddressCreate' });
  }

  openUpdate(item: AddressItem): void {
    CacheStore.setJson<AddressItem>(this.context, 'editingAddress', item);
    router.pushUrl({ url: 'pages/MeAddressUpdate', params: { id: item.id } });
  }

  async saveAddresses(addresses: AddressItem[]): Promise<void> {
    this.addresses = addresses;
    await CacheStore.setJson<AddressItem[]>(this.context, 'addresses', addresses);
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await UserApi.saveAddresses(token, addresses, env);
    } catch (_) {
    }
  }

  async setDefault(item: AddressItem): Promise<void> {
    const next: AddressItem[] = [];
    this.addresses.forEach((addr: AddressItem) => {
      addr.isDefault = addr.id === item.id;
      next.push(addr);
    });
    await this.saveAddresses(next);
    ToastUtil.show('已设为默认地址');
  }

  confirmDelete(item: AddressItem): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这个地址吗？',
      primaryButton: {
        value: '删除',
        action: () => {
          this.deleteAddress(item);
        }
      },
      secondaryButton: { value: '取消', action: () => {} }
    });
  }

  async deleteAddress(item: AddressItem): Promise<void> {
    const next = this.addresses.filter((addr: AddressItem) => addr.id !== item.id);
    await this.saveAddresses(next);
    ToastUtil.show('地址已删除');
  }

  @Builder
  AddressCard(item: AddressItem) {
    Row() {
      Column() {
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(item.phone)
            .fontSize(14)
            .fontColor('#888888')
            .margin({ left: 10 })
        }
        .width('100%')
        Row() {
          if (item.isDefault) {
            Text('[默认]')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5722')
              .margin({ right: 5 })
          }
          Text(item.area)
            .fontSize(12)
            .fontColor('#888888')
            .backgroundColor('#F0F0F0')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 5 })
          Text(item.detail)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(20)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => {
          this.setDefault(item);
        })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Text('编辑')
          .fontSize(14)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .onClick(() => {
            this.openUpdate(item);
          })
        Text('删除')
          .fontSize(14)
          .fontColor('#FF3B30')
          .padding({ left: 8, right: 0, top: 8, bottom: 8 })
          .onClick(() => {
            this.confirmDelete(item);
          })
      }
      .margin({ left: 10 })
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .shadow({ radius: 6, color: '#0D000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📍')
        .fontSize(58)
        .fontColor('#CCCCCC')
      Text('还没有收货地址，快去添加一个吧')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 14 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(360)
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          if (this.addresses.length > 0) {
            ForEach(this.addresses, (item: AddressItem) => {
              this.AddressCard(item)
            }, (item: AddressItem) => item.id)
          } else {
            this.EmptyState()
          }
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 96 })
      }
      .layoutWeight(1)

      Button('新增收货地址')
        .width('90%')
        .height(46)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(23)
        .margin({ bottom: 20 })
        .shadow({ radius: 8, color: '#4D007AFF', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          this.openCreate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}
