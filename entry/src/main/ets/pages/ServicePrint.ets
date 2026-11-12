import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { CoverImage } from '../components/common/CoverImage';
import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { PrimaryButton } from '../components/common/PrimaryButton';
import { AddressItem, PrintOrder } from '../models/MiniProgramModels';
import { PrintApi } from '../api/PrintApi';
import { UserApi } from '../api/UserApi';
import { PickedFile, UploadService } from '../services/UploadService';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct ServicePrint {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State serviceOpen: boolean = true;
  @State serviceType: string = 'delivery';
  @State priceText: string = '';
  @State loading: boolean = false;
  @State selectedFile: PickedFile | null = null;
  @State defaultAddress: AddressItem | null = null;
  @State order: PrintOrder = new PrintOrder('draft', '派送服务', '', '互成一家用户', '', 1, '', '', '待提交');
  private confirmController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '确认下单',
      message: '确认提交打印订单吗？提交后将进入处理流程。',
      confirmText: '确认下单',
      onConfirm: () => {
        this.doSubmit();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.loadPrintInfo();
    this.loadDefaultAddress();
  }

  onPageShow(): void {
    this.loadDefaultAddress();
  }

  private addressText(): string {
    const address = this.defaultAddress;
    return address === null ? '' : `${address.area}${address.detail}`;
  }

  /** 复用「我的地址」：优先默认地址，其次第一条；本地缓存兜底。 */
  async loadDefaultAddress(): Promise<void> {
    let addresses: AddressItem[] = [];
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      addresses = await UserApi.loadAddresses(token, env);
    } catch (err) {
      LogUtil.warn('print', `load addresses failed ${(err as Error).message}`);
    }
    if (addresses.length === 0) {
      addresses = await CacheStore.getJson<AddressItem[]>(this.context, 'addresses', []);
    }
    let selected: AddressItem | null = null;
    for (let index = 0; index < addresses.length; index++) {
      if (addresses[index].isDefault) {
        selected = addresses[index];
        break;
      }
    }
    if (selected === null && addresses.length > 0) {
      selected = addresses[0];
    }
    this.defaultAddress = selected;
    if (selected !== null) {
      if (this.serviceType === 'delivery') {
        this.order.address = `${selected.area}${selected.detail}`;
      }
      if (this.order.phone.trim().length === 0) {
        this.order.phone = selected.phone;
      }
    } else if (this.serviceType === 'delivery') {
      this.order.address = '';
    }
  }

  async loadPrintInfo(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      this.serviceOpen = await PrintApi.isOpen(token, env);
      this.priceText = await PrintApi.priceText(token, env);
      await CacheStore.setString(this.context, 'printPriceText', this.priceText);
    } catch (_) {
      this.priceText = await CacheStore.getString(this.context, 'printPriceText', '黑白打印 0.2 元/页，彩色打印 1 元/页，装订服务 2 元/份');
      ToastUtil.demoData();
    }
  }

  private setServiceType(type: string): void {
    this.serviceType = type;
    this.order.type = type === 'pickup' ? '上门取件' : '派送服务';
    this.order.address = type === 'delivery' ? this.addressText() : '';
    const address = this.defaultAddress;
    if (this.order.phone.trim().length === 0 && address !== null) {
      this.order.phone = address.phone;
    }
  }

  private changeCount(delta: number): void {
    const next = this.order.count + delta;
    if (next < 1 || next > 99) {
      return;
    }
    this.order.count = next;
  }

  /** 文件管理器选择打印文件，读取为内存 ArrayBuffer 以便转 base64 下单。 */
  async chooseFile(): Promise<void> {
    try {
      const picked = await UploadService.pickDocuments(this.context, 1);
      if (picked.length === 0) {
        return;
      }
      const file: PickedFile = picked[0];
      const reason = UploadService.checkDocument(file);
      if (reason.length > 0) {
        ToastUtil.show(reason);
        return;
      }
      this.selectedFile = file;
      this.order.fileName = file.name;
      ToastUtil.show('文件选择成功');
    } catch (err) {
      LogUtil.warn('print', `pick document failed ${(err as Error).message}`);
      ToastUtil.show('文件选择失败，请重试');
    }
  }

  removeFile(): void {
    this.selectedFile = null;
    this.order.fileName = '';
    ToastUtil.show('文件已移除');
  }

  private selectedFileName(): string {
    const file = this.selectedFile;
    return file === null ? '' : file.name;
  }

  private selectedFileSize(): string {
    const file = this.selectedFile;
    return file === null ? '' : file.sizeText();
  }

  submitOrder(): void {
    if (!this.serviceOpen) {
      ToastUtil.show('打印服务暂未开启');
      return;
    }
    if (this.selectedFile === null) {
      ToastUtil.show('请先选择要打印的文件');
      return;
    }
    if (this.serviceType === 'delivery' && this.defaultAddress === null) {
      ToastUtil.show('请选择收货地址');
      return;
    }
    if (this.serviceType === 'pickup' && this.order.phone.trim().length === 0) {
      ToastUtil.show('请填写联系电话');
      return;
    }
    if (this.serviceType === 'delivery' && this.addressPhone().trim().length === 0) {
      ToastUtil.show('收货地址缺少联系电话，请完善地址信息');
      return;
    }
    this.syncOrderFields();
    this.confirmController.open();
  }

  private addressPhone(): string {
    const address = this.defaultAddress;
    return address === null ? '' : address.phone;
  }

  /** 与小程序 PrintForm 的订单字段保持一致。 */
  private syncOrderFields(): void {
    this.order.type = this.serviceType === 'pickup' ? '上门取件' : '派送服务';
    this.order.address = this.serviceType === 'delivery' ? this.addressText() : '';
    this.order.phone = this.serviceType === 'pickup' ? this.order.phone.trim() : this.addressPhone();
  }

  async doSubmit(): Promise<void> {
    this.syncOrderFields();
    const file = this.selectedFile;
    if (file === null) {
      ToastUtil.show('请先选择要打印的文件');
      return;
    }
    if (this.loading) {
      return;
    }
    this.loading = true;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const fileDataUrl = `data:${file.mimeType};base64,${file.base64()}`;
      const result = await PrintApi.createOrder(token, this.order, env, fileDataUrl);
      const created = result === null ? this.order : result;
      if (created.createdAt.length === 0) {
        created.createdAt = new Date().toLocaleString();
      }
      await CacheStore.setJson<PrintOrder>(this.context, 'lastPrintOrder', created);
      ToastUtil.show('下单成功');
      router.pushUrl({ url: 'pages/ServicePrintSuccess', params: { type: 'print', orderId: created.id } });
    } catch (err) {
      ToastUtil.show(`打印下单失败：${(err as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  @Builder
  ServiceClosedModal() {
    if (!this.serviceOpen) {
      Column() {
        Text('🚫')
          .fontSize(52)
        Text('打印服务暂未开启')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 14 })
        Text('服务开启时间：周一至周五 8:00-18:00')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 14 })
        Text('请在服务时间内使用打印功能')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
        Button('返回主页')
          .width('100%')
          .height(44)
          .backgroundColor('#007AFF')
          .borderRadius(10)
          .margin({ top: 24 })
          .onClick(() => {
            router.replaceUrl({ url: 'pages/Index' });
          })
      }
      .width('86%')
      .padding(28)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
    }
  }

  @Builder
  IntroCard() {
    Column() {
      Text('校园打印服务 | 便捷文印助手')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text('快速便民，打印服务触手可及！')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 9 })
      Row() {
        this.Tag('快速出稿')
        this.Tag('多点可取')
        this.Tag('学生优惠')
      }
      .margin({ top: 16 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: -28 })
  }

  @Builder
  Tag(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#007AFF')
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor('#E8F4FF')
      .borderRadius(14)
      .margin({ right: 8 })
  }

  @Builder
  NoticeCard() {
    Column() {
      Row() {
        Text('ℹ️')
          .fontSize(18)
        Text('服务范围说明')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
          .margin({ left: 8 })
      }
      Text('仅限南海大学城区域内下单，配送仅限广东东软学院校内以及小镇宿舍。')
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF8F0')
    .border({ width: 1, color: '#FF6B35' })
    .borderRadius(14)
    .margin({ top: 14 })
  }

  @Builder
  PriceCard() {
    Column() {
      Row() {
        Text('💳')
          .fontSize(20)
        Text('打印价格')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      Text(this.priceText.length > 0 ? this.priceText : '价格加载中...')
        .fontSize(14)
        .fontColor(this.priceText.length > 0 ? '#333333' : '#999999')
        .lineHeight(21)
        .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  PrintForm() {
    Column() {
      this.FormLabel('服务方式')
      Row() {
        this.ServiceOption('pickup', '👤', '自己上门取件')
        this.ServiceOption('delivery', '✈️', '派送服务')
      }
      .width('100%')

      if (this.serviceType === 'delivery') {
        this.FormLabel('收货地址')
        Row() {
          Text(this.defaultAddress === null ? '请选择或新建地址' : this.addressText())
            .fontSize(14)
            .fontColor(this.defaultAddress === null ? '#999999' : '#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('›')
            .fontSize(20)
            .fontColor('#C7C7CC')
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 14, right: 12, top: 12, bottom: 12 })
        .backgroundColor('#F8F9FA')
        .borderRadius(14)
        .onClick(() => {
          router.pushUrl({ url: 'pages/MeAddress' });
        })
      }

      this.FormLabel('上传文件')
      if (this.selectedFile !== null) {
        Row() {
          Text('📄')
            .fontSize(22)
            .margin({ right: 10 })
          Column() {
            Text(this.selectedFileName())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.selectedFileSize())
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 3 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('移除')
            .fontSize(13)
            .fontColor('#FF3B30')
            .padding({ left: 10, right: 4, top: 6, bottom: 6 })
            .onClick(() => {
              this.removeFile();
            })
        }
        .width('100%')
        .padding({ left: 14, right: 10, top: 10, bottom: 10 })
        .backgroundColor('#F8F9FA')
        .borderRadius(14)
      } else {
        Row() {
          Text('点击选择文件 (支持 PDF，DOCS，DOC)')
            .fontSize(14)
            .fontColor('#999999')
            .layoutWeight(1)
          Text('选择')
            .fontSize(14)
            .fontColor('#007AFF')
        }
        .width('100%')
        .height(52)
        .padding({ left: 14, right: 14 })
        .backgroundColor('#F8F9FA')
        .borderRadius(14)
        .onClick(() => {
          this.chooseFile();
        })
      }

      this.FormLabel('打印份数')
      Row() {
        Text('−')
          .fontSize(24)
          .fontColor('#007AFF')
          .textAlign(TextAlign.Center)
          .width(42)
          .height(42)
          .borderRadius(21)
          .backgroundColor('#E8F4FF')
          .onClick(() => {
            this.changeCount(-1);
          })
        Text(`${this.order.count}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Text('+')
          .fontSize(24)
          .fontColor('#007AFF')
          .textAlign(TextAlign.Center)
          .width(42)
          .height(42)
          .borderRadius(21)
          .backgroundColor('#E8F4FF')
          .onClick(() => {
            this.changeCount(1);
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#F8F9FA')
      .borderRadius(14)

      if (this.serviceType === 'pickup') {
        this.FormLabel('联系电话')
        TextInput({
          placeholder: this.addressPhone().length > 0 ? `默认: ${this.addressPhone()}` : '请输入手机号',
          text: this.order.phone
        })
          .height(48)
          .backgroundColor('#F8F9FA')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.order.phone = value;
          })

        Text(this.addressPhone().length > 0 ?
          '已自动填入默认手机号，可修改。务必确保手机号可以拨通，因手机号无法拨通导致的问题自行承担' :
          '请填写可以拨通的手机号，务必确保手机号可以拨通，因手机号无法拨通导致的问题自行承担')
          .fontSize(12)
          .fontColor('#FF6B35')
          .lineHeight(18)
          .margin({ top: 10 })
      }

      PrimaryButton({
        text: '立即下单',
        loading: this.loading,
        buttonHeight: 50,
        buttonRadius: 25,
        onTap: () => {
          this.submitOrder();
        }
      })
        .margin({ top: 18 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  FormLabel(label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#333333')
      .margin({ top: 14, bottom: 8 })
  }

  @Builder
  ServiceOption(type: string, icon: string, label: string) {
    Row() {
      Text(icon)
        .fontSize(16)
      Text(label)
        .fontSize(13)
        .fontColor(this.serviceType === type ? '#007AFF' : '#999999')
        .fontWeight(this.serviceType === type ? FontWeight.Bold : FontWeight.Regular)
        .margin({ left: 6 })
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(42)
    .backgroundColor(this.serviceType === type ? '#E8F4FF' : '#F8F9FA')
    .borderRadius(12)
    .margin({ right: type === 'pickup' ? 8 : 0 })
    .onClick(() => {
      this.setServiceType(type);
    })
  }

  @Builder
  ServiceInfoCard() {
    Column() {
      Text('服务信息')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      if (this.serviceType === 'pickup') {
        this.InfoRow('上门取件地址：', '广东东软学院图书馆4楼sovo互成一家工位')
        this.InfoRow('营业时间：', '周一至周日 9:00-21:00')
      } else {
        Row() {
          Text('送货上门地址：')
            .fontSize(13)
            .fontColor('#666666')
            .width(112)
          Text(this.order.address.length > 0 ? this.order.address : '请先选择收货地址')
            .fontSize(13)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Top)
        .margin({ top: 12 })
        this.InfoRow('配送时间：', '工作日 10:00-18:00（节假日顺延）')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width(112)
      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .margin({ top: 12 })
  }

  @Builder
  WhyUsCard() {
    Column() {
      this.FeatureBlock('服务优势', '✈️ 简单操作，一键上传文件', '⚙️ 专业设备，高质量打印', '🤝 增值服务，装订整理')
      this.FeatureBlock('附加服务', '🔥 加急服务，快速处理', '⬇️ 多种格式，全面支持', '✅ 专业装帧，精美呈现')
    }
    .width('100%')
    .margin({ top: 14, bottom: 24 })
  }

  @Builder
  FeatureBlock(title: string, first: string, second: string, third: string) {
    Column() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      this.FeatureRow(first)
      this.FeatureRow(second)
      this.FeatureRow(third)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ bottom: 14 })
  }

  @Builder
  FeatureRow(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor('#555555')
      .margin({ top: 12 })
  }

  build() {
    Stack() {
      if (!this.serviceOpen) {
        Column() {
          this.ServiceClosedModal()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
      } else {
        Column() {
          PageHeader({ title: '文件打印' })
          Scroll() {
            Column() {
              CoverImage({
                imageUrl: 'https://api.hcyj.xyz/images/dnfw.png',
                title: '',
                watermarkText: '互成一家 | 校园打印服务',
                imageHeight: 220,
                imageRadius: 0
              })
              this.IntroCard()
              this.NoticeCard()
              this.PriceCard()
              this.PrintForm()
              this.ServiceInfoCard()
              this.WhyUsCard()
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F7')
      }
    }
    .width('100%')
    .height('100%')
  }
}
