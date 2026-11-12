import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppIcon } from '../components/AppIcon';
import { ConfirmDialog } from '../components/common/ConfirmDialog';
import { EmptyState } from '../components/common/EmptyState';
import { NetImage } from '../components/common/NetImage';
import { Skeleton } from '../components/common/Skeleton';
import { CommunityPost } from '../models/CommunityPost';
import { RouteParams } from '../models/MiniProgramModels';
import { CommunityApi, PostComment } from '../api/CommunityApi';
import { PageResult, PagedListController } from '../services/PagedList';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

/** 详情页把点赞/评论变化写回列表页（Community.ets 监听同一 key）。 */
const POST_DELTA_KEY: string = 'communityPostDelta';

@Entry
@Component
struct CommunityDetail {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State post: CommunityPost = MockData.posts()[0];
  @State liked: boolean = false;
  @State likeCount: number = 0;
  @State commentCount: number = 0;
  @State viewCount: number = 0;
  @State comments: PostComment[] = [];
  @State commentText: string = '';
  @State loadingComments: boolean = true;
  @State commentsError: string = '';
  @State refreshing: boolean = false;
  @State previewUrl: string = '';
  @State replyTargetId: string = '';
  @State replyTargetName: string = '';
  @State replyTargetContent: string = '';
  @State loadingRepliesId: string = '';
  private postId: string = '';
  private myUserId: string = '';
  private pendingDeleteCommentId: string = '';
  private pendingDeleteReplyId: string = '';
  private pendingDeleteParentId: string = '';
  private scroller: Scroller = new Scroller();
  private commentPager: PagedListController<PostComment> =
    new PagedListController<PostComment>((cursor: string) => this.loadCommentPage(cursor));
  private deleteCommentDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '提示',
      message: '确定要删除这条评论吗？',
      confirmText: '删除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.deleteComment();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });
  private deleteReplyDialog: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '提示',
      message: '确定要删除这条回复吗？',
      confirmText: '删除',
      confirmColor: '#FF3B30',
      onConfirm: () => {
        this.deleteReply();
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    this.postId = params && params.id ? params.id : '';
    if (this.postId.length === 0) {
      ToastUtil.show('帖子ID无效');
      router.back();
      return;
    }
    const me = await AuthStore.getUser(this.context);
    this.myUserId = me.id.length > 0 ? me.id : me.studentId;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const detail = await CommunityApi.detail(token, this.postId, env);
      if (detail !== null) {
        this.post = detail;
      }
      await CacheStore.setJson<CommunityPost>(this.context, `post:${this.postId}`, this.post);
    } catch (err) {
      LogUtil.warn('detail', `post failed ${(err as Error).message}`);
      const fallback = MockData.posts().find((item: CommunityPost) => item.id === this.postId) || MockData.posts()[0];
      this.post = await CacheStore.getJson<CommunityPost>(this.context, `post:${this.postId}`, fallback);
    }
    this.syncPostState();
    await this.loadFirstComments();
  }

  /** 用独立的 @State 镜像帖子计数，避免直接改嵌套对象不触发刷新。 */
  private syncPostState(): void {
    this.liked = this.post.isLike === 1;
    this.likeCount = this.post.likeCount;
    this.commentCount = this.post.commentCount;
    this.viewCount = this.post.viewCount;
  }

  private async loadCommentPage(cursor: string): Promise<PageResult<PostComment>> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    const list = await CommunityApi.comments(token, this.postId, env, cursor);
    const nextCursor = list.length > 0 ? `${list[list.length - 1].id}` : '';
    const repeated = cursor.length > 0 && nextCursor === cursor;
    if (cursor.length === 0) {
      await CacheStore.setJson<PostComment[]>(this.context, `comments:${this.postId}`, list);
    }
    // 与小程序 showLoadMoreComments 一致：满 10 条才提示加载更多。
    return new PageResult<PostComment>(list, repeated ? '' : nextCursor, list.length >= 10 && !repeated);
  }

  private async loadFirstComments(): Promise<void> {
    this.loadingComments = true;
    this.commentsError = '';
    await this.commentPager.refresh();
    this.comments = this.commentPager.items;
    if (this.commentPager.error.length > 0) {
      this.commentsError = this.commentPager.error;
      LogUtil.warn('detail', `comments failed ${this.commentPager.error}`);
    }
    this.loadingComments = false;
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await this.loadFirstComments();
    } finally {
      this.refreshing = false;
    }
  }

  async loadMoreComments(): Promise<void> {
    await this.commentPager.loadMore();
    this.comments = this.commentPager.items;
    if (this.commentPager.error.length > 0) {
      ToastUtil.show('加载更多评论失败');
    }
  }

  private publishPostDelta(): void {
    AppStorage.setOrCreate<string>(POST_DELTA_KEY,
      `${this.post.id}|${this.liked ? 1 : 0}|${this.likeCount}|${this.commentCount}`);
  }

  async toggleLike(): Promise<void> {
    const previousLiked = this.liked;
    const previousCount = this.likeCount;
    const nextLiked = !previousLiked;
    this.liked = nextLiked;
    this.likeCount = previousCount + (nextLiked ? 1 : -1);
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.like(token, this.post.id, nextLiked, env);
      this.publishPostDelta();
    } catch (err) {
      LogUtil.warn('detail', `like failed ${(err as Error).message}`);
      this.liked = previousLiked;
      this.likeCount = previousCount;
      ToastUtil.show('点赞失败，请重试');
    }
  }

  private setReplyTarget(comment: PostComment): void {
    this.replyTargetId = comment.id;
    this.replyTargetName = comment.author.length > 0 ? comment.author : '同学';
    this.replyTargetContent = comment.content.length > 20 ? `${comment.content.substring(0, 20)}...` : comment.content;
  }

  private cancelReply(): void {
    this.replyTargetId = '';
    this.replyTargetName = '';
    this.replyTargetContent = '';
  }

  async submitComment(): Promise<void> {
    const text = this.commentText.trim();
    if (text.length === 0) {
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    const now = new Date();
    if (this.replyTargetId.length > 0) {
      const parentId = this.replyTargetId;
      let replyId = '';
      try {
        // addReply 内部先 /check/text，检查失败或 401 会抛错并阻断。
        replyId = await CommunityApi.addReply(token, parentId, text, env);
      } catch (err) {
        ToastUtil.show(`评论失败：${(err as Error).message}`);
        return;
      }
      const reply = new PostComment(replyId.length > 0 ? replyId : `local-reply-${now.getTime()}`,
        this.myName(), text, this.nowText(), this.myUserId);
      this.comments = this.comments.map((comment: PostComment) => {
        if (comment.id !== parentId) {
          return comment;
        }
        const updated = comment;
        updated.replyList = updated.replyList.concat([reply]);
        updated.replyCount = updated.replyCount + 1;
        updated.showReplies = true;
        return updated;
      });
      this.commentCount = this.commentCount + 1;
    } else {
      let commentId = '';
      try {
        commentId = await CommunityApi.addComment(token, this.post.id, text, env);
      } catch (err) {
        ToastUtil.show(`评论失败：${(err as Error).message}`);
        return;
      }
      const comment = new PostComment(commentId.length > 0 ? commentId : `local-${now.getTime()}`,
        this.myName(), text, this.nowText(), this.myUserId);
      this.commentPager.items = [comment].concat(this.commentPager.items);
      this.comments = this.commentPager.items;
      this.commentCount = this.commentCount + 1;
    }
    this.commentText = '';
    this.cancelReply();
    this.publishPostDelta();
    ToastUtil.show('评论成功');
  }

  private myName(): string {
    return this.myUserId.length > 0 ? '我' : '游客';
  }

  private nowText(): string {
    const date = new Date();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day} ${hour}:${minute}:00`;
  }

  private canDelete(comment: PostComment): boolean {
    if (comment.author === '我') {
      return true;
    }
    return this.myUserId.length > 0 && `${comment.uid}` === this.myUserId;
  }

  private openDeleteComment(comment: PostComment): void {
    if (!this.canDelete(comment)) {
      ToastUtil.show('无法删除他人评论');
      return;
    }
    this.pendingDeleteCommentId = comment.id;
    this.deleteCommentDialog.open();
  }

  private async deleteComment(): Promise<void> {
    const commentId = this.pendingDeleteCommentId;
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
    this.commentPager.items =
      this.commentPager.items.filter((comment: PostComment) => comment.id !== commentId);
    this.comments = this.commentPager.items;
    this.commentCount = Math.max(this.commentCount - 1, 0);
    this.pendingDeleteCommentId = '';
    this.publishPostDelta();
    ToastUtil.show('删除成功');
  }

  private openDeleteReply(parent: PostComment, reply: PostComment): void {
    if (!this.canDelete(reply)) {
      ToastUtil.show('无法删除他人评论');
      return;
    }
    this.pendingDeleteParentId = parent.id;
    this.pendingDeleteReplyId = reply.id;
    this.deleteReplyDialog.open();
  }

  private async deleteReply(): Promise<void> {
    const parentId = this.pendingDeleteParentId;
    const replyId = this.pendingDeleteReplyId;
    if (parentId.length === 0 || replyId.length === 0) {
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.deleteReply(token, replyId, env);
    } catch (err) {
      ToastUtil.show(`删除失败：${(err as Error).message}`);
      return;
    }
    this.comments = this.comments.map((comment: PostComment) => {
      if (comment.id !== parentId) {
        return comment;
      }
      const updated = comment;
      updated.replyList = updated.replyList.filter((reply: PostComment) => reply.id !== replyId);
      updated.replyCount = Math.max(updated.replyCount - 1, 0);
      return updated;
    });
    this.commentCount = Math.max(this.commentCount - 1, 0);
    this.pendingDeleteParentId = '';
    this.pendingDeleteReplyId = '';
    this.publishPostDelta();
    ToastUtil.show('删除成功');
  }

  private async loadReplies(comment: PostComment, more: boolean): Promise<void> {
    if (this.loadingRepliesId.length > 0) {
      return;
    }
    this.loadingRepliesId = comment.id;
    if (!more) {
      // 与小程序一致：先展开回复区（显示骨架），再请求。
      this.comments = this.comments.map((item: PostComment) => {
        if (item.id === comment.id) {
          item.showReplies = true;
        }
        return item;
      });
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    const cursor = more && comment.replyList.length > 0
      ? comment.replyList[comment.replyList.length - 1].id : '';
    try {
      const replies = await CommunityApi.replies(token, comment.id, env, cursor);
      this.comments = this.comments.map((item: PostComment) => {
        if (item.id !== comment.id) {
          return item;
        }
        const updated = item;
        updated.replyList = more ? updated.replyList.concat(replies) : replies;
        updated.showReplies = true;
        updated.replyHasMore = replies.length >= 5;
        if (updated.replyCount < updated.replyList.length) {
          updated.replyCount = updated.replyList.length;
        }
        return updated;
      });
    } catch (err) {
      LogUtil.warn('detail', `replies failed ${(err as Error).message}`);
      ToastUtil.show('加载回复失败');
      this.comments = this.comments.map((item: PostComment) => {
        if (item.id !== comment.id) {
          return item;
        }
        item.showReplies = true;
        return item;
      });
    } finally {
      this.loadingRepliesId = '';
    }
  }

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

  private postImages(): string[] {
    if (this.post.imgList && this.post.imgList.length > 0) {
      return this.post.imgList.slice(0, 4);
    }
    return this.post.imageUrl.length > 0 ? [this.post.imageUrl] : [];
  }

  private initialOf(name: string): string {
    return name.length > 0 ? name.substring(0, 1) : '用';
  }

  @Builder Avatar(name: string, size: number) {
    Text(this.initialOf(name))
      .fontSize(Math.max(size / 2.2, 12))
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .width(size)
      .height(size)
      .textAlign(TextAlign.Center)
      .borderRadius(size / 2)
      .linearGradient({
        angle: 135,
        colors: [['#6e8efb', 0.0], ['#a777e3', 1.0]]
      })
  }

  @Builder PostImages() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      ForEach(this.postImages(), (url: string, index: number) => {
        if (this.postImages().length === 1) {
          NetImage({
            imageUrl: url,
            imageHeight: 193,
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width('100%')
            .onClick(() => {
              this.previewUrl = url;
            })
        } else if (this.postImages().length === 3) {
          NetImage({
            imageUrl: url,
            imageHeight: 100,
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width('32%')
            .onClick(() => {
              this.previewUrl = url;
            })
        } else {
          NetImage({
            imageUrl: url,
            imageHeight: this.postImages().length === 4 ? 150 : 120,
            imageRadius: 6,
            fitMode: 'cover'
          })
            .width('48.5%')
            .margin({ bottom: 4 })
            .onClick(() => {
              this.previewUrl = url;
            })
        }
      }, (url: string, index: number) => `${this.post.id}-${index}-${url}`)
    }
    .width('100%')
    .margin({ top: 10, bottom: 12 })
  }

  @Builder PostCard() {
    Column() {
      Row() {
        this.Avatar(this.post.author, 40)
        Column() {
          Text(this.post.author.length > 0 ? this.post.author : '校园同学')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(this.formatTime(this.post.publishTime))
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.post.title.length > 0) {
        Text(this.post.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .lineHeight(25)
          .width('100%')
          .margin({ bottom: 10 })
      }

      Text(this.post.content)
        .fontSize(15)
        .fontColor('#555555')
        .lineHeight(25)
        .width('100%')

      if (this.postImages().length > 0) {
        this.PostImages()
      }

      Row() {
        Row() {
          AppIcon({ name: 'community_view', iconSize: 16 })
            .margin({ right: 8 })
          Text(`${this.viewCount}`)
            .fontSize(16)
            .fontColor('#888888')
        }

        Row() {
          AppIcon({ name: this.liked ? 'community_liked' : 'community_like', iconSize: 18 })
            .margin({ right: 8 })
          Text(`${this.likeCount}`)
            .fontSize(16)
            .fontColor('#888888')
        }
        .onClick(() => {
          this.toggleLike();
        })

        Row() {
          AppIcon({ name: 'community_comment', iconSize: 16 })
            .margin({ right: 8 })
          Text(`${this.commentCount}`)
            .fontSize(16)
            .fontColor('#888888')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#f0f0f0' })
    .shadow({ radius: 6, color: '#14000000', offsetX: 0, offsetY: 1 })
    .margin({ bottom: 12 })
  }

  @Builder ReplyItem(parentComment: PostComment, replyItem: PostComment) {
    Row() {
      this.Avatar(replyItem.author, 30)
      Column() {
        Row() {
          Text(replyItem.author)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(this.formatTime(replyItem.createTime))
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 6 })
        }

        Text(replyItem.content)
          .fontSize(13)
          .fontColor('#333333')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 3 })

        if (this.canDelete(replyItem)) {
          Row() {
            AppIcon({ name: 'community_trash', iconSize: 14 })
              .opacity(0.7)
          }
          .width(30)
          .height(30)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#fff5f5')
          .borderRadius(15)
          .margin({ top: 6 })
          .onClick(() => {
            this.openDeleteReply(parentComment, replyItem);
          })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 1 }, color: '#f8f9fa' })
  }

  @Builder CommentCard(comment: PostComment) {
    Column() {
      Row() {
        this.Avatar(comment.author, 40)
        Column() {
          Row() {
            Text(comment.author)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(this.formatTime(comment.createTime))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ left: 8 })
          }

          Text(comment.content)
            .fontSize(14)
            .fontColor('#333333')
            .lineHeight(22)
            .width('100%')
            .margin({ top: 4 })

          Row() {
            Row() {
              AppIcon({ name: 'community_comment', iconSize: 14 })
                .opacity(0.7)
            }
            .width(30)
            .height(30)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#f8f9fa')
            .borderRadius(15)
            .margin({ right: 8 })
            .onClick(() => {
              this.setReplyTarget(comment);
            })

            if (this.canDelete(comment)) {
              Row() {
                AppIcon({ name: 'community_trash', iconSize: 14 })
                  .opacity(0.7)
              }
              .width(30)
              .height(30)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#fff5f5')
              .borderRadius(15)
              .onClick(() => {
                this.openDeleteComment(comment);
              })
            }
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (comment.replyCount > 0 && !comment.showReplies) {
        Text('查看回复')
          .fontSize(13)
          .fontColor('#6e8efb')
          .margin({ left: 50, top: 8, bottom: 8 })
          .onClick(() => {
            this.loadReplies(comment, false);
          })
      }

      if (comment.showReplies) {
        Column() {
          if (this.loadingRepliesId === comment.id && comment.replyList.length === 0) {
            Skeleton({ rows: 1, showAvatar: true })
          } else {
            ForEach(comment.replyList, (reply: PostComment) => {
              this.ReplyItem(comment, reply)
            }, (reply: PostComment) => reply.id)
            if (comment.replyList.length >= 5 && comment.replyHasMore) {
              Text('加载更多回复')
                .fontSize(12)
                .fontColor('#6e8efb')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 8, bottom: 8 })
                .onClick(() => {
                  this.loadReplies(comment, true);
                })
            }
          }
        }
        .width('100%')
        .padding({ left: 10 })
        .margin({ left: 20, top: 8 })
        .border({ width: { left: 2 }, color: '#f0f0f0' })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 1 })
    .margin({ bottom: 8 })
  }

  @Builder CommentInput() {
    Column() {
      if (this.replyTargetId.length > 0) {
        Row() {
          Text(`回复 ${this.replyTargetName}: ${this.replyTargetContent}`)
            .fontSize(13)
            .fontColor('#6c757d')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('×')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#6c757d')
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .backgroundColor('#dee2e6')
            .borderRadius(10)
            .margin({ left: 8 })
            .onClick(() => {
              this.cancelReply();
            })
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#f8f9fa')
        .borderRadius(4)
        .margin({ bottom: 8 })
      }

      Row() {
        TextInput({
          text: this.commentText,
          placeholder: this.replyTargetId.length > 0 ? '回复评论...' : '写下你的评论...'
        })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .fontColor('#333333')
          .placeholderColor('#808080')
          .maxLength(200)
          .padding({ left: 12, right: 12 })
          .borderRadius(20)
          .backgroundColor('#f8f9fa')
          .border({ width: 1, color: '#e9ecef' })
          .onChange((value: string) => {
            this.commentText = value;
          })

        if (this.commentText.trim().length > 0) {
          Text('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(40)
            .padding({ left: 16, right: 16 })
            .textAlign(TextAlign.Center)
            .borderRadius(20)
            .linearGradient({
              angle: 135,
              colors: [['#6e8efb', 0.0], ['#a777e3', 1.0]]
            })
            .margin({ left: 8 })
            .onClick(() => {
              this.submitComment();
            })
        } else {
          Text('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#adb5bd')
            .height(40)
            .padding({ left: 16, right: 16 })
            .textAlign(TextAlign.Center)
            .borderRadius(20)
            .backgroundColor('#e9ecef')
            .margin({ left: 8 })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding({ bottom: 12 })
    .margin({ bottom: 12 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        PageHeader({ title: '动态详情' })
        Refresh({ refreshing: $$this.refreshing }) {
          Scroll(this.scroller) {
            Column() {
              this.PostCard()
              this.CommentInput()

              if (this.loadingComments && this.comments.length === 0) {
                Skeleton({ rows: 3, showAvatar: true })
                  .margin({ top: 12 })
              } else if (this.commentsError.length > 0 && this.comments.length === 0) {
                EmptyState({
                  title: '加载评论失败',
                  description: '请检查网络后重试',
                  actionText: '重新加载',
                  onAction: () => {
                    this.loadFirstComments();
                  }
                })
                  .margin({ top: 12 })
              } else if (this.comments.length === 0) {
                Text('暂无评论，快来抢沙发吧！')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 20, bottom: 20 })
              } else {
                ForEach(this.comments, (comment: PostComment) => {
                  this.CommentCard(comment)
                }, (comment: PostComment) =>
                `${comment.id}-${comment.replyList.length}-${comment.replyCount}-${comment.showReplies ? 1 : 0}`)

                if (this.commentPager.hasMore) {
                  Text(this.commentPager.loading ? '加载中...' : '加载更多评论')
                    .fontSize(14)
                    .fontColor('#6c757d')
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding({ top: 10, bottom: 10 })
                    .backgroundColor('#f8f9fa')
                    .borderRadius(4)
                    .margin({ top: 8 })
                    .onClick(() => {
                      this.loadMoreComments();
                    })
                }
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 40 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .align(Alignment.TopStart)
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.onRefresh();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f8f8')

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
