import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PrintOrder } from '../models/MiniProgramModels';
import { PrintApi } from '../api/PrintApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { EmptyState } from '../components/common/EmptyState';
import { PageHeader } from '../components/common/PageHeader';
import { Skeleton } from '../components/common/Skeleton';
@Entry
@Component
struct MeOrder {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State orders: PrintOrder[] = MockData.printOrders();
  @State activeFilter: string = 'all';
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const remote = await PrintApi.selfOrders(token, env);
      this.orders = remote.length > 0 ? remote : MockData.printOrders();
      await CacheStore.setJson<PrintOrder[]>(this.context, 'printOrders', this.orders);
    } catch (_) {
      this.orders = await CacheStore.getJson<PrintOrder[]>(this.context, 'printOrders', MockData.printOrders());
    } finally {
      this.loading = false;
    }
  }

  setFilter(value: string): void {
    this.activeFilter = value;
  }

  private visibleOrders(): PrintOrder[] {
    if (this.activeFilter === 'all') {
      return this.orders;
    }
    return this.orders.filter((order: PrintOrder) => order.status === this.activeFilter);
  }

  private statusColor(status: string): string {
    if (status === '已完成') {
      return '#52C41A';
    }
    if (status === '处理中') {
      return '#1890FF';
    }
    if (status === '已取消') {
      return '#999999';
    }
    return '#FA8C16';
  }

  private statusBg(status: string): string {
    if (status === '已完成') {
      return '#F6FFED';
    }
    if (status === '处理中') {
      return '#E6F7FF';
    }
    if (status === '已取消') {
      return '#F5F5F5';
    }
    return '#FFF2E8';
  }

  private createdText(order: PrintOrder): string {
    return order.createdAt.length > 0 ? order.createdAt : '刚刚';
  }

  gotoPrint(): void {
    router.pushUrl({ url: 'pages/ServicePrint' });
  }

  @Builder
  FilterTab(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.activeFilter === value ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.activeFilter === value ? '#007AFF' : '#666666')
      if (this.activeFilter === value) {
        Divider()
          .width(30)
          .height(2)
          .color('#007AFF')
          .margin({ top: 8 })
      } else {
        Divider()
          .width(30)
          .height(2)
          .color('#FFFFFF')
          .margin({ top: 8 })
      }
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(52)
    .onClick(() => {
      this.setFilter(value);
    })
  }

  @Builder
  FilterTabs() {
    Row() {
      this.FilterTab('全部', 'all')
      this.FilterTab('待处理', '待处理')
      this.FilterTab('处理中', '处理中')
      this.FilterTab('已完成', '已完成')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#EEEEEE' })
  }

  @Builder
  InfoRow(label: string, value: string) {
    if (value.length > 0) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor('#999999')
          .width(76)
        Text(value)
          .fontSize(13)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 6 })
    }
  }

  @Builder
  OrderCard(order: PrintOrder) {
    Column() {
      Row() {
        Column() {
          Text(`订单号: ${order.id}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(this.createdText(order))
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(order.status)
          .fontSize(12)
          .fontColor(this.statusColor(order.status))
          .backgroundColor(this.statusBg(order.status))
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      }
      .width('100%')

      Row() {
        Text('✈')
          .fontSize(20)
          .fontColor('#007AFF')
          .textAlign(TextAlign.Center)
          .width(34)
          .height(34)
          .borderRadius(17)
          .backgroundColor('#E6F2FF')
        Column() {
          Text('打印服务')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(order.fileName.length > 0 ? order.fileName : '文件打印')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
        Text(`${order.count}份`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ top: 14, bottom: 10 })

      Column() {
        this.InfoRow('服务方式:', order.type)
        this.InfoRow('联系人:', order.name)
        this.InfoRow('联系电话:', order.phone)
        this.InfoRow('配送地址:', order.address)
        this.InfoRow('备注:', order.remark)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .shadow({ radius: 6, color: '#14000000', offsetX: 0, offsetY: 2 })
  }

  build() {
    Column() {
      PageHeader({ title: '我的订单' })
      this.FilterTabs()
      Scroll() {
        Column() {
          if (this.loading) {
            Skeleton({ rows: 4, showAvatar: false })
              .margin({ top: 10 })
          } else if (this.visibleOrders().length > 0) {
            ForEach(this.visibleOrders(), (order: PrintOrder) => {
              this.OrderCard(order)
            }, (order: PrintOrder) => order.id)
          } else {
            EmptyState({
              title: '暂无订单记录',
              description: '您还没有任何打印订单',
              actionText: '去打印',
              cardBg: '#FFFFFF',
              onAction: () => {
                this.gotoPrint();
              }
            })
              .margin({ top: 40 })
          }
        }
        .width('100%')
        .padding(10)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
