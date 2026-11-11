import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppIcon } from '../components/AppIcon';
import { BackToTop } from '../components/common/BackToTop';
import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { CoverImage } from '../components/common/CoverImage';
import { EmptyState } from '../components/common/EmptyState';
import { Skeleton } from '../components/common/Skeleton';
import { CommunityPost } from '../models/CommunityPost';
import { RouteParams } from '../models/MiniProgramModels';
import { CommunityApi, PostComment } from '../api/CommunityApi';
import { PageResult, PagedListController, ScrollToTop } from '../services/PagedList';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct CommunityDetail {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State post: CommunityPost = MockData.posts()[0];
  @State comments: PostComment[] = [];
  @State commentText: string = '';
  @State loadingComments: boolean = true;
  @State refreshing: boolean = false;
  @State showBackToTop: boolean = false;
  private postId: string = '';
  private myUserId: string = '';
  private pendingDeleteId: string = '';
  private scroller: Scroller = new Scroller();
  private commentPager: PagedListController<PostComment> =
    new PagedListController<PostComment>((cursor: string) => this.loadCommentPage(cursor));
  private deleteDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除评论',
      message: '删除后不可恢复，确定删除这条评论吗？',
      confirmText: '删除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.deleteComment();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : await CacheStore.getString(this.context, 'lastPostId', 'post-1');
    this.postId = id;
    const me = await AuthStore.getUser(this.context);
    this.myUserId = me.id.length > 0 ? me.id : me.studentId;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const detail = await CommunityApi.detail(token, id, env);
      if (detail !== null) {
        this.post = detail;
      }
      await CacheStore.setJson<CommunityPost>(this.context, `post:${id}`, this.post);
    } catch (err) {
      LogUtil.warn('detail', `post failed ${(err as Error).message}`);
      const fallback = MockData.posts().find((item: CommunityPost) => item.id === id) || MockData.posts()[0];
      this.post = await CacheStore.getJson<CommunityPost>(this.context, `post:${id}`, fallback);
    }
    await this.loadFirstComments();
  }

  private async loadCommentPage(cursor: string): Promise<PageResult<PostComment>> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const list = await CommunityApi.comments(token, this.postId, env, cursor);
      const nextCursor = list.length > 0 ? `${list[list.length - 1].id}` : '';
      const repeated = cursor.length > 0 && nextCursor === cursor;
      if (cursor.length === 0) {
        await CacheStore.setJson<PostComment[]>(this.context, `comments:${this.postId}`, list);
      }
      return new PageResult<PostComment>(list, repeated ? '' : nextCursor, list.length > 0 && !repeated);
    } catch (err) {
      LogUtil.warn('detail', `comments failed cursor=${cursor} ${(err as Error).message}`);
      if (cursor.length > 0) {
        throw new Error('加载更多评论失败，请重试');
      }
      const cached = await CacheStore.getJson<PostComment[]>(this.context, `comments:${this.postId}`, [
        new PostComment('comment-1', '校园助手', '这里可以继续补充你的看法。', '刚刚')
      ]);
      return new PageResult<PostComment>(cached, '', false);
    }
  }

  async loadFirstComments(): Promise<void> {
    this.loadingComments = true;
    await this.commentPager.refresh();
    this.comments = this.commentPager.items;
    this.loadingComments = false;
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await this.commentPager.reload();
      this.comments = this.commentPager.items;
      this.showBackToTop = false;
    } catch (err) {
      LogUtil.warn('detail', `refresh failed ${(err as Error).message}`);
    } finally {
      this.refreshing = false;
    }
  }

  async loadMoreComments(): Promise<void> {
    await this.commentPager.loadMore();
    this.comments = this.commentPager.items;
  }

  async addComment(): Promise<void> {
    if (this.commentText.trim().length === 0) {
      ToastUtil.show('请输入评论内容');
      return;
    }
    const text = this.commentText.trim();
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      // CommunityApi.addComment 内部先调用 /check/text，检查失败或 401 会抛出并阻断。
      await CommunityApi.addComment(token, this.post.id, text, env);
    } catch (err) {
      ToastUtil.show(`评论失败：${(err as Error).message}`);
      return;
    }
    const local = new PostComment(`local-${new Date().getTime()}`, '我', text, '刚刚', this.myUserId);
    this.commentPager.items = [local].concat(this.commentPager.items);
    this.comments = this.commentPager.items;
    this.commentText = '';
    ToastUtil.show('评论成功');
    await CacheStore.setJson<PostComment[]>(this.context, `comments:${this.post.id}`, this.comments);
  }

  private canDelete(comment: PostComment): boolean {
    if (comment.author === '我') {
      return true;
    }
    return this.myUserId.length > 0 && `${comment.uid}` === this.myUserId;
  }

  confirmDelete(comment: PostComment): void {
    this.pendingDeleteId = comment.id;
    this.deleteDialog.open();
  }

  async deleteComment(): Promise<void> {
    const commentId = this.pendingDeleteId;
    this.pendingDeleteId = '';
    if (commentId.length === 0) {
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.deleteComment(token, commentId, env);
    } catch (err) {
      ToastUtil.show(`删除失败：${(err as Error).message}`);
      return;
    }
    this.commentPager.items = this.commentPager.items.filter((item: PostComment) => item.id !== commentId);
    this.comments = this.commentPager.items;
    ToastUtil.show('评论已删除');
    await CacheStore.setJson<PostComment[]>(this.context, `comments:${this.post.id}`, this.comments);
  }

  async addReply(comment: PostComment): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.addReply(token, comment.id, '收到，感谢补充。', env);
      ToastUtil.show('回复成功');
    } catch (err) {
      ToastUtil.show(`回复失败：${(err as Error).message}`);
    }
  }

  @Builder
  AuthorInfo() {
    Row() {
      Text(this.post.author.length > 0 ? this.post.author.substring(0, 1) : '互')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#07C160')
      Column() {
        Text(this.post.author.length > 0 ? this.post.author : '互成一家用户')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text(this.post.publishTime.length > 0 ? this.post.publishTime : '刚刚')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
  }

  @Builder
  PostCard() {
    Column() {
      this.AuthorInfo()
      Text(this.post.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .lineHeight(30)
        .width('100%')
        .margin({ top: 18 })
      Text(this.post.content)
        .fontSize(15)
        .fontColor('#555555')
        .lineHeight(24)
        .width('100%')
        .margin({ top: 10 })
      if (this.post.imageUrl.length > 0) {
        CoverImage({
          imageUrl: this.post.imageUrl,
          title: '',
          watermarkText: '互成一家 · 社区',
          imageHeight: 190,
          imageRadius: 12
        })
          .margin({ top: 14 })
      }
      Row() {
        AppIcon({ name: this.post.isLike === 1 ? 'community_liked' : 'community_like', iconSize: 16 })
        Text(`${this.post.likeCount}`)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ left: 4 })
        AppIcon({ name: 'community_comment', iconSize: 16 })
          .margin({ left: 18 })
        Text(`${this.comments.length}`)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ left: 4 })
        AppIcon({ name: 'community_view', iconSize: 16 })
          .margin({ left: 18 })
          .opacity(0.7)
        Text(`${this.post.viewCount}`)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ top: 14 })
      .margin({ top: 14 })
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  CommentBox() {
    Row() {
      TextInput({ placeholder: '写评论', text: this.commentText })
        .layoutWeight(1)
        .height(42)
        .backgroundColor('#F5F5F5')
        .borderRadius(21)
        .padding({ left: 16, right: 12 })
        .onChange((value: string) => {
          this.commentText = value;
        })
      Button('发送')
        .height(42)
        .backgroundColor('#07C160')
        .borderRadius(21)
        .margin({ left: 8 })
        .onClick(() => {
          this.addComment();
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 12 })
  }

  @Builder
  CommentCard(comment: PostComment) {
    Column() {
      Row() {
        Text(comment.author)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text(comment.createTime)
          .fontSize(11)
          .fontColor('#999999')
      }
      Text(comment.content)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(21)
        .width('100%')
        .margin({ top: 8 })
      Row() {
        Text('回复')
          .fontSize(12)
          .fontColor('#2979FF')
          .onClick(() => {
            this.addReply(comment);
          })
        if (this.canDelete(comment)) {
          Text('删除')
            .fontSize(12)
            .fontColor('#FF3B30')
            .margin({ left: 18 })
            .onClick(() => {
              this.confirmDelete(comment);
            })
        }
      }
      .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ top: 10 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        PageHeader({ title: '动态详情' })
        Refresh({ refreshing: $$this.refreshing }) {
          Scroll(this.scroller) {
            Column() {
              this.PostCard()
              this.CommentBox()
              if (this.loadingComments && this.comments.length === 0) {
                Skeleton({ rows: 3, showAvatar: true })
                  .margin({ top: 12 })
              } else if (this.comments.length === 0) {
                EmptyState({
                  title: '还没有评论',
                  description: '来抢沙发，说说你的看法'
                })
                  .margin({ top: 12 })
              } else {
                ForEach(this.comments, (comment: PostComment) => {
                  this.CommentCard(comment)
                }, (comment: PostComment) => comment.id)
                Text(this.commentPager.footerText())
                  .fontSize(12)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 16, bottom: 20 })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 24 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onScroll(() => {
            this.showBackToTop = Math.abs(this.scroller.currentOffset().yOffset) > 300;
          })
          .onScrollEdge((side: Edge) => {
            if (side === Edge.Bottom) {
              this.loadMoreComments();
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
      .backgroundColor('#F8F8F8')

      BackToTop({
        visible: this.showBackToTop,
        onTap: () => {
          ScrollToTop.toTop(this.scroller);
          this.showBackToTop = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
