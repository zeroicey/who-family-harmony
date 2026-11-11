import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppIcon } from '../components/AppIcon';
import { CoverImage } from '../components/common/CoverImage';
import { CommunityPost } from '../models/CommunityPost';
import { RouteParams } from '../models/MiniProgramModels';
import { CommunityApi, PostComment } from '../api/CommunityApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
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

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : await CacheStore.getString(this.context, 'lastPostId', 'post-1');
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const detail = await CommunityApi.detail(token, id, env);
      if (detail !== null) {
        this.post = detail;
      }
      this.comments = await CommunityApi.comments(token, id, env);
      await CacheStore.setJson<CommunityPost>(this.context, `post:${id}`, this.post);
      await CacheStore.setJson<PostComment[]>(this.context, `comments:${id}`, this.comments);
    } catch (_) {
      const fallback = MockData.posts().find((item: CommunityPost) => item.id === id) || MockData.posts()[0];
      this.post = await CacheStore.getJson<CommunityPost>(this.context, `post:${id}`, fallback);
      this.comments = await CacheStore.getJson<PostComment[]>(this.context, `comments:${id}`, [
        new PostComment('comment-1', '校园助手', '这里可以继续补充你的看法。', '刚刚')
      ]);
    }
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
      await CommunityApi.addComment(token, this.post.id, text, env);
      ToastUtil.show('评论成功');
    } catch (err) {
      ToastUtil.show(`评论失败：${(err as Error).message}`);
    }
    this.comments = [new PostComment(`local-${new Date().getTime()}`, '我', text, '刚刚')].concat(this.comments);
    this.commentText = '';
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
      Text('回复')
        .fontSize(12)
        .fontColor('#2979FF')
        .margin({ top: 10 })
        .onClick(() => {
          this.addReply(comment);
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ top: 10 })
  }

  build() {
    Column() {
      PageHeader({ title: '动态详情' })
      Scroll() {
        Column() {
          this.PostCard()
          this.CommentBox()
          ForEach(this.comments, (comment: PostComment) => {
            this.CommentCard(comment)
          }, (comment: PostComment) => comment.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}
