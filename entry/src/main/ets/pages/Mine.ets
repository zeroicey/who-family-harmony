import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ApiConfig } from '../api/ApiConfig';
import { CommunityApi } from '../api/CommunityApi';
import { FocusApi } from '../api/FocusApi';
import { TaskApi } from '../api/TaskApi';
import { UserApi } from '../api/UserApi';
import { AppIcon } from '../components/AppIcon';
import { BackToTop } from '../components/common/BackToTop';
import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { EmptyState } from '../components/common/EmptyState';
import { NetImage } from '../components/common/NetImage';
import { SectionCard } from '../components/common/SectionCard';
import { Skeleton } from '../components/common/Skeleton';
import { CommunityPost } from '../models/CommunityPost';
import { StudyTask } from '../models/Task';
import { UserProfile } from '../models/UserProfile';
import { PageResult, PagedListController, ScrollToTop } from '../services/PagedList';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
export struct Mine {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State user: UserProfile = new UserProfile('用户', ApiConfig.DEMO_USER_ID);
  @StorageLink('avatarUrl') avatarUrl: string = '';
  @StorageLink('userRefreshAt') @Watch('onUserRefresh') userRefreshAt: string = '';
  @State posts: CommunityPost[] = [];
  @State todoCount: number = 0;
  @State doneCount: number = 0;
  @State todayFocusMinutes: number = 0;
  @State loadingPosts: boolean = true;
  @State postFooterText: string = '';
  @State refreshing: boolean = false;
  @State showBackToTop: boolean = false;
  @State previewUrl: string = '';
  private pendingDeleteId: string = '';
  private deleteDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '确认删除',
      message: '确定要删除这条动态吗？删除后无法恢复。',
      confirmText: '删除',
      confirmColor: '#FF4757',
      onConfirm: () => {
        this.deletePendingPost();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });
  private scroller: Scroller = new Scroller();
  private postPager: PagedListController<CommunityPost> =
    new PagedListController<CommunityPost>((cursor: string) => this.loadSelfPostPage(cursor));

  aboutToAppear(): void {
    this.refresh();
  }

  /** 资料/头像保存后由 MeProfile 触发，重新拉取用户信息。 */
  onUserRefresh(): void {
    if (this.userRefreshAt.length > 0) {
      this.refresh();
    }
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

    await this.loadFirstPosts();

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
      const minutes = await FocusApi.today(token, apiEnvironment);
      this.todayFocusMinutes = Number.isNaN(minutes) ? 0 : minutes;
    } catch (err) {
      LogUtil.warn('mine', `focus failed ${(err as Error).message}`);
      this.todayFocusMinutes = 0;
    }
  }

  private async loadSelfPostPage(cursor: string): Promise<PageResult<CommunityPost>> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      const posts = await CommunityApi.selfPosts(token, apiEnvironment, cursor);
      const nextCursor = posts.length > 0 ? posts[posts.length - 1].id : '';
      const repeated = cursor.length > 0 && nextCursor === cursor;
      const hasMore = posts.length >= 20 && !repeated;
      if (cursor.length === 0) {
        await CacheStore.setJson<CommunityPost[]>(this.context, 'myPosts', posts);
      }
      return new PageResult<CommunityPost>(posts, hasMore ? nextCursor : '', hasMore);
    } catch (err) {
      LogUtil.warn('mine', `self posts failed cursor=${cursor} ${(err as Error).message}`);
      if (cursor.length > 0) {
        throw new Error('加载更多失败，请重试');
      }
      const cached = await CacheStore.getJson<CommunityPost[]>(this.context, 'myPosts', []);
      return new PageResult<CommunityPost>(cached, '', false);
    }
  }

  private syncPostPagerState(): void {
    this.posts = this.postPager.items;
    this.postFooterText = this.postPager.footerText();
  }

  async loadFirstPosts(): Promise<void> {
    this.loadingPosts = true;
    await this.postPager.refresh();
    this.syncPostPagerState();
    this.loadingPosts = false;
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await this.refresh();
      this.showBackToTop = false;
    } catch (err) {
      LogUtil.warn('mine', `refresh failed ${(err as Error).message}`);
    } finally {
      this.syncPostPagerState();
      this.refreshing = false;
    }
  }

  async loadMorePosts(): Promise<void> {
    this.postFooterText = '加载中...';
    await this.postPager.loadMore();
    this.syncPostPagerState();
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
    const quotes: string[] = ['专注成就未来', '心无旁骛行', '深思促成长', '不负好时光', '专注最珍贵',
      '每分钟都值', '专注超自我', '静心厚积发', '专注是修行', '坚持专注力'];
    const now = new Date();
    const dayOfYear = Math.floor((now.getTime() - new Date(now.getFullYear(), 0, 0).getTime()) /
      (1000 * 60 * 60 * 24));
    return quotes[(now.getHours() + dayOfYear) % quotes.length];
  }

  private firstAvatarText(): string {
    const name = this.displayName();
    return name.length > 0 ? name.substring(0, 1) : '用';
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

  private postImages(post: CommunityPost): string[] {
    if (post.imgList && post.imgList.length > 0) {
      return post.imgList;
    }
    return post.imageUrl.length > 0 ? [post.imageUrl] : [];
  }

  /** 小程序 MyPostCard：浏览量为 0 时随机展示 10–200，这里用 id 做种子保证稳定。 */
  private viewCountText(post: CommunityPost): string {
    if (post.viewCount > 0) {
      return `${post.viewCount}`;
    }
    let seed = 0;
    for (let index = 0; index < post.id.length; index++) {
      seed += post.id.charCodeAt(index);
    }
    return `${10 + (seed % 191)}`;
  }

  private isContentTruncated(post: CommunityPost): boolean {
    return post.content.length > 150;
  }

  /** 与小程序 utils/timeFormat.js 的 formatRelativeTime 一致。 */
  private formatTime(value: string): string {
    if (value.length === 0) {
      return '';
    }
    const date = new Date(value.replace(/-/g, '/').replace('T', ' '));
    const time = date.getTime();
    if (Number.isNaN(time)) {
      return value;
    }
    const diff = new Date().getTime() - time;
    if (diff < 60 * 1000) {
      return '刚刚';
    }
    if (diff < 60 * 60 * 1000) {
      return `${Math.floor(diff / (60 * 1000))}分钟前`;
    }
    if (diff < 24 * 60 * 60 * 1000) {
      return `${Math.floor(diff / (60 * 60 * 1000))}小时前`;
    }
    if (diff < 7 * 24 * 60 * 60 * 1000) {
      return `${Math.floor(diff / (24 * 60 * 60 * 1000))}天前`;
    }
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  /** 与小程序 user store 一致：仅本地切换状态，不调用接口。 */
  toggleLike(post: CommunityPost): void {
    const nextLiked = post.isLike !== 1;
    post.isLike = nextLiked ? 1 : 0;
    post.liked = nextLiked;
    post.likeCount = nextLiked ? post.likeCount + 1 : Math.max(post.likeCount - 1, 0);
    this.posts = this.posts.map((item: CommunityPost) => item.id === post.id ? post : item);
    this.postPager.items = this.postPager.items.map((item: CommunityPost) => item.id === post.id ? post : item);
  }

  confirmDelete(post: CommunityPost): void {
    this.pendingDeleteId = post.id;
    this.deleteDialog.open();
  }

  async deletePendingPost(): Promise<void> {
    const id = this.pendingDeleteId;
    this.pendingDeleteId = '';
    if (id.length === 0) {
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.deletePost(token, id, env);
      this.posts = this.posts.filter((post: CommunityPost) => post.id !== id);
      this.postPager.items = this.postPager.items.filter((post: CommunityPost) => post.id !== id);
      await CacheStore.setJson<CommunityPost[]>(this.context, 'myPosts', this.posts);
      ToastUtil.show('删除成功');
    } catch (err) {
      LogUtil.warn('mine', `delete post failed ${(err as Error).message}`);
      ToastUtil.show('删除失败，请稍后重试');
    }
  }

  private profileValue(field: string): string {
    if (field === 'school') {
      return this.user.school;
    }
    if (field === 'major') {
      return this.user.major;
    }
    return this.user.grade;
  }

  @Builder SchoolInfoRow(icon: string, label: string, field: string) {
    Row() {
      AppIcon({ name: icon, iconSize: 24 })
        .margin({ right: 12 })
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#07c160')
        .width(42)
      Text(this.profileValue(field).length > 0 ? this.profileValue(field) : '未填写')
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
        Text('⚙')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(34)
          .height(34)
          .margin({ left: 4 })
          .onClick(() => {
            this.openPage('pages/MeSetting');
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 16 })
      .linearGradient({
        angle: 90,
        colors: [['#07c160', 0.0], ['#39e28c', 1.0]]
      })
      .onClick(() => {
        this.openPage('pages/MeProfile');
      })

      Column() {
        this.SchoolInfoRow('profile_school', '学校:', 'school')
        this.SchoolInfoRow('profile_major', '专业:', 'major')
        this.SchoolInfoRow('profile_grade', '年级:', 'grade')
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
      } else {
        // 参考 QuickNav 的「消息」项本身无跳转；这里给明确反馈，避免静默无响应。
        ToastUtil.show('消息功能暂未开放');
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

  /** 动态图片：1 张大图、2 张并排、3 张首图通栏、4 张及以上两列网格（对齐 MyPostCard.vue）。 */
  @Builder PostImages(post: CommunityPost) {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      ForEach(this.postImages(post), (url: string, index: number) => {
        if (this.postImages(post).length === 1) {
          NetImage({
            imageUrl: url,
            imageHeight: 200,
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width(200)
            .height(200)
            .onClick(() => {
              this.previewUrl = url;
            })
        } else if (this.postImages(post).length === 3 && index === 0) {
          NetImage({
            imageUrl: url,
            imageHeight: 120,
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width('100%')
            .margin({ bottom: 3 })
            .onClick(() => {
              this.previewUrl = url;
            })
        } else {
          NetImage({
            imageUrl: url,
            imageHeight: this.postImages(post).length === 2 ? 120 : (this.postImages(post).length === 3 ? 120 : 100),
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width('48.5%')
            .margin({ bottom: 3 })
            .onClick(() => {
              this.previewUrl = url;
            })
        }
      }, (url: string, index: number) => `${post.id}-${index}-${url}`)
    }
    .width('100%')
    .margin({ top: 10 })
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
          Row() {
            AppIcon({ name: 'community_view', iconSize: 18 })
              .opacity(0.65)
            Text(this.viewCountText(post))
              .fontSize(13)
              .fontColor('#999999')
              .margin({ left: 3 })
          }
          Row() {
            AppIcon({ name: post.isLike === 1 ? 'community_liked' : 'community_like', iconSize: 18 })
            Text(`${post.likeCount}`)
              .fontSize(13)
              .fontColor(post.isLike === 1 ? '#ff6b6b' : '#999999')
              .margin({ left: 3 })
          }
          .margin({ left: 10 })
          .onClick(() => {
            this.toggleLike(post);
          })
          Row() {
            AppIcon({ name: 'community_comment', iconSize: 18 })
              .opacity(0.7)
            Text(`${post.commentCount}`)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ left: 3 })
          }
          .margin({ left: 10 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#f5f5f5')
        .borderRadius(16)
      }
      .width('100%')

      Column() {
        Text(post.content)
          .fontSize(15)
          .fontColor('#333333')
          .lineHeight(22)
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (this.isContentTruncated(post)) {
          Text('... 点击查看全部')
            .fontSize(13)
            .fontColor('#007AFF')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 12 })

      if (this.postImages(post).length > 0) {
        this.PostImages(post)
      }

      Row() {
        Text(this.formatTime(post.publishTime))
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
        AppIcon({ name: 'community_trash', iconSize: 20 })
          .width(32)
          .height(28)
          .onClick(() => {
            this.confirmDelete(post);
          })
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
    Stack({ alignContent: Alignment.BottomEnd }) {
      Refresh({ refreshing: $$this.refreshing }) {
        Scroll(this.scroller) {
          Column() {
            this.UserProfileCard()
            SectionCard({
              cardBg: '#00000000',
              showShadow: false,
              cardPadding: 0
            }) {
              Column() {
                this.QuickNav()
                this.CoreFunctions()
              }
              .width('100%')
            }

            Column() {
              if (this.loadingPosts && this.posts.length === 0) {
                Skeleton({ rows: 3, showAvatar: true })
                  .margin({ left: 12, right: 12 })
              } else if (this.posts.length === 0) {
                EmptyState({
                  title: '还没有发布动态',
                  description: '去社区分享你的第一条动态吧',
                  cardBg: '#FFFFFF'
                })
                  .margin({ left: 12, right: 12 })
              } else {
                ForEach(this.posts, (post: CommunityPost) => {
                  this.MyPostCard(post)
                }, (post: CommunityPost) => `${post.id}-${post.isLike}-${post.likeCount}-${post.commentCount}`)
                Text(this.postFooterText)
                  .fontSize(12)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 8, bottom: 18 })
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 2 })
          }
          .width('100%')
          .padding({ top: 4, bottom: 28 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onScroll(() => {
          this.showBackToTop = Math.abs(this.scroller.currentOffset().yOffset) > 400;
        })
        .onScrollEdge((side: Edge) => {
          if (side === Edge.Bottom) {
            this.loadMorePosts();
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
      .onRefreshing(() => {
        this.onRefresh();
      })

      BackToTop({
        visible: this.showBackToTop,
        onTap: () => {
          ScrollToTop.toTop(this.scroller);
          this.showBackToTop = false;
        }
      })

      if (this.previewUrl.length > 0) {
        Column() {
          Image(this.previewUrl)
            .width('100%')
            .height('80%')
            .objectFit(ImageFit.Contain)
          Text('点击任意处关闭')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ top: 18 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .zIndex(30)
        .onClick(() => {
          this.previewUrl = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
