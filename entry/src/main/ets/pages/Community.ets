import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { CommunityApi } from '../api/CommunityApi';
import { AppIcon } from '../components/AppIcon';
import { BackToTop } from '../components/common/BackToTop';
import { EmptyState } from '../components/common/EmptyState';
import { NetImage } from '../components/common/NetImage';
import { Skeleton } from '../components/common/Skeleton';
import { Tag } from '../components/common/Tag';
import { CommunityPost } from '../models/CommunityPost';
import { CommunityMock } from '../mock/CommunityMock';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { PageResult, PagedListController, ScrollToTop } from '../services/PagedList';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { ErrandTask, MockData } from '../utils/MockData';

class CommunityTab {
  label: string;
  value: string;
  icon: string;

  constructor(label: string, value: string, icon: string) {
    this.label = label;
    this.value = value;
    this.icon = icon;
  }
}

@Entry
@Component
export struct Community {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State posts: CommunityPost[] = [];
  @State errandTasks: ErrandTask[] = MockData.errandTasks();
  @State currentTab: string = 'dynamic';
  @State loading: boolean = true;
  @State refreshing: boolean = false;
  @State showBackToTop: boolean = false;
  @State previewUrl: string = '';
  @State followedAuthors: string[] = [];
  @StorageLink('communityPostDelta') @Watch('onPostDelta') postDelta: string = '';
  @StorageLink('communityRefreshAt') @Watch('onRefreshSignal') refreshAt: string = '';
  private scroller: Scroller = new Scroller();
  private pager: PagedListController<CommunityPost> =
    new PagedListController<CommunityPost>((cursor: string) => this.loadPosts(cursor));

  aboutToAppear(): void {
    this.loadFirstPage();
  }

