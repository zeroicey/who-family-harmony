import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AddressItem } from '../models/MiniProgramModels';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { UserApi } from '../api/UserApi';
import { MockData } from '../utils/MockData';
import { LogUtil } from '../utils/LogUtil';

import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { LoadingView } from '../components/common/LoadingView';
import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct MeAddress {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State addresses: AddressItem[] = [];
  @State loading: boolean = true;
  private pendingDeleteId: number = 0;
  private deleteDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '确认删除',
      message: '确定要删除这个地址吗？',
      confirmText: '删除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.deletePending();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  /** 进入/返回页面时刷新列表（对应小程序 onShow）。 */
  onPageShow(): void {
    this.load();
  }

  async load(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    this.loading = true;
    try {
      // 与小程序一致：后端返回空数组时展示空态，不用 Mock 顶替。
      const remote = await UserApi.loadAddresses(token, env);
      LogUtil.info('address', `loaded count=${remote.length}`);
      this.addresses = remote;
      await CacheStore.setJson<AddressItem[]>(this.context, 'addresses', remote);
    } catch (err) {
      LogUtil.warn('address', `load failed ${(err as Error).message}`);
      this.addresses = await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', MockData.addresses());
    } finally {
      this.loading = false;
    }
  }

  openCreate(): void {
    router.pushUrl({ url: 'pages/MeAddressCreate' });
  }

  async openUpdate(item: AddressItem): Promise<void> {
    await CacheStore.setJson<AddressItem>(this.context, 'editingAddress', item);
    router.pushUrl({ url: 'pages/MeAddressUpdate', params: { id: `${item.id}` } });
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
  }

  confirmDelete(item: AddressItem): void {
    this.pendingDeleteId = item.id;
    this.deleteDialog.open();
  }

  async deletePending(): Promise<void> {
    const id = this.pendingDeleteId;
    this.pendingDeleteId = 0;
    if (id === 0) {
      return;
    }
    const target = this.addresses.find((addr: AddressItem) => addr.id === id);
    if (target !== undefined) {
      await this.deleteAddress(target);
    }
  }

  async deleteAddress(item: AddressItem): Promise<void> {
    const next = this.addresses.filter((addr: AddressItem) => addr.id !== item.id);
    // 与小程序一致：删除默认地址后，若仍有地址且无默认，首条回补为默认。
    if (item.isDefault && next.length > 0 && next.every((addr: AddressItem) => !addr.isDefault)) {
      next[0].isDefault = true;
    }
    await this.saveAddresses(next);
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
          Text(item.alias)
            .fontSize(12)
            .fontColor('#888888')
            .backgroundColor('#F0F0F0')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 5 })
          Text(item.fullAddress)
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
      Image($r('app.media.icon_me_address_empty'))
        .width(100)
        .height(100)
      Text('还没有收货地址，快去添加一个吧')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ top: 14 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(360)
  }

  build() {
    Column() {
      PageHeader({ title: '地址管理' })
      Scroll() {
        Column() {
          if (this.loading) {
            LoadingView({ text: '正在加载地址', minHeight: 240 })
          } else if (this.addresses.length > 0) {
            ForEach(this.addresses, (item: AddressItem) => {
              this.AddressCard(item)
            }, (item: AddressItem) => `${item.id}-${item.isDefault}-${item.alias}-${item.fullAddress}`)
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
