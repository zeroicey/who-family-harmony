import { CommunityPost, PostType } from '../models/CommunityPost';
import { ApiConfig, ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';
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

  constructor(id: string = '', author: string = '', content: string = '', createTime: string = '') {
    this.id = id;
    this.author = author;
    this.content = content;
    this.createTime = createTime;
  }
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

  constructor(title: string, content: string, type: string = '好物推荐') {
    this.title = title;
    this.content = content;
    this.type = type;
    this.imgCount = 0;
  }
}

class PreparePostResponse {
  id: string = '';
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

  static async recommend(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<CommunityPost[]> {
    const result = await HttpClient.get<CommunityPostResponse[]>('/community/recommend-post', token, apiEnvironment);
    const posts = result.data === null ? [] : result.data;
    LogUtil.info('community-api', `recommend raw count=${posts.length} env=${apiEnvironment}`);
    return CommunityApi.normalizePosts(posts, apiEnvironment);
  }

  static async selfPosts(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<CommunityPost[]> {
    const result = await HttpClient.get<CommunityPostResponse[]>('/community/self-post', token, apiEnvironment);
    const posts = result.data === null ? [] : result.data;
    LogUtil.info('community-api', `self raw count=${posts.length} env=${apiEnvironment}`);
    return CommunityApi.normalizePosts(posts, apiEnvironment);
  }

  static async detail(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<CommunityPost | null> {
    const result = await HttpClient.get<CommunityPostResponse>(`/community/post?id=${id}`, token, apiEnvironment);
    return result.data === null ? null : CommunityApi.normalizePost(result.data, apiEnvironment);
  }

  static async comments(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PostComment[]> {
    const result = await HttpClient.get<PostComment[]>(`/community/post-comment?id=${id}`, token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async replies(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PostComment[]> {
    const result = await HttpClient.get<PostComment[]>(`/community/post-comment-reply?id=${id}`, token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async addComment(token: string, postId: string, content: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/post-comment', token, new CommentPayload(postId, content), apiEnvironment);
  }

  static async addReply(token: string, commentId: string, content: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/post-comment-reply', token, new CommentPayload(commentId, content), apiEnvironment);
  }

  static async publishText(token: string, title: string, content: string, type: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    const prepare = await HttpClient.post<PreparePostResponse>('/community/prepare-post', token, new PreparePostPayload(title, content, type), apiEnvironment);
    if (prepare.data !== null && prepare.data.id) {
      await HttpClient.post<ApiEmptyResponse>('/community/finalize-post', token, new PostIdPayload(prepare.data.id), apiEnvironment);
      return;
    }
    throw new Error('后端未返回待发布动态 id');
  }

  static async like(token: string, id: string, like: boolean, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/community/like-post', token, new LikePostPayload(id, like), apiEnvironment);
  }
}
