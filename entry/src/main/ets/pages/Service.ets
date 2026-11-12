import { router } from '@kit.ArkUI';
import { AppIcon } from '../components/AppIcon';
import { AppColors, AppFont, AppRadius, AppSpace } from '../theme/Theme';

import { PageHeader } from '../components/common/PageHeader';

class ServiceEntry {
  id: string;
  title: string;
  description: string;
  icon: string;
  badge: string;
  route: string;

  constructor(id: string, title: string, description: string, icon: string, badge: string, route: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.icon = icon;
    this.badge = badge;
    this.route = route;
  }
}

class ServiceGroup {
  title: string;
  subtitle: string;
  items: ServiceEntry[];

  constructor(title: string, subtitle: string, items: ServiceEntry[]) {
    this.title = title;
    this.subtitle = subtitle;
    this.items = items;
  }
}

@Entry
@Component
struct Service {
  private groups: ServiceGroup[] = [
    new ServiceGroup('校园查询', '校园动态与学习数据', [
      new ServiceEntry('flow', '校园人流天气', '实时查看校园各区域人流量分布与空气质量指数。',
        'tab_service', '实时', 'pages/ServicePersonInfo'),
      new ServiceEntry('schedule', '查询课表服务', '查询当前学期课表，及时了解课程安排。',
        'learn', '可用', 'pages/ServiceSchedule'),
      new ServiceEntry('grade', '查询成绩服务', '查询当前学期成绩，了解学习情况。',
        'profile_grade', '可用', 'pages/ServiceGrade')
    ]),
    new ServiceGroup('打印快递', '文件打印与快递代取', [
      new ServiceEntry('print', '远程打印服务', '宿舍也能轻松打印，手机填写信息后提交订单。',
        'profile_publish', '¥0.2/页', 'pages/ServicePrint'),
      new ServiceEntry('express', '快递代取', '快递专人代取，填写地址与包裹信息即可下单。',
        'me_address', '¥3起', 'pages/ServiceExpress')
    ]),
    new ServiceGroup('生活服务', '地址与订单管理', [
      new ServiceEntry('order', '我的订单', '查看打印订单记录与处理状态。',
        'me_order', '查看', 'pages/MeOrder'),
      new ServiceEntry('address', '地址簿', '管理收货地址，供打印与代取订单复用。',
        'me_address', '管理', 'pages/MeAddress')
    ])
  ];

  private openService(item: ServiceEntry): void {
    if (item.route.length === 0) {
      return;
    }
    router.pushUrl({ url: item.route });
  }

  @Builder
  Header() {
    Column() {
      Text('推荐服务')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textPrimary)
        .width('100%')
      Text('校园查询、打印快递与生活服务，一站直达。')
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textSecondary)
        .width('100%')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: AppSpace.xl, right: AppSpace.xl, top: AppSpace.xxl, bottom: AppSpace.md })
  }

  @Builder
  GroupTitle(group: ServiceGroup) {
    Row() {
      Column() {
        Text(group.title)
          .fontSize(AppFont.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textPrimary)
        Text(group.subtitle)
          .fontSize(AppFont.xs)
          .fontColor(AppColors.textTertiary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${group.items.length} 项`)
        .fontSize(AppFont.xs)
        .fontColor(AppColors.textTertiary)
    }
    .width('100%')
    .padding({ top: AppSpace.lg, bottom: AppSpace.md })
  }

  @Builder
  ServiceCard(item: ServiceEntry) {
    Column() {
      Row() {
        Row() {
          AppIcon({ name: item.icon, iconSize: 30 })
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.primaryLight)
        .borderRadius(AppRadius.md)
        Text(item.badge)
          .fontSize(10)
          .fontColor(AppColors.brandBlue)
          .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          .backgroundColor('#EAF4FF')
          .borderRadius(AppRadius.pill)
          .margin({ left: 6 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(item.title)
        .fontSize(AppFont.base)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textPrimary)
        .width('100%')
        .margin({ top: AppSpace.md })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(item.description)
        .fontSize(AppFont.xs)
        .fontColor(AppColors.textSecondary)
        .lineHeight(17)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: AppSpace.xs })
    }
    .alignItems(HorizontalAlign.Start)
    .width('48%')
    .height(142)
    .padding(AppSpace.md)
    .backgroundColor(AppColors.bgCard)
    .borderRadius(AppRadius.lg)
    .margin({ bottom: AppSpace.md })
    .onClick(() => {
      this.openService(item);
    })
  }

  @Builder
  Group(group: ServiceGroup) {
    Column() {
      this.GroupTitle(group)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(group.items, (item: ServiceEntry) => {
          this.ServiceCard(item)
        }, (item: ServiceEntry) => item.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpace.page, right: AppSpace.page })
  }

  build() {
    Column() {
      PageHeader({ title: '服务' })
      Scroll() {
        Column() {
          this.Header()
          ForEach(this.groups, (group: ServiceGroup) => {
            this.Group(group)
          }, (group: ServiceGroup) => group.title)
          Text('更多服务持续接入中')
            .fontSize(AppFont.xs)
            .fontColor(AppColors.textDisabled)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: AppSpace.md, bottom: AppSpace.xxl })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.bgPage)
  }
}
