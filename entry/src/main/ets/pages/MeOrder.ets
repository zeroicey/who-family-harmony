import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PrintOrder } from '../models/MiniProgramModels';
import { PrintApi } from '../api/PrintApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { EmptyState } from '../components/common/EmptyState';
import { PageHeader } from '../components/common/PageHeader';
import { Skeleton } from '../components/common/Skeleton';
@Entry
@Component
struct MeOrder {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State orders: PrintOrder[] = [];
  @State activeFilter: string = 'all';
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  private safeText(value: string | number | null | undefined): string {
    if (value === null || value === undefined || value === 0) {
      return '';
    }
    return `${value}`;
  }

  /** 后端字段可能为 null，先归一化再进列表，避免渲染期读取 null。 */
  private normalizeOrder(raw: PrintOrder): PrintOrder {
    const order = new PrintOrder(
      this.safeText(raw.id),
      this.safeText(raw.type).length > 0 ? this.safeText(raw.type) : '派送服务',
      this.safeText(raw.address),
      this.safeText(raw.name),
      this.safeText(raw.phone),
      Number(raw.count) > 0 ? Number(raw.count) : 1,
      this.safeText(raw.fileName),
      this.safeText(raw.remark),
      this.safeText(raw.status).length > 0 ? this.safeText(raw.status) : '待处理',
      this.safeText(raw.createdAt)
    );
    order.startOrderTime = this.safeText(raw.startOrderTime);
    order.endOrderTime = this.safeText(raw.endOrderTime);
    return order;
  }

  async load(): Promise<void> {
    this.loading = true;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const remote = await PrintApi.selfOrders(token, env);
      // 与参考一致：后端返回空数组时展示空态，不用演示订单顶替。
      this.orders = remote.map((raw: PrintOrder) => this.normalizeOrder(raw));
      await CacheStore.setJson<PrintOrder[]>(this.context, 'printOrders', this.orders);
    } catch (_) {
      const cached = await CacheStore.getJson<PrintOrder[]>(this.context, 'printOrders', []);
      this.orders = cached.map((raw: PrintOrder) => this.normalizeOrder(raw));
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
    if (status === '处理中') {
      return '#1976D2';
    }
    if (status === '已完成') {
      return '#388E3C';
    }
    if (status === '已取消') {
      return '#D32F2F';
    }
    return '#F57C00';
  }

  private statusBg(status: string): string {
    if (status === '处理中') {
      return '#E3F2FD';
    }
    if (status === '已完成') {
      return '#E8F5E8';
    }
    if (status === '已取消') {
      return '#FCE4EC';
    }
    return '#FFF3E0';
  }

  /** 小程序订单头部展示下单时间（startOrderTime）。 */
  private createdText(order: PrintOrder): string {
    if (order.startOrderTime.length > 0) {
      return order.startOrderTime;
    }
    return '刚刚';
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
          .fontSize(14)
          .fontColor('#666666')
          .width(80)
        Text(value)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
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
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
      }
      .width('100%')
      .padding({ top: 14, bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Column() {
        this.InfoRow('服务方式:', order.type)
        this.InfoRow('联系人:', order.name)
        this.InfoRow('联系电话:', order.phone)
        this.InfoRow('配送地址:', order.type === '派送服务' ? order.address : '')
        this.InfoRow('备注:', order.remark)
        this.InfoRow('创建时间:', order.startOrderTime)
        this.InfoRow('完成时间:', order.endOrderTime)
      }
      .width('100%')
      .padding({ top: 10 })
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
              iconText: '☰',
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
