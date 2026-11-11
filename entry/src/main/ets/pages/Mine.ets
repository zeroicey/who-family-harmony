import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ApiConfig } from '../api/ApiConfig';
import { CommunityApi } from '../api/CommunityApi';
import { FocusApi } from '../api/FocusApi';
import { TaskApi } from '../api/TaskApi';
import { UserApi } from '../api/UserApi';
import { AppIcon } from '../components/AppIcon';
import { NetImage } from '../components/common/NetImage';
import { CommunityPost } from '../models/CommunityPost';
import { StudyTask } from '../models/Task';
import { UserProfile } from '../models/UserProfile';
import { AuthStore } from '../stores/AuthStore';
import { LogUtil } from '../utils/LogUtil';

@Entry
@Component
export struct Mine {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State user: UserProfile = new UserProfile('用户', ApiConfig.DEMO_USER_ID);
  @State avatarUrl: string = '';
  @State posts: CommunityPost[] = [];
  @State todoCount: number = 0;
  @State doneCount: number = 0;
  @State todayFocusMinutes: number = 0;

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);

    try {
      const remoteUser = await UserApi.getUserInfo(token, ApiConfig.DEMO_USER_ID, apiEnvironment);
      const remoteAvatar = await UserApi.getAvatarUrl(token, remoteUser.avaterId, apiEnvironment);
      remoteUser.avatarUrl = remoteAvatar;
      this.user = remoteUser;
      this.avatarUrl = remoteAvatar;
      await AuthStore.saveUser(this.context, remoteUser);
    } catch (err) {
      LogUtil.warn('mine', `user info failed ${(err as Error).message}`);
      this.user = await AuthStore.getUser(this.context);
      this.avatarUrl = this.user.avatarUrl;
    }

    try {
      this.posts = await CommunityApi.selfPosts(token, apiEnvironment);
    } catch (err) {
      LogUtil.warn('mine', `self posts failed ${(err as Error).message}`);
      this.posts = [];
    }

    try {
      const tasks = await TaskApi.list(token, apiEnvironment);
      this.todoCount = tasks.filter((task: StudyTask) => task.status !== '已完成').length;
      this.doneCount = tasks.length - this.todoCount;
    } catch (err) {
      LogUtil.warn('mine', `tasks failed ${(err as Error).message}`);
      this.todoCount = 0;
      this.doneCount = 0;
    }

    try {
      this.todayFocusMinutes = await FocusApi.today(token, apiEnvironment);
    } catch (err) {
      LogUtil.warn('mine', `focus failed ${(err as Error).message}`);
      this.todayFocusMinutes = 0;
    }
  }

  private displayName(): string {
    return this.user.nickname.length > 0 ? this.user.nickname : '用户';
  }

  private bioText(): string {
    if (this.user.bio.length === 0) {
      return '这个用户很懒，还没有填写简介哦~';
    }
    if (this.user.bio.length > 20) {
      return `${this.user.bio.substring(0, 20)}...`;
    }
    return this.user.bio;
  }

  private userBrand(): string {
    const brandTitles: string[] = [
      '卷王', '躺平王', '摸鱼大师', '早八人', '夜猫子', '复习达人',
      '课表杀手', 'DDL战士', '食堂VIP', '图书馆常驻', '运动健将',
      '社团大佬', '宿舍躺王', '外卖达人', '校园百事通', '社交恐怖',
      '萌新', '老油条', '传说', '工具人', '水课王', '干饭人',
      '摸鱼专业户', '起床困难户', '拖延症晚期', '复习困难户'
    ];
    let seed = 0;
    const name = this.displayName();
    for (let index = 0; index < name.length; index++) {
      seed += name.charCodeAt(index);
    }
    return brandTitles[seed % brandTitles.length];
  }

  private todoProgress(): number {
    const total = this.todoCount + this.doneCount;
    if (total === 0) {
      return 0;
    }
    return Math.round((this.doneCount / total) * 100);
  }

  private todoProgressWidth(): string {
    return `${this.todoProgress()}%`;
  }

  private focusText(): string {
    const hours = Math.floor(this.todayFocusMinutes / 60);
    const minutes = this.todayFocusMinutes % 60;
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`;
    }
    return `${minutes}分钟`;
  }

  private motivationalText(): string {
    const quotes: string[] = ['专注成就未来', '心无旁骛行', '深思促成长', '不负好时光', '专注最珍贵', '每分钟都值', '专注超自我', '静心厚积发'];
    return quotes[new Date().getHours() % quotes.length];
  }

  private firstAvatarText(): string {
    const name = this.displayName();
    return name.length > 0 ? name.substring(0, 1) : '用';
  }

  private firstPostImage(post: CommunityPost): string {
    if (post.imgList && post.imgList.length > 0) {
      return post.imgList[0];
    }
    return post.imageUrl;
  }

  openPage(url: string): void {
    router.pushUrl({ url: url });
  }

  openPost(post: CommunityPost): void {
    router.pushUrl({
      url: 'pages/CommunityDetail',
      params: { id: post.id }
    });
  }

  @Builder SchoolInfoRow(icon: string, label: string, value: string) {
    Row() {
      AppIcon({ name: icon, iconSize: 24 })
        .margin({ right: 12 })
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#07c160')
        .width(42)
      Text(value.length > 0 ? value : '未填写')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2c3e50')
        .layoutWeight(1)
    }
    .width('100%')
    .height(42)
    .border({ width: { bottom: 1 }, color: '#2607c160', style: BorderStyle.Dashed })
  }

  @Builder UserProfileCard() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Bottom }) {
          Stack({ alignContent: Alignment.TopStart }) {
            if (this.avatarUrl.length > 0) {
              NetImage({
                imageUrl: this.avatarUrl,
                imageHeight: 64,
                imageRadius: 32,
                fitMode: 'cover'
              })
                .width(64)
                .border({ width: 2, color: '#e8f7ef' })
            } else {
              Text(this.firstAvatarText())
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#07c160')
                .width(64)
                .height(64)
                .textAlign(TextAlign.Center)
                .backgroundColor('#FFFFFF')
                .borderRadius(32)
                .border({ width: 2, color: '#e8f7ef' })
            }

            Text(`Lv.${this.user.level}`)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
              .backgroundColor('#ff9500')
              .borderRadius(10)
              .border({ width: 1, color: '#FFFFFF' })
          }
          .width(70)
          .height(70)

          Text(this.userBrand())
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#ff9a56')
            .borderRadius(4)
            .margin({ bottom: -2 })
        }
        .width(74)
        .height(78)
        .margin({ right: 12 })

        Column() {
          Text(this.displayName())
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.bioText())
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F6FFFA')
            .lineHeight(20)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        AppIcon({ name: 'profile_publish', iconSize: 25 })
          .width(34)
          .height(34)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 16 })
      .backgroundColor('#07c160')
      .onClick(() => {
        this.openPage('pages/MeProfile');
      })

      Column() {
        this.SchoolInfoRow('profile_school', '学校:', this.user.school)
        this.SchoolInfoRow('profile_major', '专业:', this.user.major)
        this.SchoolInfoRow('profile_grade', '年级:', this.user.grade)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 8 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 12, topRight: 12 })
    .clip(true)
    .margin({ left: 12, right: 12, top: 12 })
  }

  @Builder QuickNavItem(icon: string, text: string, url: string) {
    Column() {
      AppIcon({ name: icon, iconSize: 32 })
        .margin({ bottom: 6 })
      Text(text)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('20%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (url.length > 0) {
        this.openPage(url);
      }
    })
  }

  @Builder QuickNav() {
    Row() {
      this.QuickNavItem('me_order', '订单', 'pages/MeOrder')
      this.QuickNavItem('me_address', '地址', 'pages/MeAddress')
      this.QuickNavItem('me_message', '消息', '')
      this.QuickNavItem('me_about', '关于', 'pages/MeAbout')
      this.QuickNavItem('me_feedback', '反馈', 'pages/MeFeedback')
    }
    .width('100%')
    .height(82)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor('#FFFFFF')
    .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    .border({ width: { top: 1 }, color: '#1A5B0F03', style: BorderStyle.Dashed })
    .shadow({ radius: 5, color: '#0D000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 12, right: 12 })
  }

  @Builder CoreFunctions() {
    Row() {
      Column() {
        Row() {
          AppIcon({ name: 'me_task', iconSize: 40 })
            .margin({ right: 12 })
          Column() {
            Text('任务待办')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(`${this.todoCount} 项未完成`)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Stack({ alignContent: Alignment.Start }) {
            Text('')
              .width('100%')
              .height(8)
              .backgroundColor('#f5f5f5')
              .borderRadius(4)
            Text('')
              .width(this.todoProgressWidth())
              .height(8)
              .backgroundColor('#1890ff')
              .borderRadius(4)
          }
          .layoutWeight(1)
          .height(8)
          .margin({ right: 10 })

          Text('完成进度')
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding(15)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 15, color: '#14000000', offsetX: 0, offsetY: 3 })
      .onClick(() => {
        this.openPage('pages/TaskPage');
      })

      Blank()
        .width(10)

      Row() {
        AppIcon({ name: 'me_focus', iconSize: 40 })
          .margin({ right: 12 })
        Column() {
          Text('专注时刻')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(`今日专注 ${this.focusText()}`)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 6 })
          Text(this.motivationalText())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1890ff')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .layoutWeight(1)
      .padding(15)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 15, color: '#14000000', offsetX: 0, offsetY: 3 })
      .onClick(() => {
        this.openPage('pages/FocusPage');
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .margin({ top: 12, bottom: 8 })
  }

  @Builder MyPostCard(post: CommunityPost) {
    Column() {
      Row() {
        Text(post.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Row() {
          AppIcon({ name: 'community_view', iconSize: 13 })
            .opacity(0.65)
          Text(`${post.viewCount === 0 ? 88 : post.viewCount}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 3 })
          AppIcon({ name: post.isLike === 1 ? 'community_liked' : 'community_like', iconSize: 13 })
            .margin({ left: 8 })
          Text(`${post.likeCount}`)
            .fontSize(12)
            .fontColor(post.isLike === 1 ? '#ff6b6b' : '#999999')
            .margin({ left: 3 })
          AppIcon({ name: 'community_comment', iconSize: 13 })
            .margin({ left: 8 })
            .opacity(0.7)
          Text(`${post.commentCount}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 3 })
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('#f5f5f5')
        .borderRadius(16)
      }
      .width('100%')

      Text(post.content)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 12 })
        .width('100%')

      if (this.firstPostImage(post).length > 0) {
        NetImage({
          imageUrl: this.firstPostImage(post),
          imageHeight: 200,
          imageRadius: 6,
          fitMode: 'cover'
        })
          .width(200)
          .margin({ top: 10 })
      }

      Row() {
        Text(post.publishTime)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
        AppIcon({ name: 'community_trash', iconSize: 16 })
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: '#f0f0f0' })
      .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      this.openPost(post);
    })
  }

  build() {
    Scroll() {
      Column() {
        this.UserProfileCard()
        this.QuickNav()
        this.CoreFunctions()

        Column() {
          ForEach(this.posts, (post: CommunityPost) => {
            this.MyPostCard(post)
          }, (post: CommunityPost) => post.id)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 2 })
      }
      .width('100%')
      .padding({ top: 4, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
