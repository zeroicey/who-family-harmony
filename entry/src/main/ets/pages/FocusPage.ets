import { common } from '@kit.AbilityKit';
import { FocusApi } from '../api/FocusApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct FocusPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private quotes: string[] = [
    '每一次专注，都是向目标迈进的一大步。',
    '时间是海绵里的水，只要愿挤，总还是有的。',
    '坚持一下，胜利就在眼前。',
    '专注力是成功的关键。',
    '今天你专注了吗？为自己点赞！'
  ];
  @State todayMinutes: number = 0;
  @State currentSeconds: number = 0;
  @State isFocusing: boolean = false;
  @State showCompletion: boolean = false;
  @State quoteIndex: number = 0;

  aboutToAppear(): void {
    this.loadTodayFocus();
  }

  private formatTotal(minutes: number): string {
    if (minutes <= 0) {
      return '0分钟';
    }
    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    if (hours > 0) {
      return `${hours}小时${rest}分钟`;
    }
    return `${rest}分钟`;
  }

  private formatTimer(seconds: number): string {
    const hours = Math.floor(seconds / 3600).toString().padStart(2, '0');
    const minutes = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
    const rest = (seconds % 60).toString().padStart(2, '0');
    return `${hours}:${minutes}:${rest}`;
  }

  private currentQuote(): string {
    return this.quotes[this.quoteIndex % this.quotes.length];
  }

  async loadTodayFocus(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      this.todayMinutes = await FocusApi.today(token, env);
      await CacheStore.setString(this.context, 'todayFocus', this.todayMinutes.toString());
    } catch (_) {
      const cached = await CacheStore.getString(this.context, 'todayFocus', '0');
      this.todayMinutes = Number(cached);
    }
  }

  startFocus(): void {
    this.isFocusing = true;
    this.showCompletion = false;
    this.currentSeconds = 0;
    this.quoteIndex = (this.quoteIndex + 1) % this.quotes.length;
  }

  async endFocus(): Promise<void> {
    if (!this.isFocusing) {
      return;
    }
    const minutes = this.currentSeconds < 60 ? 1 : Math.ceil(this.currentSeconds / 60);
    this.isFocusing = false;
    this.currentSeconds = 0;
    this.todayMinutes += minutes;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await FocusApi.submit(token, minutes, env);
      ToastUtil.show('专注完成！');
    } catch (err) {
      ToastUtil.show(`专注记录提交失败：${(err as Error).message}`);
    }
    await CacheStore.setString(this.context, 'todayFocus', this.todayMinutes.toString());
    this.showCompletion = true;
  }

  cancelFocus(): void {
    if (!this.isFocusing) {
      return;
    }
    AlertDialog.show({
      title: '提示',
      message: '确定要放弃本次专注吗？',
      primaryButton: {
        value: '确定',
        action: () => {
          this.isFocusing = false;
          this.currentSeconds = 0;
          this.quoteIndex = (this.quoteIndex + 1) % this.quotes.length;
          ToastUtil.show('已取消专注');
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }

  @Builder
  Header() {
    Column() {
      Text('专注时刻')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text(`今日已专注：${this.formatTotal(this.todayMinutes)}`)
        .fontSize(17)
        .fontColor('#666666')
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .margin({ top: 38, bottom: 42 })
  }

  @Builder
  TimerCircle() {
    Column() {
      Text(this.formatTimer(this.currentSeconds))
        .fontSize(42)
        .fontWeight(FontWeight.Bold)
        .fontColor('#409EFF')
        .fontFamily('Courier New')
    }
    .width(210)
    .height(210)
    .borderRadius(105)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .border({ width: 6, color: '#409EFF' })
    .shadow({ radius: 18, color: 0x18000000, offsetY: 6 })
  }

  @Builder
  Controls() {
    Column() {
      if (!this.isFocusing) {
        Button('开始专注')
          .width('80%')
          .height(50)
          .fontSize(17)
          .fontColor('#FFFFFF')
          .backgroundColor('#409EFF')
          .borderRadius(25)
          .onClick(() => {
            this.startFocus();
          })
      } else {
        Button('结束专注')
          .width('80%')
          .height(50)
          .fontSize(17)
          .fontColor('#FFFFFF')
          .backgroundColor('#F56C6C')
          .borderRadius(25)
          .onClick(() => {
            this.endFocus();
          })
        Button('放弃专注')
          .width('80%')
          .height(50)
          .fontSize(17)
          .fontColor('#FFFFFF')
          .backgroundColor('#909399')
          .borderRadius(25)
          .margin({ top: 14 })
          .onClick(() => {
            this.cancelFocus();
          })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .margin({ top: 44 })
  }

  @Builder
  Tips() {
    Column() {
      Text(this.currentQuote())
        .fontSize(17)
        .fontColor('#555555')
        .fontStyle(FontStyle.Italic)
        .lineHeight(25)
        .textAlign(TextAlign.Center)
      if (this.isFocusing && !this.showCompletion) {
        Text('专注期间请勿退出或锁屏，否则计时将中断')
          .fontSize(13)
          .fontColor('#AAAAAA')
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .margin({ top: 40 })
  }

  @Builder
  Completion() {
    if (this.showCompletion) {
      Column() {
        Text('✓')
          .fontSize(54)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(112)
          .height(112)
          .borderRadius(56)
          .backgroundColor('#409EFF')
        Text('太棒了！专注完成！')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#409EFF')
          .margin({ top: 22 })
      }
      .width('100%')
      .padding(28)
      .backgroundColor(0xEEFFFFFF)
      .position({ x: 0, y: 260 })
      .zIndex(5)
      .onClick(() => {
        this.showCompletion = false;
      })
    }
  }

  build() {
    Stack() {
      Column() {
        PageHeader({ title: '专注' })
        this.Header()
        this.TimerCircle()
        this.Controls()
        this.Tips()
        Blank()
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F0F2F5')
      this.Completion()
    }
    .width('100%')
    .height('100%')
  }
}
