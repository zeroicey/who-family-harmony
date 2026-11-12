import { router } from '@kit.ArkUI';
import { AppColors, AppFont, AppSize, AppSpace } from '../../theme/Theme';

/**
 * 统一子页导航栏：返回 + 标题 + 右侧操作。
 *
 * 用法：
 *   PageHeader({ title: '岗位详情' })
 *   PageHeader({ title: '发布动态', showBack: true }) { ...自定义右侧... }
 *
 * 说明：当前窗口未开启全屏布局，系统状态栏位于应用内容区之外，
 * 因此默认不再重复计算状态栏高度；如后续开启沉浸式，可通过 topInset 传入。
 */
@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  @Prop headerBackground: string = AppColors.bgCard;
  @Prop titleColor: string = AppColors.textPrimary;
  @Prop borderBottom: boolean = true;
  @Prop topInset: number = 0;
  onBack: () => void = () => {
    if (Number(router.getLength()) > 1) {
      router.back();
    } else {
      router.replaceUrl({ url: 'pages/Index' });
    }
  };
  @BuilderParam trailing: () => void = this.emptyTrailing;

  @Builder
  emptyTrailing() {
  }

  build() {
    Column() {
      Row() {
        Row() {
          if (this.showBack) {
            Text('‹')
              .fontSize(30)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
              .textAlign(TextAlign.Center)
              .width(44)
              .height(44)
              .onClick(() => {
                this.onBack();
              })
          }
        }
        .width(44)
        .justifyContent(FlexAlign.Start)

        Text(this.title)
          .fontSize(AppFont.lg)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Row() {
          this.trailing()
        }
        .width(44)
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .height(AppSize.headerHeight)
      .padding({ left: AppSpace.sm, right: AppSpace.sm })
    }
    .width('100%')
    .padding({ top: this.topInset })
    .backgroundColor(this.headerBackground)
    .border({
      width: { bottom: this.borderBottom ? 0.5 : 0 },
      color: { bottom: AppColors.border }
    })
  }
}