import { common } from '@kit.AbilityKit';
import { FocusApi } from '../api/FocusApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

/** 跨页面保留的专注会话（参考实现由 Vuex store 持有同样状态）。 */
class FocusSession {
  static focusing: boolean = false;
  static startTime: number = 0;
  static todayMinutes: number = 0;
}

@Entry
@Component
struct FocusPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private quotes: string[] = [
    '每一次专注，都是向目标迈进的一大步。',
    '时间是海绵里的水，只要愿挤，总还是有的。',
    '坚持一下，胜利就在眼前。',
    '专注力是成功的关键。',
    '今天你专注了吗？为自己点赞！',
    '一分耕耘，一分收获。',
    '保持专注，未来可期。',
    '别让琐事打断你的节奏。',
    '高效的时间利用，源于专注。',
    '每一次专注，都是对未来的投资。',
    '相信自己，你能做到！'
  ];
  private timerId: number = -1;
  private completionTimer: number = -1;
  @State todayMinutes: number = 0;
  @State currentSeconds: number = 0;
  @State isFocusing: boolean = false;
  @State showCompletion: boolean = false;
  @State quoteIndex: number = 0;

  aboutToAppear(): void {
    this.loadTodayFocus();
    this.isFocusing = FocusSession.focusing;
    if (this.isFocusing && FocusSession.startTime > 0) {
      this.currentSeconds = Math.floor((Date.now() - FocusSession.startTime) / 1000);
      this.startTimer();
    }
    this.quoteIndex = this.randomQuoteIndex();
  }

  aboutToDisappear(): void {
    this.stopTimer();
    if (this.completionTimer !== -1) {
      clearTimeout(this.completionTimer);
      this.completionTimer = -1;
    }
  }

  private randomQuoteIndex(): number {
    return Math.floor(Math.random() * this.quotes.length);
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

  private startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.tick();
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private tick(): void {
    if (!this.isFocusing || FocusSession.startTime <= 0) {
      return;
    }
    const nextSeconds = Math.floor((Date.now() - FocusSession.startTime) / 1000);
    const previousMinute = Math.floor(this.currentSeconds / 60);
    const nextMinute = Math.floor(nextSeconds / 60);
    this.currentSeconds = nextSeconds;
    // 参考实现每满一分钟刷新一条激励语。
    if (nextMinute > previousMinute) {
      this.quoteIndex = this.randomQuoteIndex();
    }
  }

  async loadTodayFocus(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      this.todayMinutes = await FocusApi.today(token, env);
      FocusSession.todayMinutes = this.todayMinutes;
      await CacheStore.setString(this.context, 'todayFocus', this.todayMinutes.toString());
    } catch (_) {
      const cached = await CacheStore.getString(this.context, 'todayFocus', '0');
      this.todayMinutes = Number(cached);
      FocusSession.todayMinutes = this.todayMinutes;
    }
  }

  startFocus(): void {
    FocusSession.focusing = true;
    FocusSession.startTime = Date.now();
    this.isFocusing = true;
    this.currentSeconds = 0;
    this.showCompletion = false;
    this.startTimer();
  }

  endFocus(): void {
    if (!this.isFocusing) {
      return;
    }
    const durationMs = Date.now() - FocusSession.startTime;
    FocusSession.focusing = false;
    FocusSession.startTime = 0;
    this.isFocusing = false;
    this.stopTimer();

    // 与参考 store 一致：不足 1 分钟按 1 分钟计，不足 10 分钟不记录。
    let focusMinutes = Math.ceil(durationMs / (1000 * 60));
    if (durationMs > 0 && focusMinutes === 0) {
      focusMinutes = 1;
    }
    if (focusMinutes < 10) {
      ToastUtil.show('专注时间太少，至少需要10分钟哦');
      return;
    }
    this.submitFocus(focusMinutes);
  }

  async submitFocus(minutes: number): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await FocusApi.submit(token, minutes, env);
      await this.loadTodayFocus();
      this.quoteIndex = this.randomQuoteIndex();
      ToastUtil.show('专注完成！');
      this.showCompletion = true;
      if (this.completionTimer !== -1) {
        clearTimeout(this.completionTimer);
      }
      this.completionTimer = setTimeout(() => {
        this.showCompletion = false;
        this.quoteIndex = this.randomQuoteIndex();
        this.completionTimer = -1;
      }, 2500);
    } catch (err) {
      ToastUtil.show((err as Error).message);
    }
  }

  cancelFocus(): void {
    FocusSession.focusing = false;
    FocusSession.startTime = 0;
    this.isFocusing = false;
    this.currentSeconds = 0;
    this.showCompletion = false;
    this.stopTimer();
    this.quoteIndex = this.randomQuoteIndex();
    ToastUtil.show('已取消专注');
  }

  confirmCancel(): void {
    AlertDialog.show({
      title: '放弃专注',
      message: '确定要放弃本次专注吗？当前专注时长将不会记录。',
      primaryButton: {
        value: '放弃专注',
        fontColor: '#F56C6C',
        action: () => {
          this.cancelFocus();
        }
      },
      secondaryButton: {
        value: '继续专注',
        action: () => {
        }
      }
    });
  }

  @Builder
  TimerPanel() {
    Column() {
      Text(this.formatTimer(this.currentSeconds))
        .fontSize(44)
        .fontWeight(FontWeight.Bold)
        .fontColor('#409EFF')
        .fontFamily('Courier New')
    }
    .width(220)
    .height(220)
    .borderRadius(110)
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.Center)
    .border({ width: 5, color: '#409EFF' })
    .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 5 })
  }

  @Builder
  Controls() {
    Column() {
      if (!this.isFocusing) {
        Button('开始专注')
          .width('80%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#409EFF')
          .borderRadius(24)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            this.startFocus();
          })
      } else {
        Button('结束专注')
          .width('80%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#F56C6C')
          .borderRadius(24)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            this.endFocus();
          })
        Button('放弃专注')
          .width('80%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#909399')
          .borderRadius(24)
          .margin({ top: 14 })
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            this.confirmCancel();
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CompletionOverlay() {
    Column() {
      Text('✓')
        .fontSize(54)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(100)
        .height(100)
        .borderRadius(50)
        .backgroundColor('#409EFF')
      Text('太棒了！专注完成！')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#409EFF')
        .margin({ top: 22 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(255, 255, 255, 0.92)')
    .onClick(() => {
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        PageHeader({ title: '专注' })
        Scroll() {
          Column() {
            Column() {
              Text('专注时刻')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
              Text(`今日已专注：${this.formatTotal(this.todayMinutes)}`)
                .fontSize(15)
                .fontColor('#666666')
                .width('100%')
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({ left: 20, right: 20, top: 20, bottom: 10 })

            this.TimerPanel()

            Column() {
              this.Controls()
            }
            .margin({ top: 36 })

            Column() {
              Text(this.currentQuote())
                .fontSize(16)
                .fontColor('#555555')
                .lineHeight(24)
                .textAlign(TextAlign.Center)
                .width('100%')
              if (this.isFocusing && !this.showCompletion) {
                Text('专注期间请勿退出或锁屏，否则计时将中断')
                  .fontSize(13)
                  .fontColor('#999999')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 24, bottom: 40 })
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F0F2F5')

      if (this.showCompletion) {
        this.CompletionOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
