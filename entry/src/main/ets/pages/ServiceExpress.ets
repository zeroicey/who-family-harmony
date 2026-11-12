import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ExpressOrder } from '../models/ExpressOrder';
import { AddressItem } from '../models/MiniProgramModels';
import { UserApi } from '../api/UserApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { NetImage } from '../components/common/NetImage';
import { PageHeader } from '../components/common/PageHeader';

class ExpressRouteParams {
  showOrders: boolean = false;
}

@Entry
@Component
struct ServiceExpress {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private packageSizes: string[] = ['小件', '中件', '大件'];
  private weights: string[] = ['<1kg', '1-5kg', '>5kg'];
  @State addresses: AddressItem[] = [];
  @State selectedAddress: AddressItem | null = null;
  @State packageSize: string = '中件';
  @State weight: string = '1-5kg';
  @State remark: string = '';
  @State localOrders: ExpressOrder[] = [];
  @State showAddressPicker: boolean = false;
  @State submitting: boolean = false;
  private scroller: Scroller = new Scroller();
  private scrollToOrders: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as ExpressRouteParams;
    this.scrollToOrders = params !== undefined && params !== null && params.showOrders === true;
    this.loadAddresses();
    this.loadLocalOrders();
  }

  onPageShow(): void {
    // 从地址簿新增/管理返回后刷新地址，选择面板不保留旧列表。
    this.showAddressPicker = false;
    this.loadAddresses();
  }

  async loadAddresses(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    let loaded: AddressItem[] = [];
    try {
      loaded = await UserApi.loadAddresses(token, env);
    } catch (_) {
      loaded = [];
    }
    if (loaded.length === 0) {
      loaded = await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', MockData.addresses());
    }
    this.addresses = loaded;
    if (this.selectedAddress !== null) {
      const previousId = this.selectedAddress.id;
      const keep = loaded.find((item: AddressItem) => item.id === previousId);
      this.selectedAddress = keep !== undefined ? keep : this.defaultAddress();
    } else {
      this.selectedAddress = this.defaultAddress();
    }
  }

  private defaultAddress(): AddressItem | null {
    const preferred = this.addresses.find((item: AddressItem) => item.isDefault);
    if (preferred !== undefined) {
      return preferred;
    }
    return this.addresses.length > 0 ? this.addresses[0] : null;
  }

  private addressText(item: AddressItem): string {
    const alias = item.alias.length > 0 ? item.alias : '';
    const detail = item.fullAddress.length > 0 ? item.fullAddress : '';
    return `${alias} ${detail}`.trim();
  }

  private selectedAddressText(): string {
    return this.selectedAddress === null ? '' : this.addressText(this.selectedAddress);
  }

  private packageBasePrice(): number {
    if (this.packageSize === '小件') {
      return 3;
    }
    if (this.packageSize === '大件') {
      return 8;
    }
    return 5;
  }

  private weightSurcharge(): number {
    if (this.weight === '<1kg') {
      return 0;
    }
    if (this.weight === '>5kg') {
      return 5;
    }
    return 2;
  }

  private totalPrice(): number {
    return this.packageBasePrice() + this.weightSurcharge();
  }

  async loadLocalOrders(): Promise<void> {
    this.localOrders = await CacheStore.getJson<ExpressOrder[]>(this.context, 'expressOrders', []);
    if (this.scrollToOrders) {
      this.scrollToOrders = false;
      setTimeout(() => {
        try {
          this.scroller.scrollEdge(Edge.Bottom);
        } catch (_) {
        }
      }, 200);
    }
  }

  async placeOrder(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (this.selectedAddress === null) {
      ToastUtil.show('请选择收货地址');
      return;
    }
    this.submitting = true;
    const address = this.selectedAddress;
    const nowText = new Date().toLocaleString();
    const order = new ExpressOrder(
      `express-${Date.now()}`,
      `${address.id}`,
      this.addressText(address),
      this.packageSize,
      this.weight,
      this.remark.trim(),
      this.totalPrice(),
      '待处理',
      nowText
    );
    this.localOrders = [order].concat(this.localOrders);
    await CacheStore.setJson<ExpressOrder[]>(this.context, 'expressOrders', this.localOrders);
    this.submitting = false;
    ToastUtil.show('下单成功（演示订单）');
    router.pushUrl({
      url: 'pages/ServiceSuccess',
      params: { type: 'express', orderId: order.id }
    });
  }

  @Builder
  SectionTitle(title: string, subtitle: string) {
    Column() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
      if (subtitle.length > 0) {
        Text(subtitle)
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: 4 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  InfoCard() {
    Column() {
      Text('闪电速递，使命必达')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text('戴拿奥特曼化身光之快递员，30分钟内极速代取，包裹直送宿舍门口！')
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .margin({ top: 8 })
      Row() {
        Text('安全可靠')
          .fontSize(12)
          .fontColor('#007AFF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#EAF4FF')
          .borderRadius(12)
        Text('24小时待命')
          .fontSize(12)
          .fontColor('#28A745')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#ECF9F0')
          .borderRadius(12)
          .margin({ left: 8 })
        Text('超能优惠')
          .fontSize(12)
          .fontColor('#FF8A00')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#FFF4E5')
          .borderRadius(12)
          .margin({ left: 8 })
      }
      .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: -26 })
    .shadow({ radius: 16, color: 'rgba(16, 24, 40, 0.06)', offsetX: 0, offsetY: 4 })
  }

  @Builder
  Perk(icon: string, title: string, desc: string) {
    Row() {
      Text(icon)
        .fontSize(22)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F4F7FB')
        .borderRadius(22)
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  PerksCard() {
    Column() {
      this.Perk('📍', '校园专属', '路线规划比导航还准！')
      this.Perk('🌱', '环保行动', '每10单，种下1棵光之树')
      this.Perk('🎁', '隐藏彩蛋', '随机掉落奥特曼徽章')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  FormItemLabel(label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#333333')
      .width('100%')
      .margin({ top: 18, bottom: 10 })
  }

  @Builder
  SegmentOption(label: string, selected: boolean, onSelect: () => void) {
    Text(label)
      .fontSize(14)
      .fontWeight(selected ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(selected ? '#007AFF' : '#666666')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(38)
      .backgroundColor(selected ? '#FFFFFF' : '#F2F4F7')
      .borderRadius(8)
      .border({ width: selected ? 1 : 0, color: '#007AFF' })
      .onClick(onSelect)
  }

  @Builder
  FormCard() {
    Column() {
      this.SectionTitle('填写代取信息', '带 * 为必填项')

      Row() {
        Text('收货地址')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width(76)
        Text(this.selectedAddress === null ? '请选择收货地址 *' : this.selectedAddressText())
          .fontSize(14)
          .fontColor(this.selectedAddress === null ? '#999999' : '#333333')
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('›')
          .fontSize(22)
          .fontColor('#C0C4CC')
          .margin({ left: 6 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .onClick(() => {
        this.showAddressPicker = true;
      })

      Divider().color('#F0F0F0')

      this.FormItemLabel('快递大小')
      Row() {
        ForEach(this.packageSizes, (item: string) => {
          this.SegmentOption(item, this.packageSize === item, () => {
            this.packageSize = item;
          })
        }, (item: string) => item)
      }
      .width('100%')
      .padding(3)
      .backgroundColor('#F2F4F7')
      .borderRadius(10)

      this.FormItemLabel('预估重量')
      Row() {
        ForEach(this.weights, (item: string) => {
          this.SegmentOption(item, this.weight === item, () => {
            this.weight = item;
          })
        }, (item: string) => item)
      }
      .width('100%')
      .padding(3)
      .backgroundColor('#F2F4F7')
      .borderRadius(10)

      this.FormItemLabel('备注')
      TextInput({ text: this.remark, placeholder: '如有取件码或送达要求，请填写（选填）' })
        .height(46)
        .maxLength(100)
        .backgroundColor('#F8F9FA')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.remark = value;
        })

      Row() {
        Column() {
          Text('预估费用')
            .fontSize(13)
            .fontColor('#888888')
          Text(`¥${this.totalPrice().toFixed(2)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF4D4F')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column() {
          Text(`${this.packageSize}基础价 ¥${this.packageBasePrice().toFixed(2)}`)
            .fontSize(11)
            .fontColor('#999999')
          Text(`重量附加 ¥${this.weightSurcharge().toFixed(2)}`)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFF8F7')
      .borderRadius(12)
      .margin({ top: 18 })

      Text('演示提示：当前未接入快递代取后端，下单仅生成保存在本机的演示订单，不会真实派单。')
        .fontSize(11)
        .fontColor('#FA8C16')
        .lineHeight(17)
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF7E6')
        .borderRadius(8)
        .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  ProcessCard() {
    Column() {
      this.SectionTitle('服务流程', '')
      Row() {
        this.ProcessStep('线上下单')
        Text('→').fontSize(14).fontColor('#CCCCCC')
        this.ProcessStep('骑手接单')
        Text('→').fontSize(14).fontColor('#CCCCCC')
        this.ProcessStep('送货上门')
        Text('→').fontSize(14).fontColor('#CCCCCC')
        this.ProcessStep('确认收货')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  ProcessStep(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#007AFF')
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .backgroundColor('#EAF4FF')
      .borderRadius(8)
  }

  @Builder
  Review(initial: string, name: string, content: string) {
    Column() {
      Row() {
        Text(initial)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#7FB3FF')
        Text(name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      Text(content)
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(19)
        .width('100%')
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  ReviewsCard() {
    Column() {
      this.SectionTitle('用户评价', '')
      this.Review('光', '光之巨人', '速度真的快，像光一样！以后快递都交给你们了！')
      Divider().color('#F5F5F5')
      this.Review('校', '校园懒人', '太方便了，再也不用顶着大太阳去取快递了，拯救了我的懒癌！')
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  LocalOrdersCard() {
    Column() {
      this.SectionTitle('我的代取订单', '仅保存在本机')
      if (this.localOrders.length === 0) {
        Text('暂无代取订单，填写上方信息即可体验下单。')
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.localOrders.slice(0, 5), (order: ExpressOrder) => {
          Column() {
            Row() {
              Text(order.id)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)
              Text(order.status)
                .fontSize(11)
                .fontColor('#007AFF')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('#EAF4FF')
                .borderRadius(10)
            }
            .width('100%')
            Text(order.addressDetails)
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 6 })
            Row() {
              Text(`${order.packageSize} · ${order.estimatedWeight}`)
                .fontSize(11)
                .fontColor('#999999')
                .layoutWeight(1)
              Text(`¥${order.price.toFixed(2)}`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF4D4F')
            }
            .width('100%')
            .margin({ top: 4 })
            Text(order.createdAt)
              .fontSize(10)
              .fontColor('#BBBBBB')
              .width('100%')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .border({ width: { bottom: 1 }, color: '#F5F5F5' })
        }, (order: ExpressOrder) => order.id)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  AddressPicker() {
    Column() {
      Row() {
        Text('选择收货地址')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('×')
          .fontSize(28)
          .fontColor('#999999')
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showAddressPicker = false;
          })
      }
      .width('100%')
      .padding({ bottom: 12 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      if (this.addresses.length === 0) {
        Text('地址簿为空，请先新增地址')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .padding({ top: 24, bottom: 24 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.addresses, (item: AddressItem) => {
              Row() {
                Column() {
                  Row() {
                    Text(item.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333333')
                    Text(item.phone)
                      .fontSize(13)
                      .fontColor('#888888')
                      .margin({ left: 8 })
                    if (item.isDefault) {
                      Text('默认')
                        .fontSize(10)
                        .fontColor('#007AFF')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor('#EAF4FF')
                        .borderRadius(8)
                        .margin({ left: 8 })
                    }
                  }
                  Text(this.addressText(item))
                    .fontSize(13)
                    .fontColor('#666666')
                    .maxLines(2)
                    .margin({ top: 5 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text(this.selectedAddress !== null && this.selectedAddress.id === item.id ? '✓' : '')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#007AFF')
                  .width(28)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 1 }, color: '#F5F5F5' })
              .onClick(() => {
                this.selectedAddress = item;
                this.showAddressPicker = false;
              })
            }, (item: AddressItem) => `${item.id}`)
          }
          .width('100%')
        }
        .constraintSize({ maxHeight: 340 })
      }

      Row() {
        Button('管理地址')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor('#EAF4FF')
          .borderRadius(21)
          .onClick(() => {
            this.showAddressPicker = false;
            router.pushUrl({ url: 'pages/MeAddress' });
          })
        Button('新增地址')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(21)
          .margin({ left: 10 })
          .onClick(() => {
            this.showAddressPicker = false;
            router.pushUrl({ url: 'pages/MeAddressCreate' });
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('88%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        PageHeader({ title: '快递代取' })
        Scroll(this.scroller) {
          Column() {
            NetImage({
              imageUrl: 'https://api.hcyj.xyz/images/dngg.jpg',
              imageHeight: 210,
              imageRadius: 0,
              fitMode: 'cover'
            })
            Column() {
              this.InfoCard()
              this.PerksCard()
              this.FormCard()
              this.ProcessCard()
              this.ReviewsCard()
              this.LocalOrdersCard()
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 100 })
          }
          .width('100%')
        }
        .layoutWeight(1)

        Row() {
          Column() {
            Text('预估费用')
              .fontSize(11)
              .fontColor('#999999')
            Text(`¥${this.totalPrice().toFixed(2)}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF4D4F')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Button(this.submitting ? '提交中...' : '立即下单')
            .width(170)
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(23)
            .enabled(!this.submitting)
            .onClick(() => {
              this.placeOrder();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 16 })
        .backgroundColor('#FFFFFF')
        .border({ width: { top: 1 }, color: '#F0F0F0' })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F8')

      if (this.showAddressPicker) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')
          .onClick(() => {
            this.showAddressPicker = false;
          })
        this.AddressPicker()
      }
    }
    .width('100%')
    .height('100%')
  }
}
