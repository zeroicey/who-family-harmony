import { DateUtil } from '../utils/DateUtil';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PrintOrder } from '../models/MiniProgramModels';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

export class PrintSuccessParams {
  type: string = '';
  orderId: string = '';
}

@Entry
@Component
struct ServicePrintSuccess {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private params: PrintSuccessParams = new PrintSuccessParams();
  @State order: PrintOrder = new PrintOrder();
  @State priceText: string = '';
  @State loaded: boolean = false;

  aboutToAppear(): void {
    this.params = router.getParams() as PrintSuccessParams;
    this.loadOrder();
  }

  async loadOrder(): Promise<void> {
    const cached = await CacheStore.getJson<PrintOrder>(this.context, 'lastPrintOrder', new PrintOrder());
    this.order = this.normalizeOrder(cached);
    this.priceText = await CacheStore.getString(this.context, 'printPriceText', '');
    const orderId = (this.params === null || this.params === undefined || this.params.orderId === undefined)
      ? '' : `${this.params.orderId}`;
    if (orderId.length > 0 && this.order.id !== orderId) {
      const orders = await CacheStore.getJson<PrintOrder[]>(this.context, 'printOrders', []);
      const found = orders.find((item: PrintOrder) => `${item.id}` === orderId);
      if (found !== undefined) {
        this.order = this.normalizeOrder(found);
      } else {
        ToastUtil.show('订单信息加载失败');
      }
    }
    this.loaded = true;
  }

  /** 后端/缓存中的 id 可能是数字，统一归一为字符串。 */
  private normalizeOrder(raw: PrintOrder): PrintOrder {
    const order = new PrintOrder(
      raw.id === undefined || raw.id === null ? '' : `${raw.id}`,
      raw.type, raw.address, raw.name, raw.phone, raw.count,
      raw.fileName, raw.remark, raw.status, raw.createdAt);
    order.startOrderTime = raw.startOrderTime === undefined ? '' : raw.startOrderTime;
    order.endOrderTime = raw.endOrderTime === undefined ? '' : raw.endOrderTime;
    return order;
  }

  private orderIdText(): string {
    return this.order.id.length > 0 ? this.order.id : 'draft';
  }

  private createdAtText(): string {
    return this.order.createdAt.length > 0 ? this.order.createdAt : DateUtil.nowText();
  }

  /** 参考实现无金额字段：按价格文案中的单价 × 份数给出预估，最终以商家报价为准。 */
  private amountText(): string {
    const match = this.priceText.match(/([0-9]+(?:\.[0-9]+)?)/);
    if (match === null) {
      return '以商家确认为准';
    }
    const unitPrice = Number(match[1]);
    if (isNaN(unitPrice) || unitPrice <= 0) {
      return '以商家确认为准';
    }
    const total = unitPrice * this.order.count;
    return `¥${total.toFixed(2)}（预估）`;
  }

  private statusColor(): string {
    switch (this.order.status) {
      case '待支付':
        return '#FAAD14';
      case '待完成':
        return '#1890FF';
      case '已完成':
        return '#52C41A';
      case '已取消':
        return '#BFBFBF';
      default:
        return '#1890FF';
    }
  }

  private statusBg(): string {
    switch (this.order.status) {
      case '待支付':
        return '#FFFBE6';
      case '待完成':
        return '#E6F7FF';
      case '已完成':
        return '#F6FFED';
      case '已取消':
        return '#F5F5F5';
      default:
        return '#E6F7FF';
    }
  }

  @Builder
  OrderCard() {
    Column() {
      Row() {
        Row() {
          Text('🖨️')
            .fontSize(18)
          Text('文件打印')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 8 })
        }
        .layoutWeight(1)
        Text(this.order.status.length > 0 ? this.order.status : '待处理')
          .fontSize(12)
          .fontColor(this.statusColor())
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.statusBg())
          .borderRadius(14)
      }
      .width('100%')
      .padding({ bottom: 14 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      this.InfoRow('订单号:', this.orderIdText())
      this.InfoRow('收货地址:', this.order.address.length > 0 ? this.order.address : '未填写')
      this.InfoRow('打印份数:', `${this.order.count} 份`)
      this.InfoRow('金额:', this.amountText())
      this.InfoRow('创建时间:', this.createdAtText())
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

  build() {
    Column() {
      PageHeader({ title: '打印下单成功' })
      Scroll() {
        Column() {
          Column() {
            Text('下单成功')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
            Text('请添加商家微信进行联系')
              .fontSize(15)
              .fontColor('#888888')
              .width('100%')
              .margin({ top: 10 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 30 })

          if (this.loaded) {
            this.OrderCard()
          } else {
            LoadingProgress()
              .width(36)
              .height(36)
              .color('#FF6B00')
              .margin({ top: 60 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 120 })
      }
      .layoutWeight(1)

      Row() {
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
            router.pushUrl({ url: 'pages/MeOrder' });
          })
        Button('返回首页')
          .layoutWeight(2)
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B00')
          .borderRadius(25)
          .margin({ left: 12 })
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
