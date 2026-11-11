import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ApiConfig } from '../api/ApiConfig';
import { AppIcon } from '../components/AppIcon';
import { RemoteImage } from '../components/RemoteImage';
import { JobApi } from '../api/JobApi';
import { UserApi } from '../api/UserApi';
import { Banner } from '../models/Banner';
import { Job } from '../models/Job';
import { AuthStore } from '../stores/AuthStore';
import { MockData } from '../utils/MockData';
import { LogUtil } from '../utils/LogUtil';
import { Community } from './Community';
import { Helper } from './Helper';
import { Knowledge } from './Knowledge';
import { Mine } from './Mine';

class HomeService {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  price: string;
  rating: string;
  orders: string;
  url: string;

  constructor(id: string, title: string, description: string, imageUrl: string, price: string, rating: string, orders: string, url: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.imageUrl = imageUrl;
    this.price = price;
    this.rating = rating;
    this.orders = orders;
    this.url = url;
  }
}

class CampusNotification {
  id: string;
  typeText: string;
  tagColor: string;
  title: string;
  description: string;
  sender: string;
  time: string;
  readers: string;

  constructor(id: string, typeText: string, tagColor: string, title: string, description: string, sender: string, time: string, readers: string) {
    this.id = id;
    this.typeText = typeText;
    this.tagColor = tagColor;
    this.title = title;
    this.description = description;
    this.sender = sender;
    this.time = time;
    this.readers = readers;
  }
}

@Entry
@Component
struct Index {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State banners: Banner[] = MockData.banners();
  @State selectedIndex: number = 0;
  @State userName: string = '同学';
  @State jobs: Job[] = MockData.jobs();

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
      if (remoteJobs.length > 0) {
        this.jobs = remoteJobs;
      }
    } catch (err) {
      LogUtil.warn('home', `jobs failed ${(err as Error).message}`);
      this.jobs = MockData.jobs();
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
    return [
      new HomeService('flow', '校园人流天气', '实时查看校园各区域人流量分布与空气质量指数，助你避开拥挤，畅享清新校园生活。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAESETBpwP6ugYWtISs6XQ81KokrT4mBIgACnCQAAiLeCFbhCOwpzFtBizoE.png', '', '5.0', '4060', 'pages/ServicePersonInfo'),
      new HomeService('schedule', '查询课表服务', '查询当前学期的课表，方便你及时了解自己的课程安排。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECPRpAZAXQl3cBfhxDxuSt1AojYoeHQAC7iAAAtCQCFQvkTsfSeUnwjYE.jpg', '', '4.8', '1580', 'pages/ServiceSchedule'),
      new HomeService('grade', '查询成绩服务', '查询当前学期的成绩，方便你及时了解自己的学习情况。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECP5pAZDT2lKDbMs1BC1kkTo76bcj3AAC-CAAAtCQCFQGU12qYNcw8DYE.jpg', '', '4.8', '1580', 'pages/ServiceGrade'),
      new HomeService('print', '远程打印服务', '宿舍也能轻松打印！手机一键上传，即刻获取文件。', 'https://api.hcyj.xyz/images/dnfw.png', '¥0.2/页', '4.9', '2350', 'pages/ServicePrint'),
      new HomeService('more', '更多服务', '更多精彩服务即将上线！我们正在精心准备更多便捷实用的校园服务。', 'https://api.hcyj.xyz/images/gdfw.jpg', '???¥', '5.0', '5000', '')
    ];
  }

  private notifications(): CampusNotification[] {
    return [
      new CampusNotification('n1', '重要', '#ff4d4f', '关于2025年春季学期期末考试安排的通知', '各位同学，2025年春季学期期末考试将于6月15日至6月25日进行，请查看具体安排并做好准备。', '教务处', '2小时前', '1253'),
      new CampusNotification('n2', '活动', '#1890ff', '校园才艺大赛报名开始', '第十二届校园才艺大赛现已开始报名，欢迎各位同学积极参与，展示你的才华！', '学生会', '4小时前', '865'),
      new CampusNotification('n3', '讲座', '#722ed1', '人工智能与未来职业发展讲座', '著名AI研究员张教授将于下周三在主教学楼进行讲座，探讨AI如何改变未来就业格局。', '计算机学院', '昨天', '743'),
      new CampusNotification('n4', '通知', '#faad14', '图书馆开放时间调整', '因维修工程，图书馆自5月1日起将调整开放时间，周一至周五8:00-21:00，周末9:00-18:00。', '图书馆', '昨天', '1028'),
      new CampusNotification('n5', '奖学金', '#52c41a', '2025年国家奖学金申请开始', '2025年国家奖学金申请已开始，请符合条件的同学于5月15日前提交申请材料。', '学生处', '2天前', '1536'),
      new CampusNotification('n6', '就业', '#fa8c16', '腾讯2025校园招聘宣讲会', '腾讯公司将于5月10日在主会场举办校园招聘宣讲会，欢迎应届毕业生参加。', '就业指导中心', '3天前', '1892')
    ];
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
    if (service.url.length === 0) {
      return;
    }
    router.pushUrl({ url: service.url });
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
            RemoteImage({
              imageUrl: item.imageUrl,
              imageHeight: 178,
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
                .fontColor('#F2F4F7')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(15)
            .backgroundColor('#88000000')
          }
          .width('100%')
          .height('100%')
          .borderRadius(16)
          .clip(true)
        }, (item: Banner) => item.id)
      }
      .autoPlay(true)
      .loop(true)
      .indicator(true)
      .height(178)
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
                RemoteImage({
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
            .backgroundColor('#1890ff')
            .borderRadius(3)
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
            this.selectedIndex = 1;
            router.pushUrl({ url: 'pages/JobList' });
          })
      }
      .width('100%')
      .margin({ bottom: 14 })

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
