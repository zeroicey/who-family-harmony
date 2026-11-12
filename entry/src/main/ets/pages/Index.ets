import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ApiConfig } from '../api/ApiConfig';
import { AppIcon } from '../components/AppIcon';
import { NetImage } from '../components/common/NetImage';
import { JobApi } from '../api/JobApi';
import { UserApi } from '../api/UserApi';
import { Banner } from '../models/Banner';
import { Job } from '../models/Job';
import { AuthStore } from '../stores/AuthStore';
import { MockData } from '../utils/MockData';
import { CampusNotification, HomeService } from '../models/MockModels';
import { LogUtil } from '../utils/LogUtil';
import { Community } from './Community';
import { Helper } from './Helper';
import { Knowledge } from './Knowledge';
import { Mine } from './Mine';

@Entry
@Component
struct Index {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State banners: Banner[] = MockData.banners();
  @State selectedIndex: number = 0;
  @State userName: string = '同学';
  @State jobs: Job[] = [];
  @State jobsLoading: boolean = true;

  async aboutToAppear(): Promise<void> {
    await AuthStore.isLogin(this.context);
    await this.loadHomeData();
  }

  async loadHomeData(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      const user = await UserApi.getUserInfo(token, ApiConfig.DEMO_USER_ID, apiEnvironment);
      this.userName = user.nickname.length > 0 ? user.nickname : '同学';
      await AuthStore.saveUser(this.context, user);
    } catch (err) {
      LogUtil.warn('home', `user info failed ${(err as Error).message}`);
      const cachedUser = await AuthStore.getUser(this.context);
      this.userName = cachedUser.nickname.length > 0 ? cachedUser.nickname : '同学';
    }