  /** 第一页失败时优先用缓存/CommunityMock，保持可浏览（m2）。 */
  private async loadPosts(cursor: string): Promise<PageResult<CommunityPost>> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      const posts = await CommunityApi.recommend(token, apiEnvironment, cursor);
      const nextCursor = posts.length > 0 ? posts[posts.length - 1].id : '';
      const repeated = cursor.length > 0 && nextCursor === cursor;
      // 后端单页最多 20 条；不足 20 条即可判定为最后一页，避免末尾继续显示“上拉加载更多”。
      const hasMore = posts.length >= 20 && !repeated;
      if (cursor.length === 0) {
        await CacheStore.setJson<CommunityPost[]>(this.context, 'communityPosts', posts);
      }
      return new PageResult<CommunityPost>(posts, hasMore ? nextCursor : '', hasMore);
    } catch (err) {
      LogUtil.warn('community', `recommend failed cursor=${cursor} ${(err as Error).message}`);
      if (cursor.length > 0) {
        throw new Error('加载更多失败，请重试');
      }
      const cached = await CacheStore.getJson<CommunityPost[]>(this.context, 'communityPosts', CommunityMock.posts());
      const fallback = cached.length > 0 ? cached : CommunityMock.posts();
      return new PageResult<CommunityPost>(fallback, '', false);
    }
  }

  async loadFirstPage(): Promise<void> {
    this.loading = true;
    await this.pager.refresh();
    this.posts = this.pager.items;
    this.loading = false;
    this.showBackToTop = false;
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await this.pager.reload();
      this.posts = this.pager.items;
      this.showBackToTop = false;
    } catch (err) {
      LogUtil.warn('community', `refresh failed ${(err as Error).message}`);
    } finally {
      this.refreshing = false;
    }
  }

  async loadMore(): Promise<void> {
    await this.pager.loadMore();
    this.posts = this.pager.items;
  }

  private tabs(): CommunityTab[] {
    return [
      new CommunityTab('动态', 'dynamic', 'community_dynamic'),
      new CommunityTab('跑腿', 'errand', 'community_errand'),
      new CommunityTab('二手', 'secondhand', 'community_secondhand'),
      new CommunityTab('评分', 'rating', 'community_rating')
    ];
  }

  private filteredPosts(): CommunityPost[] {
    return this.posts;
  }

  /** 跑腿/二手图标的原始尺寸比另外两个大（与 index.vue 的 icon-large 一致）。 */
  private navIconSize(value: string): number {
    return value === 'errand' || value === 'secondhand' ? 27 : 22;
  }

  private postImages(post: CommunityPost): string[] {
    if (post.imgList && post.imgList.length > 0) {
      return post.imgList;
    }
    return post.imageUrl.length > 0 ? [post.imageUrl] : [];
  }

  private avatarText(post: CommunityPost): string {
    const name = post.author.length > 0 ? post.author : '用';
    return name.substring(0, 1);
  }

  private brandText(post: CommunityPost): string {
    const brandTitles: string[] = ['卷王', '躺平王', '摸鱼大师', '早八人', '夜猫子', '复习达人',
      '课表杀手', 'DDL战士', '食堂VIP', '图书馆常驻', '运动健将', '社团大佬', '宿舍躺王', '外卖达人',
      '校园百事通', '社交恐怖', '萌新', '老油条', '传说', '工具人', '水课王', '干饭人',
      '摸鱼专业户', '起床困难户', '拖延症晚期', '复习困难户'];
    let seed = 0;
    const name = post.author.length > 0 ? post.author : post.title;
    for (let index = 0; index < name.length; index++) {
      seed += name.charCodeAt(index);
    }
    return brandTitles[seed % brandTitles.length];
  }

  /** 与小程序 utils/timeFormat.js 的 formatRelativeTime 一致。 */
  private formatTime(value: string): string {
    if (value.length === 0) {
      return '';
    }
    const normalized = value.replace(/-/g, '/').replace('T', ' ');
    const date = new Date(normalized);
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

  private viewCount(post: CommunityPost): number {
    if (post.viewCount > 0) {
      return post.viewCount;
    }
    const source = post.id.length > 0 ? post.id : post.title;
    let seed = 0;
    for (let index = 0; index < source.length; index++) {
      seed = (seed * 31 + source.charCodeAt(index)) % 100000;
    }
    return 10 + (seed % 191);
  }

  private errandTypeColor(type: string): string {
    if (type === '校园跑腿') {
      return '#00cc6a';
    }
    if (type === '快递代取') {
      return '#ff9500';
    }
    if (type === '快递到寝') {
      return '#007AFF';
    }
    if (type === '东南门代拿') {
      return '#ff6b6b';
    }
    if (type === '东北门代拿') {
      return '#5856d6';
    }
    if (type === '西门代拿') {
      return '#ffcc00';
    }
    return '#999999';
  }

  private errandStatusText(status: string): string {
    if (status === 'pending') {
      return '待接单';
    }
    if (status === 'completed') {
      return '订单完成';
    }
    if (status === 'cancelled') {
      return '已取消';
    }
    return '未知状态';
  }

  private errandStatusColor(status: string): string {
    if (status === 'pending') {
      return '#ff9500';
    }
    if (status === 'completed') {
      return '#00cc6a';
    }
    if (status === 'cancelled') {
      return '#999999';
    }
    return '#999999';
  }

  private errandStatusBg(status: string): string {
    if (status === 'pending') {
      return '#1Aff9500';
    }
    if (status === 'completed') {
      return '#1A00cc6a';
    }
    if (status === 'cancelled') {
      return '#1A999999';
    }
    return '#1A999999';
  }

  openDetail(post: CommunityPost): void {
    router.pushUrl({
      url: 'pages/CommunityDetail',
      params: { id: post.id }
    });
  }

  openPublish(): void {
    router.pushUrl({ url: 'pages/CommunityPublish' });
  }

  private isFollowing(post: CommunityPost): boolean {
    return this.followedAuthors.indexOf(post.author) >= 0;
  }

  /** 关注/取关为本地交互（小程序也未接后端关注接口）。 */
  private toggleFollow(post: CommunityPost): void {
    if (!this.isFollowing(post)) {
      this.followedAuthors = this.followedAuthors.concat([post.author]);
      return;
    }
    promptAction.showDialog({
      title: '确认取关',
      message: `确定要取消关注 ${post.author} 吗？`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#00cc6a' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.followedAuthors = this.followedAuthors.filter((name: string) => name !== post.author);
      }
    });
  }

  /** 发布成功后重新拉取第一页。 */
  private onRefreshSignal(): void {
    if (this.refreshAt.length === 0) {
      return;
    }
    AppStorage.setOrCreate<string>('communityRefreshAt', '');
    this.onRefresh();
  }

  /** 详情页返回后同步点赞/评论数，避免列表停留在旧数据。 */
  private onPostDelta(): void {
    if (this.postDelta.length === 0) {
      return;
    }
    const parts = this.postDelta.split('|');
    if (parts.length < 4) {
      return;
    }
    const id = parts[0];
    const liked = parts[1] === '1';
    const likeCount = Number(parts[2]);
    const commentCount = Number(parts[3]);
    const apply = (post: CommunityPost): CommunityPost => {
      if (post.id !== id) {
        return post;
      }
      post.liked = liked;
      post.isLike = liked ? 1 : 0;
      post.likeCount = Number.isNaN(likeCount) ? post.likeCount : likeCount;
      post.commentCount = Number.isNaN(commentCount) ? post.commentCount : commentCount;
      return post;
    };
    this.posts = this.posts.map(apply);
    this.pager.items = this.pager.items.map(apply);
    AppStorage.setOrCreate<string>('communityPostDelta', '');
  }

  async toggleLike(post: CommunityPost): Promise<void> {
    // 乐观点赞：先更新 UI，失败后回滚（与任务约定一致）。
    const nextLiked = !post.liked;
    const previousLiked = post.liked;
    const previousCount = post.likeCount;
    post.liked = nextLiked;
    post.isLike = nextLiked ? 1 : 0;
    post.likeCount = previousCount + (nextLiked ? 1 : -1);
    this.posts = this.posts.map((item: CommunityPost) => item.id === post.id ? post : item);
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.like(token, post.id, nextLiked, apiEnvironment);
    } catch (err) {
      LogUtil.warn('community', `like failed ${(err as Error).message}`);
      post.liked = previousLiked;
      post.isLike = previousLiked ? 1 : 0;
      post.likeCount = previousCount;
      this.posts = this.posts.map((item: CommunityPost) => item.id === post.id ? post : item);
      ToastUtil.show('点赞失败，请重试');
    }
  }

  @Builder NavItem(tab: CommunityTab) {
    Column() {
      Row() {
        AppIcon({ name: tab.icon, iconSize: this.navIconSize(tab.value) })
          .opacity(this.currentTab === tab.value ? 1 : 0.58)
          .scale({
            x: this.currentTab === tab.value ? 1.1 : 1,
            y: this.currentTab === tab.value ? 1.1 : 1
          })
        Text(tab.label)
          .fontSize(12)
          .fontWeight(this.currentTab === tab.value ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === tab.value ? '#00cc6a' : '#666666')
          .margin({ left: 4 })
      }
      .height(42)
      .justifyContent(FlexAlign.Center)

      Text('')
        .width(20)
        .height(3)
        .backgroundColor(this.currentTab === tab.value ? '#00cc6a' : '#00ffffff')
        .borderRadius(2)
    }
    .layoutWeight(1)
    .onClick(() => {
      this.currentTab = tab.value;
    })
  }

  /** 动态图片：1 张大图、3 张首图通栏、其余两列网格（对齐 PostCard.vue）。 */
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
            imageHeight: this.postImages(post).length >= 4 ? 100 : 120,
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

  @Builder PostCard(post: CommunityPost) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.TopStart }) {
          Text(this.avatarText(post))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .linearGradient({
              angle: 135,
              colors: [['#6e8efb', 0.0], ['#a777e3', 1.0]]
            })
            .borderRadius(20)
          Tag({
            text: this.brandText(post),
            fgColor: '#FFFFFF',
            bgColor: '#ff9a56',
            fontSize: 10,
            tagRadius: 4,
            tagPaddingH: 7,
            tagPaddingV: 2,
            centerText: true
          })
            .width(70)
            .rotate({ angle: -8 })
            .position({ x: -10, y: 33 })
        }
        .width(50)
        .height(52)
        .margin({ right: 10 })

        Column() {
          Text(post.author)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(this.formatTime(post.publishTime))
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.isFollowing(post) ? '已关注' : '关注')
          .fontSize(12)
          .fontColor(this.isFollowing(post) ? '#999999' : '#00cc6a')
          .padding({ left: 15, right: 15, top: 6, bottom: 6 })
          .border({ width: 1, color: this.isFollowing(post) ? '#dddddd' : '#00cc6a' })
          .borderRadius(16)
          .onClick(() => {
            this.toggleFollow(post);
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(post.content)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      if (this.postImages(post).length > 0) {
        this.PostImages(post)
      }

      Row() {
        Row() {
          AppIcon({ name: 'community_view', iconSize: 15 })
            .opacity(0.62)
          Text(`${this.viewCount(post)}`)
            .fontSize(13)
            .fontColor('#999999')
            .margin({ left: 4 })
        }
        .layoutWeight(1)

        Row() {
          Row() {
            AppIcon({ name: 'community_comment', iconSize: 15 })
              .opacity(0.7)
            Text(`${post.commentCount}`)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .margin({ right: 16 })

          Row() {
            AppIcon({ name: post.isLike === 1 ? 'community_liked' : 'community_like', iconSize: 16 })
            Text(`${post.likeCount}`)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .onClick(() => {
            this.toggleLike(post);
          })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#f5f5f5')
        .borderRadius(16)
      }
      .width('100%')
      .padding({ top: 12 })
      .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 7 })
    .onClick(() => {
      this.openDetail(post);
    })
  }

  @Builder DynamicList() {
    Column() {
      if (this.loading && this.filteredPosts().length === 0) {
        Skeleton({ rows: 4, showAvatar: true })
          .margin({ left: 12, right: 12, top: 12 })
      } else if (this.filteredPosts().length === 0) {
        EmptyState({
          title: '暂无动态',
          description: '下拉刷新，或稍后再来看看',
          actionText: '重新加载',
          onAction: () => {
            this.onRefresh();
          }
        })
          .margin({ top: 12 })
      } else {
        ForEach(this.filteredPosts(), (post: CommunityPost) => {
          this.PostCard(post)
        }, (post: CommunityPost) => `${post.id}-${post.isLike}-${post.likeCount}-${post.commentCount}`)
        if (this.pager.error.length > 0) {
          Text('加载失败，点击重试')
            .fontSize(12)
            .fontColor('#ff6b6b')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 24 })
            .onClick(() => {
              this.loadMore();
            })
        } else {
          Text(this.pager.footerText())
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 24 })
        }
      }
    }
    .width('100%')
  }

  @Builder ErrandCard(task: ErrandTask) {
    Column() {
      Row() {
        Text(task.type)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.errandTypeColor(task.type))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: this.errandTypeColor(task.type) })
          .borderRadius(4)
          .margin({ right: 8 })
        Text(task.content)
          .fontSize(15)
          .fontColor('#333333')
          .lineHeight(20)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        AppIcon({ name: 'community_position', iconSize: 16 })
          .margin({ right: 6 })
        Text(`${task.from} → ${task.to}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#f5f5f5')
      .borderRadius(4)
      .margin({ bottom: 12 })

      Row() {
        Row() {
          AppIcon({ name: 'community_yuan', iconSize: 16 })
            .margin({ right: 4 })
          Text(`${task.price}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ff9500')
        }
        .layoutWeight(1)

        Text(this.errandStatusText(task.status))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.errandStatusColor(task.status))
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(this.errandStatusBg(task.status))
          .borderRadius(12)
          .margin({ right: 8 })
        AppIcon({ name: 'community_more', iconSize: 16 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  @Builder ErrandList() {
    Column() {
      if (this.errandTasks.length === 0) {
        Text('暂无跑腿任务')
          .fontSize(14)
          .fontColor('#999999')
          .height(160)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        ForEach(this.errandTasks, (task: ErrandTask) => {
          this.ErrandCard(task)
        }, (task: ErrandTask) => task.id)
      }
    }
    .width('100%')
    .padding({ top: 10, left: 0, right: 0 })
  }

  @Builder EmptyTab(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor('#999999')
      .height(160)
      .width('100%')
      .textAlign(TextAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          ForEach(this.tabs(), (tab: CommunityTab) => {
            this.NavItem(tab)
          }, (tab: CommunityTab) => tab.value)
        }
        .width('100%')
        .height(64)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })

        Refresh({ refreshing: $$this.refreshing }) {
          Scroll(this.scroller) {
            if (this.currentTab === 'dynamic') {
              this.DynamicList()
            } else if (this.currentTab === 'errand') {
              this.ErrandList()
            } else if (this.currentTab === 'secondhand') {
              this.EmptyTab('二手功能开发中...')
            } else {
              this.EmptyTab('评分功能开发中...')
            }
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#f8f8f8')
          .scrollBar(BarState.Off)
          .onScroll(() => {
            this.showBackToTop = Math.abs(this.scroller.currentOffset().yOffset) > 300;
          })
          .onScrollEdge((side: Edge) => {
            if (side === Edge.Bottom && this.currentTab === 'dynamic') {
              this.loadMore();
            }
          })
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.onRefresh();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f8f8')

      BackToTop({
        visible: this.showBackToTop,
        marginBottom: 146,
        onTap: () => {
          ScrollToTop.toTop(this.scroller);
          this.showBackToTop = false;
        }
      })

      Button('+')
        .width(50)
        .height(50)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#00cc6a')
        .borderRadius(25)
        .shadow({ radius: 10, color: '#33000000', offsetX: 0, offsetY: 3 })
        .margin({ right: 20, bottom: 80 })
        .onClick(() => {
          this.openPublish();
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
