import { CommunityPost, PostType } from '../models/CommunityPost';
import { ApiConfig, ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';
import { CheckApi } from './CheckApi';
import { PickedFile, UploadService } from '../services/UploadService';
import { LogUtil } from '../utils/LogUtil';

class CommunityPostResponse {
  id: string | number = '';
  typeId: string | number = '';
  type: string = '';
  username: string = '';
  author: string = '';
  title: string = '';
  content: string = '';
  imageUrl: string = '';
  imgList: string[] = [];
  imgIdList: string[] = [];
  likeCount: number | string = 0;
  commentCount: number | string = 0;
  viewCount: number | string = 0;
  liked: boolean = false;
  isLike: number | string | boolean = 0;
  createTime: string = '';
  publishTime: string = '';
}

class LikePostPayload {
  id: string = '';
  like: boolean = false;

  constructor(id: string, like: boolean) {
    this.id = id;
    this.like = like;
  }
}

export class PostComment {
  id: string;
  author: string;
  content: string;
  createTime: string;
  uid: string;
  avatarId: string;
  replyCount: number;
  replyList: PostComment[];
  replyCursor: string;
  replyHasMore: boolean;
  showReplies: boolean;

  constructor(id: string = '', author: string = '', content: string = '', createTime: string = '', uid: string = '',
    avatarId: string = '', replyCount: number = 0) {
    this.id = id;
    this.author = author;
    this.content = content;
    this.createTime = createTime;
    this.uid = uid;
    this.avatarId = avatarId;
    this.replyCount = replyCount;
    this.replyList = [];
    this.replyCursor = '';
    this.replyHasMore = false;
    this.showReplies = false;
  }
}

class CommentResponse {
  id: string | number = '';
  username: string = '';
  author: string = '';
  content: string = '';
  createTime: string = '';
  uid: string | number = '';
  avatarId: string | number = '';
  avaterId: string | number = '';
  replyCount: number | string = 0;
}

class CommentPayload {
  id: string = '';
  content: string = '';

  constructor(id: string, content: string) {
    this.id = id;
    this.content = content;
  }
}

class PreparePostPayload {
  title: string = '';
  content: string = '';
  type: string = '';
  imgCount: number = 0;

  constructor(title: string, content: string, type: string = '好物推荐', imgCount: number = 0) {
    this.title = title;
    this.content = content;
    this.type = type;
    this.imgCount = imgCount;
  }
}

/** prepare-post 为每张待上传图片分配的 id 与直传 URL。 */
export class PrepareImageItem {
  id: string = '';
  url: string = '';
}

class PreparePostResponse {
  // 后端社区 id 为数字（如 194），统一按 string | number 接收后再转字符串。
  id: string | number = '';
  communityId: string | number = '';
  communityImageList: PrepareImageItem[] | null = [];
}

class PostIdPayload {
  id: string = '';

  constructor(id: string) {
    this.id = id;
  }
}

export class CommunityApi {
  private static safeText(value: string | number | boolean | null): string {
    return value ? `${value}` : '';
  }

  private static safeNumber(value: number | string | null): number {
    if (!value) {
      return 0;
    }
    const parsed = Number(value);
    if (parsed >= 0 || parsed < 0) {
      return parsed;
    }
    return 0;
  }

  private static safeLike(value: number | string | boolean | null): boolean {
    return value === true || value === 1 || value === '1' || value === 'true';
  }

  private static normalizeImageUrl(value: string, apiEnvironment: string): string {
    const imageUrl = value.trim();
    if (imageUrl.length === 0) {
      return '';
    }
    if (imageUrl.indexOf('http://') === 0 || imageUrl.indexOf('https://') === 0 || imageUrl.indexOf('data:') === 0) {
      return imageUrl;
    }
    if (imageUrl.indexOf('//') === 0) {
      return `https:${imageUrl}`;
    }
    const baseUrl = ApiConfig.currentBaseUrl(apiEnvironment);
    if (imageUrl.indexOf('/') === 0) {
      return `${baseUrl}${imageUrl}`;
    }
    return `${baseUrl}/${imageUrl}`;
  }

  private static firstImageUrl(post: CommunityPostResponse, apiEnvironment: string): string {
    const directUrl = CommunityApi.normalizeImageUrl(CommunityApi.safeText(post.imageUrl), apiEnvironment);
    if (directUrl.length > 0) {
      return directUrl;
    }
    if (post.imgList && post.imgList.length > 0) {
      for (let index = 0; index < post.imgList.length; index++) {
        const imageUrl = CommunityApi.normalizeImageUrl(CommunityApi.safeText(post.imgList[index]), apiEnvironment);
        if (imageUrl.length > 0) {
          return imageUrl;
        }
      }
    }
    return '';
  }

  private static normalizePost(post: CommunityPostResponse, apiEnvironment: string): CommunityPost {
    const id = CommunityApi.safeText(post.id);
    const typeId = CommunityApi.safeText(post.typeId).length > 0 ? CommunityApi.safeText(post.typeId) : CommunityApi.safeText(post.type);
    const author = CommunityApi.safeText(post.author).length > 0 ? CommunityApi.safeText(post.author) : CommunityApi.safeText(post.username);
    const imageUrl = CommunityApi.firstImageUrl(post, apiEnvironment);
    const publishTime = CommunityApi.safeText(post.publishTime).length > 0 ? CommunityApi.safeText(post.publishTime) : CommunityApi.safeText(post.createTime);
    const imgCount = post.imgList ? post.imgList.length : 0;
    LogUtil.info('community-map', `id=${id} title=${post.title} imgCount=${imgCount} imageUrl=${imageUrl}`);
    if (imageUrl.length === 0) {
      LogUtil.warn('community-map', `missing image id=${id} title=${post.title} rawImageUrl=${post.imageUrl}`);
    }
    const normalized = new CommunityPost(
      id,
      typeId,
      author,
      CommunityApi.safeText(post.title),
      CommunityApi.safeText(post.content),
      imageUrl,
      CommunityApi.safeNumber(post.likeCount),
      post.liked || CommunityApi.safeLike(post.isLike),
      publishTime
    );
    normalized.commentCount = CommunityApi.safeNumber(post.commentCount);
    normalized.viewCount = CommunityApi.safeNumber(post.viewCount);
    normalized.isLike = CommunityApi.safeLike(post.isLike) ? 1 : 0;
    normalized.imgList = post.imgList ? post.imgList : [];
    normalized.imgIdList = post.imgIdList ? post.imgIdList : [];
    return normalized;
  }

  private static normalizePosts(posts: CommunityPostResponse[], apiEnvironment: string): CommunityPost[] {
    const normalizedPosts: CommunityPost[] = [];
    posts.forEach((post: CommunityPostResponse) => {
      normalizedPosts.push(CommunityApi.normalizePost(post, apiEnvironment));
    });
    return normalizedPosts;
  }

  static async types(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PostType[]> {
    const result = await HttpClient.get<PostType[]>('/community/postTypes', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  private static cursorQuery(lastId: string): string {
    return lastId.length > 0 ? `?lastPostId=${encodeURIComponent(lastId)}` : '';
  }

  /** 推荐动态；lastPostId 为空取第一页。 */
  static async recommend(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION,
    lastPostId: string = ''): Promise<CommunityPost[]> {
    const result = await HttpClient.get<CommunityPostResponse[]>(
      `/community/recommend-post${CommunityApi.cursorQuery(lastPostId)}`, token, apiEnvironment);
    const posts = result.data === null ? [] : result.data;
    LogUtil.info('community-api', `recommend raw count=${posts.length} cursor=${lastPostId} env=${apiEnvironment}`);
    return CommunityApi.normalizePosts(posts, apiEnvironment);
  }

  /** 我的动态；lastPostId 为空取第一页。 */
  static async selfPosts(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION,
    lastPostId: string = ''): Promise<CommunityPost[]> {
    const result = await HttpClient.get<CommunityPostResponse[]>(
      `/community/self-post${CommunityApi.cursorQuery(lastPostId)}`, token, apiEnvironment);
    const posts = result.data === null ? [] : result.data;
    LogUtil.info('community-api', `self raw count=${posts.length} cursor=${lastPostId} env=${apiEnvironment}`);
    return CommunityApi.normalizePosts(posts, apiEnvironment);
  }

  static async detail(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<CommunityPost | null> {
    const result = await HttpClient.get<CommunityPostResponse>(`/community/post?id=${id}`, token, apiEnvironment);
    return result.data === null ? null : CommunityApi.normalizePost(result.data, apiEnvironment);
  }

  /** 一级评论；lastCommentId 为空取第一页（与小程序 api/community.js 一致）。 */
  /** 后端评论字段为 username/avaterId，这里统一映射为页面使用的 author/avatarId。 */
  private static normalizeComment(raw: CommentResponse): PostComment {
    const author = raw.username.length > 0 ? raw.username : raw.author;
    const avatarId = CommunityApi.safeText(raw.avatarId).length > 0
      ? CommunityApi.safeText(raw.avatarId) : CommunityApi.safeText(raw.avaterId);
    return new PostComment(
      CommunityApi.safeText(raw.id),
      author,
      raw.content,
      raw.createTime,
      CommunityApi.safeText(raw.uid),
      avatarId,
      CommunityApi.safeNumber(raw.replyCount)
    );
  }

  private static normalizeComments(rawComments: CommentResponse[] | null): PostComment[] {
    const comments: PostComment[] = [];
    if (rawComments === null) {
      return comments;
    }
    rawComments.forEach((raw: CommentResponse) => {
      comments.push(CommunityApi.normalizeComment(raw));
    });
    return comments;
  }

  static async comments(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION,
    lastCommentId: string = ''): Promise<PostComment[]> {
    const cursor = lastCommentId.length > 0 ? `&lastCommentId=${encodeURIComponent(lastCommentId)}` : '';
    const result = await HttpClient.get<CommentResponse[]>(
      `/community/post-comment?id=${encodeURIComponent(id)}${cursor}`, token, apiEnvironment);
    return CommunityApi.normalizeComments(result.data);
  }

  static async replies(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION,
    lastCommentId: string = ''): Promise<PostComment[]> {
    const cursor = lastCommentId.length > 0 ? `&lastCommentId=${encodeURIComponent(lastCommentId)}` : '';
    const result = await HttpClient.get<CommentResponse[]>(
      `/community/post-comment-reply?id=${encodeURIComponent(id)}${cursor}`, token, apiEnvironment);
    return CommunityApi.normalizeComments(result.data);
  }

  /** 返回后端生成的评论 id（用于本地插入后立即支持删除，与小程序一致）。 */
  static async addComment(token: string, postId: string, content: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<string> {
    // 与小程序 api/community.js 一致：先检查文本，未通过则不发评论。
    const check = await CheckApi.checkText(token, new CommentPayload(postId, content), apiEnvironment);
    if (!check.passed) {
      throw new Error(check.message);
    }
    const result = await HttpClient.post<string | number>('/community/post-comment', token,
      new CommentPayload(postId, content), apiEnvironment);
    return result.data === null ? '' : `${result.data}`;
  }

  static async addReply(token: string, commentId: string, content: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<string> {
    const check = await CheckApi.checkText(token, new CommentPayload(commentId, content), apiEnvironment);
    if (!check.passed) {
      throw new Error(check.message);
    }
    const result = await HttpClient.post<string | number>('/community/post-comment-reply', token,
      new CommentPayload(commentId, content), apiEnvironment);
    return result.data === null ? '' : `${result.data}`;
  }

  static async deleteComment(token: string, commentId: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.delete<ApiEmptyResponse>('/community/post-comment', token,
      new PostIdPayload(commentId), apiEnvironment);
  }

  static async deleteReply(token: string, replyId: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.delete<ApiEmptyResponse>('/community/post-comment-reply', token,
      new PostIdPayload(replyId), apiEnvironment);
  }

  /** prepare-post：创建草稿，并拿到 communityId 与每张图片的上传 URL/id。 */
  static async preparePost(token: string, title: string, content: string, type: string, imgCount: number,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PreparePostResponse> {
    const payload = new PreparePostPayload(title, content, type, imgCount);
    const check = await CheckApi.checkText(token, payload, apiEnvironment);
    if (!check.passed) {
      throw new Error(check.message);
    }
    const result = await HttpClient.post<PreparePostResponse>('/community/prepare-post', token, payload, apiEnvironment);
    if (result.data === null) {
      throw new Error('后端未返回待发布动态');
    }
    return result.data;
  }

  /** 标记单张图片上传完成。 */
  static async markImageUploaded(token: string, imageId: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/img-uploaded', token, new PostIdPayload(imageId), apiEnvironment);
  }

  /** finalize-post：草稿转正式动态。 */
  static async finalizePost(token: string, postId: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/finalize-post', token, new PostIdPayload(postId), apiEnvironment);
  }

  private static communityIdOf(prepare: PreparePostResponse): string {
    const communityId = CommunityApi.safeText(prepare.communityId);
    if (communityId.length > 0) {
      return communityId;
    }
    return CommunityApi.safeText(prepare.id);
  }

  static async publishText(token: string, title: string, content: string, type: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    const prepare = await CommunityApi.preparePost(token, title, content, type, 0, apiEnvironment);
    const postId = CommunityApi.communityIdOf(prepare);
    if (postId.length === 0) {
      throw new Error('后端未返回待发布动态 id');
    }
    await CommunityApi.finalizePost(token, postId, apiEnvironment);
  }

  /**
   * 图片动态发布：文本检查 → prepare-post → 图片检查 → PUT 直传 → img-uploaded → finalize-post。
   * 与小程序 store/modules/community.js 的 publish_post_with_image 流程一致。
   */
  static async publishWithImages(token: string, title: string, content: string, type: string,
    images: PickedFile[], apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    const prepare = await CommunityApi.preparePost(token, title, content, type, images.length, apiEnvironment);
    const postId = CommunityApi.communityIdOf(prepare);
    if (postId.length === 0) {
      throw new Error('后端未返回待发布动态 id');
    }
    const targets = prepare.communityImageList === null ? [] : prepare.communityImageList;
    if (targets.length < images.length) {
      throw new Error('上传凭证数量不足，请稍后重试');
    }
    for (let index = 0; index < images.length; index++) {
      const image = images[index];
      const check = await CheckApi.checkImg(token, image.base64(), image.mimeType, apiEnvironment);
      if (!check.passed) {
        throw new Error(`第 ${index + 1} 张图片：${check.message}`);
      }
      await UploadService.uploadToUrl(targets[index].url, token, image, apiEnvironment);
      await CommunityApi.markImageUploaded(token, targets[index].id, apiEnvironment);
    }
    await CommunityApi.finalizePost(token, postId, apiEnvironment);
  }

  /** 删除自己的动态（小程序 api/user.js deletePost）。 */
  static async deletePost(token: string, id: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.delete<ApiEmptyResponse>('/community/post', token, new PostIdPayload(id), apiEnvironment);
  }

  static async like(token: string, id: string, like: boolean, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/like-post', token, new LikePostPayload(id, like), apiEnvironment);
  }
}
