import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ExpressOrder, ServiceSuccessParams } from '../models/ExpressOrder';
import { PrintOrder } from '../models/MiniProgramModels';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

@Entry
@Component
struct ServiceSuccess {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private params: ServiceSuccessParams = new ServiceSuccessParams();
  @State type: string = 'other';
  @State titleText: string = '服务提交成功';
  @State descText: string = '请等待校内服务人员联系。';
  @State typeText: string = '校园服务';
  @State printOrder: PrintOrder = new PrintOrder();
  @State expressOrder: ExpressOrder = new ExpressOrder();
  @State priceText: string = '';
  @State orderFound: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as ServiceSuccessParams;
    if (params !== undefined && params !== null) {
      this.params = params;
    }
    if (this.params.type === 'print') {
      this.type = 'print';
      this.titleText = '下单成功';
      this.descText = '请添加商家微信进行联系';
      this.typeText = '文件打印';
      this.loadPrintOrder();
    } else if (this.params.type === 'express') {
      this.type = 'express';
      this.titleText = '下单成功';
      this.descText = '请添加商家微信进行联系';
      this.typeText = '快递代取';
      this.loadExpressOrder();
    }
  }

  async loadPrintOrder(): Promise<void> {
    const orderId = this.params.orderId === undefined ? '' : this.params.orderId;
    this.priceText = await CacheStore.getString(this.context, 'printPriceText', '');
    this.printOrder = await CacheStore.getJson<PrintOrder>(this.context, 'lastPrintOrder', new PrintOrder());
    if (orderId.length > 0 && this.printOrder.id !== orderId) {
      const orders = await CacheStore.getJson<PrintOrder[]>(this.context, 'printOrders', []);
      const found = orders.find((item: PrintOrder) => item.id === orderId);
      if (found !== undefined) {
        this.printOrder = found;
      }
    }
    this.orderFound = this.printOrder.id.length > 0;
    if (!this.orderFound && orderId.length > 0) {
      ToastUtil.show('订单信息加载失败');
    }
  }

  async loadExpressOrder(): Promise<void> {
    const orderId = this.params.orderId === undefined ? '' : this.params.orderId;
    const orders = await CacheStore.getJson<ExpressOrder[]>(this.context, 'expressOrders', []);
    const found = orders.find((item: ExpressOrder) => item.id === orderId);
    if (found !== undefined) {
      this.expressOrder = found;
      this.orderFound = true;
    } else if (orders.length > 0 && orderId.length === 0) {
      this.expressOrder = orders[0];
      this.orderFound = true;
    } else if (orderId.length > 0) {
      ToastUtil.show('订单信息加载失败');
    }
  }

  private orderIdText(id: string): string {
    return id.length > 0 ? id : 'draft';
  }

  private createdAtText(value: string): string {
    return value.length > 0 ? value : new Date().toLocaleString();
  }

  private amountText(count: number): string {
    const match = this.priceText.match(/([0-9]+(?:\.[0-9]+)?)/);
    if (match === null) {
      return '以商家确认为准';
    }
    const unitPrice = Number(match[1]);
    if (Number.isNaN(unitPrice) || unitPrice <= 0) {
      return '以商家确认为准';
    }
    return `¥${(unitPrice * count).toFixed(2)}（预估）`;
  }

  private statusColor(status: string): string {
    switch (status) {
      case '待支付':
        return '#FAAD14';
      case '已完成':
        return '#52C41A';
      case '已取消':
        return '#BFBFBF';
      default:
        return '#1890FF';
    }
  }

  private statusBg(status: string): string {
    switch (status) {
      case '待支付':
        return '#FFFBE6';
      case '已完成':
        return '#F6FFED';
      case '已取消':
        return '#F5F5F5';
      default:
        return '#E6F7FF';
    }
  }

  @Builder
  CardHeader(icon: string, label: string, status: string) {
    Row() {
      Row() {
        Text(icon)
          .fontSize(18)
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .layoutWeight(1)
      Text(status.length > 0 ? status : '待处理')
        .fontSize(12)
        .fontColor(this.statusColor(status))
        .fontWeight(FontWeight.Bold)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.statusBg(status))
        .borderRadius(14)
    }
    .width('100%')
    .padding({ bottom: 14 })
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#888888')
        .width(86)
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  @Builder
  ExpressCard() {
    Column() {
      this.CardHeader('📦', '快递代取', this.expressOrder.status)
      this.InfoRow('订单号:', this.orderIdText(this.expressOrder.id))
      this.InfoRow('收货地址:', this.expressOrder.addressDetails.length > 0 ? this.expressOrder.addressDetails : '未填写')
      this.InfoRow('快递大小:', this.expressOrder.packageSize)
      this.InfoRow('预估重量:', this.expressOrder.estimatedWeight)
      this.InfoRow('预估费用:', `¥${this.expressOrder.price.toFixed(2)}`)
      if (this.expressOrder.remark.length > 0) {
        this.InfoRow('备注:', this.expressOrder.remark)
      }
      this.InfoRow('创建时间:', this.createdAtText(this.expressOrder.createdAt))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 24 })
    .shadow({ radius: 20, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  PrintCard() {
    Column() {
      this.CardHeader('🖨️', '文件打印', this.printOrder.status)
      this.InfoRow('订单号:', this.orderIdText(this.printOrder.id))
      this.InfoRow('收货地址:', this.printOrder.address.length > 0 ? this.printOrder.address : '未填写')
      this.InfoRow('打印份数:', `${this.printOrder.count} 份`)
      this.InfoRow('金额:', this.amountText(this.printOrder.count))
      this.InfoRow('创建时间:', this.createdAtText(this.printOrder.createdAt))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 24 })
    .shadow({ radius: 20, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  DefaultCard() {
    Column() {
      this.CardHeader('🧾', this.typeText, '待处理')
      this.InfoRow('提交时间:', new Date().toLocaleString())
      this.InfoRow('处理方式:', '校内服务人员线下确认')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 24 })
    .shadow({ radius: 20, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }

  private hasOrderAction(): boolean {
    return this.type === 'print' || this.type === 'express';
  }

  private openOrder(): void {
    if (this.type === 'print') {
      router.pushUrl({ url: 'pages/MeOrder' });
    } else if (this.type === 'express') {
      router.replaceUrl({ url: 'pages/ServiceExpress' });
    }
  }

  build() {
    Column() {
      PageHeader({ title: '服务提交成功' })
      Scroll() {
        Column() {
          Column() {
            Text(this.titleText)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
            Text(this.descText)
              .fontSize(15)
              .fontColor('#888888')
              .width('100%')
              .margin({ top: 10 })

            if (this.type === 'express') {
              Text('演示订单：仅保存在本机，未提交到后端')
                .fontSize(12)
                .fontColor('#FA8C16')
                .width('100%')
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor('#FFF7E6')
                .borderRadius(8)
                .margin({ top: 12 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 30 })

          if (this.type === 'express') {
            this.ExpressCard()
          } else if (this.type === 'print') {
            this.PrintCard()
          } else {
            this.DefaultCard()
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 120 })
      }
      .layoutWeight(1)

      Row() {
        if (this.hasOrderAction()) {
          Button('查看订单')
            .layoutWeight(1)
            .height(50)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B00')
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#FF6B00' })
            .borderRadius(25)
            .onClick(() => {
              this.openOrder();
            })
        }
        Button('返回首页')
          .layoutWeight(this.hasOrderAction() ? 2 : 1)
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B00')
          .borderRadius(25)
          .margin({ left: this.hasOrderAction() ? 12 : 0 })
          .onClick(() => {
            router.replaceUrl({ url: 'pages/Index' });
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