    try {
      const remoteJobs = await JobApi.recommend(token, apiEnvironment);
      this.jobs = remoteJobs.length > 0 ? remoteJobs : MockData.jobs();
    } catch (err) {
      LogUtil.warn('home', `jobs failed ${(err as Error).message}`);
      this.jobs = MockData.jobs();
    } finally {
      this.jobsLoading = false;
    }
  }

  private greeting(): string {
    const hour = new Date().getHours();
    if (hour < 6) {
      return '凌晨好';
    }
    if (hour < 9) {
      return '早上好';
    }
    if (hour < 12) {
      return '上午好';
    }
    if (hour < 14) {
      return '中午好';
    }
    if (hour < 18) {
      return '下午好';
    }
    if (hour < 22) {
      return '晚上好';
    }
    return '夜深了';
  }

  private dateText(): string {
    const date = new Date();
    const weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return `${date.getMonth() + 1}.${date.getDate()} · 星期${weekDays[date.getDay()]}`;
  }

  private services(): HomeService[] {
    return MockData.homeServices();
  }

  private notifications(): CampusNotification[] {
    return MockData.campusNotifications();
  }

  private bannerData(): Banner[] {
    return [
      new Banner('1', '校园社区动态', 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=800&auto=format&fit=crop', '了解最新校园活动与社区资讯'),
      new Banner('2', '社团活动招新', 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=800&auto=format&fit=crop', '丰富多彩的社团等你加入'),
      new Banner('3', '校园互助服务', 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=800&auto=format&fit=crop', '便捷的校园生活服务平台'),
      new Banner('4', '学习资源共享', 'https://images.unsplash.com/photo-1600267175161-cfaa711b4a81?q=80&w=2070&auto=format&fit=crop', '优质学习资源一站获取')
    ];
  }

  openService(service: HomeService): void {
    if (service.route.length === 0) {
      return;
    }
    router.pushUrl({ url: service.route });
  }

  openJob(job: Job): void {
    router.pushUrl({
      url: 'pages/JobDetail',
      params: { id: job.id }
    });
  }

  @Builder tabBar(icon: string, title: string, index: number) {
    Column() {
      AppIcon({ name: icon, iconSize: 24 })
        .opacity(this.selectedIndex === index ? 1 : 0.55)
      Text(title)
        .fontSize(12)
        .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.selectedIndex === index ? '#07c160' : '#999999')
        .margin({ top: 2 })
    }
    .height(58)
    .justifyContent(FlexAlign.Center)
  }

  @Builder HomeHeader() {
    Column() {
      Row() {
        Row() {
          Text(`${this.greeting()}，`)
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(this.userName)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#07c160')
        }
        .layoutWeight(1)

        Text(this.dateText())
          .fontSize(12)
          .fontColor('#666666')
          .padding({ left: 11, right: 11, top: 5, bottom: 5 })
          .backgroundColor('#f5f5f5')
          .borderRadius(16)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 16 })

      Swiper() {
        ForEach(this.bannerData(), (item: Banner) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            NetImage({
              imageUrl: item.imageUrl,
              imageHeight: 169,
              imageRadius: 0,
              fitMode: 'cover'
            })
              .width('100%')

            Column() {
              Text(item.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(item.summary)
                .fontSize(12)
                .fontColor('rgba(255, 255, 255, 0.9)')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(15)
            .linearGradient({
              angle: 180,
              colors: [['#B3000000', 0.0], ['#00000000', 1.0]]
            })
          }
          .width('100%')
          .height('100%')
          .borderRadius(16)
          .clip(true)
        }, (item: Banner) => item.id)
      }
      .autoPlay(true)
      .loop(true)
      .interval(3000)
      .duration(500)
      .indicator(true)
      .indicatorStyle({ color: 'rgba(255, 255, 255, 0.5)', selectedColor: '#FFFFFF' })
      .height(169)
      .borderRadius(16)
      .margin({ left: 20, right: 20, bottom: 16 })
    }
    .width('100%')
  }

  @Builder ServiceRecommend() {
    Column() {
      Row() {
        Text('推荐服务')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('超多服务等你来！')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 12 })

      Scroll() {
        Row() {
          ForEach(this.services(), (item: HomeService) => {
            Column() {
              Stack({ alignContent: Alignment.TopEnd }) {
                NetImage({
                  imageUrl: item.imageUrl,
                  imageHeight: 142,
                  imageRadius: 0,
                  fitMode: 'cover'
                })
                  .width('100%')

                if (item.price.length > 0) {
                  Text(item.price)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                    .backgroundColor('#ff4d4f')
                    .borderRadius({ topLeft: 16, bottomLeft: 16 })
                    .margin({ top: 12 })
                }
              }
              .width('100%')
              .height(142)

              Column() {
                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.description)
                  .fontSize(12)
                  .fontColor('#666666')
                  .lineHeight(17)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 8 })
                Row() {
                  Text(item.rating)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#fa8c16')
                    .margin({ right: 6 })
                  Text('★★★★★')
                    .fontSize(11)
                    .fontColor('#fa8c16')
                    .layoutWeight(1)
                  Text(`${item.orders}人已预约`)
                    .fontSize(11)
                    .fontColor('#999999')
                }
                .width('100%')
                .margin({ top: 9 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(15)
            }
            .width(268)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .clip(true)
            .shadow({ radius: 15, color: '#14000000', offsetX: 0, offsetY: 3 })
            .margin({ right: 16, bottom: 8 })
            .onClick(() => {
              this.openService(item);
            })
          }, (item: HomeService) => item.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .padding({ left: 20 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder CampusNotifications() {
    Column() {
      Row() {
        Text('校园动态')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text(`${this.notifications().length}条新动态`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 11 })

      Scroll() {
        Column() {
          ForEach(this.notifications(), (item: CampusNotification) => {
            Row() {
              Text(item.typeText)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .padding({ left: 9, right: 9, top: 4, bottom: 4 })
                .backgroundColor(item.tagColor)
                .borderRadius(3)
                .margin({ right: 12 })

              Column() {
                Text(item.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.description)
                  .fontSize(12)
                  .fontColor('#666666')
                  .lineHeight(17)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
                Row() {
                  Text(`发布人：${item.sender}`)
                    .fontSize(11)
                    .fontColor('#666666')
                    .layoutWeight(1)
                  Text(item.time)
                    .fontSize(11)
                    .fontColor('#999999')
                    .margin({ right: 8 })
                  Text(`${item.readers}人已读`)
                    .fontSize(11)
                    .fontColor('#999999')
                }
                .width('100%')
                .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 11, bottom: 11 })
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })
          }, (item: CampusNotification) => item.id)
        }
      }
      .height(244)
      .scrollBar(BarState.Off)
    }
    .alignItems(HorizontalAlign.Start)
    .width('auto')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .margin({ left: 20, right: 20, top: 12 })
  }

  @Builder RecruitmentCard() {
    Column() {
      Row() {
        Row() {
          Text('')
            .width(4)
            .height(20)
            .borderRadius(2)
            .linearGradient({
              angle: 180,
              colors: [['#1890ff', 0.0], ['#36a6ff', 1.0]]
            })
            .margin({ right: 10 })
          Text('近期招聘')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .layoutWeight(1)
        Text('查看更多')
          .fontSize(12)
          .fontColor('#1890ff')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#141890ff')
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/JobList' });
          })
      }
      .width('100%')
      .margin({ bottom: 14 })

      if (this.jobsLoading && this.jobs.length === 0) {
        Column() {
          LoadingProgress()
            .width(22)
            .height(22)
            .color('#1890ff')
          Text('正在加载...')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 22, bottom: 22 })
        .alignItems(HorizontalAlign.Center)
      } else if (this.jobs.length === 0) {
        Column() {
          Text('暂无招聘信息')
            .fontSize(13)
            .fontColor('#aaaaaa')
        }
        .width('100%')
        .padding({ top: 38, bottom: 38 })
        .alignItems(HorizontalAlign.Center)
      }

      ForEach(this.jobs.slice(0, 5), (item: Job) => {
        Row() {
          Column() {
            Text(item.title)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Text(item.tags.length > 0 ? item.tags[0] : '招聘')
                .fontSize(11)
                .fontColor('#1890ff')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#e6f7ff')
                .borderRadius(12)
                .margin({ right: 10 })
              Text(item.organization)
                .fontSize(11)
                .fontColor('#666666')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#f5f7fa')
                .borderRadius(12)
              if (item.endTime.length > 0) {
                Text(`截止: ${item.endTime}`)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#fa8c16')
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .margin({ top: 9 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('›')
            .fontSize(24)
            .fontColor('#bfbfbf')
            .width(26)
            .height(26)
            .textAlign(TextAlign.Center)
            .backgroundColor('#f5f7fa')
            .borderRadius(13)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 9, bottom: 9 })
        .border({ width: { bottom: 1 }, color: '#f0f0f0', style: BorderStyle.Dashed })
        .onClick(() => {
          this.openJob(item);
        })
      }, (item: Job) => item.id)
    }
    .alignItems(HorizontalAlign.Start)
    .width('auto')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0F000000', offsetX: 0, offsetY: 4 })
    .margin({ left: 20, right: 20, top: 18, bottom: 16 })
  }

  @Builder HomePage() {
    Scroll() {
      Column() {
        this.HomeHeader()
        this.ServiceRecommend()
        this.CampusNotifications()
        this.RecruitmentCard()
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f7f8fa')
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex }) {
      TabContent() {
        this.HomePage()
      }
      .tabBar(this.tabBar('tab_home', '首页', 0))

      TabContent() {
        Community()
      }
      .tabBar(this.tabBar('tab_community', '社区', 1))

      TabContent() {
        Helper()
      }
      .tabBar(this.tabBar('tab_helper', '助手', 2))

      TabContent() {
        Knowledge()
      }
      .tabBar(this.tabBar('tab_knowledge', '知识', 3))

      TabContent() {
        Mine()
      }
      .tabBar(this.tabBar('tab_me', '我的', 4))
    }
    .width('100%')
    .height('100%')
    .barHeight(58)
    .barBackgroundColor('#FFFFFF')
    .onChange((index: number) => {
      this.selectedIndex = index;
    })
  }
}
