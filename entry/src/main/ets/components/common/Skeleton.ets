import { AppColors, AppRadius, AppSpace } from '../../theme/Theme';

/**
 * 骨架屏：内容加载前的占位，呼吸动画。
 */
@Component
export struct Skeleton {
  @Prop rows: number = 3;
  @Prop showAvatar: boolean = false;
  @Prop showTitle: boolean = true;
  @Prop gap: number = AppSpace.md;
  @State private pulse: number = 1;

  aboutToAppear(): void {
    animateTo({
      duration: 900,
      iterations: -1,
      curve: Curve.EaseInOut,
      playMode: PlayMode.Alternate
    }, () => {
      this.pulse = 0.45;
    });
  }

  private rowItems(): number[] {
    const list: number[] = [];
    for (let i = 0; i < this.rows; i++) {
      list.push(i);
    }
    return list;
  }

  @Builder
  Block(widthValue: Length, heightValue: number) {
    Row()
      .width(widthValue)
      .height(heightValue)
      .borderRadius(AppRadius.xs)
      .backgroundColor(AppColors.bgHover)
  }

  build() {
    Column() {
      if (this.showAvatar) {
        Row() {
          this.Block(44, 44)
          Column() {
            this.Block('60%', 14)
            this.Block('40%', 12)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: AppSpace.md })
        }
        .width('100%')
        .margin({ bottom: this.gap })
      }
      if (this.showTitle) {
        this.Block('50%', 18)
      }
      ForEach(this.rowItems(), (item: number) => {
        this.Block(item === this.rows - 1 ? '70%' : '100%', 12)
      }, (item: number) => item.toString())
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppSpace.lg)
    .borderRadius(AppRadius.lg)
    .backgroundColor(AppColors.bgCard)
    .opacity(this.pulse)
  }
}