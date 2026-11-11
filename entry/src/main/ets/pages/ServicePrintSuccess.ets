import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PrintOrder } from '../models/MiniProgramModels';
import { CacheStore } from '../stores/CacheStore';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct ServicePrintSuccess {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State order: PrintOrder = new PrintOrder('draft', '文件打印', '广东东软学院 SOVO 公寓', '互成一家用户', '', 1, '实验报告.pdf', '', '待处理', '');

  aboutToAppear(): void {
    this.loadOrder();
  }

  async loadOrder(): Promise<void> {
    this.order = await CacheStore.getJson<PrintOrder>(this.context, 'lastPrintOrder', this.order);
  }

  private orderIdText(): string {
    return this.order.id.length > 0 ? this.order.id : 'draft';
  }

  private createdAtText(): string {
    return this.order.createdAt.length > 0 ? this.order.createdAt : new Date().toLocaleString();
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
          .fontColor('#1890FF')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#E6F7FF')
          .borderRadius(14)
      }
      .width('100%')
      .padding({ bottom: 14 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      this.InfoRow('订单号:', this.orderIdText())
      this.InfoRow('收货地址:', this.order.address.length > 0 ? this.order.address : '未填写')
      this.InfoRow('打印份数:', `${this.order.count} 份`)
      this.InfoRow('创建时间:', this.createdAtText())
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 24 })
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

          this.OrderCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 120 })
      }
      .layoutWeight(1)

      Button('返回首页')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B00')
        .borderRadius(25)
        .margin({ left: 20, right: 20, top: 12, bottom: 20 })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/Index' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
