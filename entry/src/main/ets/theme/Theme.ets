/**
 * 设计 token：与微信小程序版（../who_family_wechat）的 uni.scss 与页面样式保持一致。
 *
 * 使用方式：
 *   import { AppColors, AppFont, AppSpace, AppRadius, AppShadow } from '../theme/Theme';
 *   Text('标题').fontSize(AppFont.lg).fontColor(AppColors.textPrimary)
 *
 * 约束：新增页面/组件不要再写颜色、字号、间距魔法值，统一从这里取。
 */
export class AppColors {
  // 品牌色（小程序：绿色主色 tabBar / #07c160，蓝色辅助 #007aff）
  static readonly primary: string = '#07C160';
  static readonly primaryDark: string = '#06AD56';
  static readonly primaryLight: string = '#E9F8F0';
  static readonly brandBlue: string = '#007AFF';
  static readonly brandTeal: string = '#0A7D6C';
  static readonly brandOrange: string = '#FF8A00';

  // 语义色
  static readonly success: string = '#4CD964';
  static readonly warning: string = '#F0AD4E';
  static readonly error: string = '#DD524D';
  static readonly danger: string = '#FF4D4F';

  // 文字（小程序：基本 #333 / 辅助 #999 / 占位 #808080 / 禁用 #c0c0c0）
  static readonly textPrimary: string = '#333333';
  static readonly textTitle: string = '#2C405A';
  static readonly textSecondary: string = '#666666';
  static readonly textTertiary: string = '#999999';
  static readonly textPlaceholder: string = '#808080';
  static readonly textDisabled: string = '#C0C0C0';
  static readonly textInverse: string = '#FFFFFF';

  // 背景（小程序：白卡片、#f8f8f8 页面底色、#f1f1f1 按压态）
  static readonly bgPage: string = '#F8F8F8';
  static readonly bgCard: string = '#FFFFFF';
  static readonly bgHover: string = '#F1F1F1';
  static readonly bgDisabled: string = '#F2F3F5';
  static readonly bgMask: string = 'rgba(0, 0, 0, 0.4)';
  static readonly bgPlaceholder: string = '#F5F5F5';

  // 分割线/边框（小程序 #c8c7cc，页面内常见浅灰 #eee）
  static readonly border: string = '#E5E6EB';
  static readonly borderStrong: string = '#C8C7CC';
  static readonly divider: string = '#F0F0F0';

  // 深色底（弹层/遮罩文字）
  static readonly overlayDark: string = 'rgba(0, 0, 0, 0.66)';
  static readonly overlayLight: string = 'rgba(0, 0, 0, 0.06)';
}

export class AppFont {
  static readonly xxs: number = 10;
  static readonly xs: number = 11;
  static readonly sm: number = 12;
  static readonly base: number = 14;
  static readonly md: number = 15;
  static readonly lg: number = 16;
  static readonly xl: number = 18;
  static readonly title: number = 20;
  static readonly hero: number = 24;

  static readonly lineTight: number = 18;
  static readonly lineBase: number = 22;
  static readonly lineLoose: number = 26;
}

/** 8pt 栅格附近的常用间距；页面左右边距用 page。 */
export class AppSpace {
  static readonly xxs: number = 2;
  static readonly xs: number = 4;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly lg: number = 16;
  static readonly xl: number = 20;
  static readonly xxl: number = 24;
  /** 小程序 rpx 30 ≈ 15px，页面统一 16px */
  static readonly page: number = 16;
}

export class AppRadius {
  static readonly xs: number = 4;
  static readonly sm: number = 6;
  static readonly md: number = 10;
  static readonly lg: number = 12;
  static readonly xl: number = 16;
  static readonly pill: number = 999;
}

export class AppShadow {
  /** 卡片默认阴影（小程序卡片风格接近无阴影，仅轻微层次） */
  static readonly card: ShadowOptions = {
    radius: 12,
    color: 'rgba(16, 24, 40, 0.06)',
    offsetX: 0,
    offsetY: 2
  };

  static readonly floating: ShadowOptions = {
    radius: 16,
    color: 'rgba(16, 24, 40, 0.12)',
    offsetX: 0,
    offsetY: 4
  };

  static readonly none: ShadowOptions = {
    radius: 0,
    color: 'rgba(0, 0, 0, 0)',
    offsetX: 0,
    offsetY: 0
  };
}

export class AppSize {
  /** 底部 tabBar 视觉高度（不含系统手势区，页面底部内容需预留） */
  static readonly tabBarHeight: number = 56;
  static readonly headerHeight: number = 48;
  static readonly touchTarget: number = 44;
  static readonly avatarSm: number = 32;
  static readonly avatarMd: number = 40;
  static readonly avatarLg: number = 64;
}

/** 常用组件尺寸。 */
export class AppTheme {
  static readonly buttonHeight: number = 44;
  static readonly inputHeight: number = 44;
  static readonly cardPadding: number = AppSpace.lg;
  static readonly pagePadding: number = AppSpace.page;
}