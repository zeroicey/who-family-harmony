export class PostType {
  id: string;
  name: string;

  constructor(id: string = '', name: string = '') {
    this.id = id;
    this.name = name;
  }
}

export class CommunityPost {
  id: string;
  typeId: string;
  author: string;
  title: string;
  content: string;
  imageUrl: string;
  likeCount: number;
  liked: boolean;
  publishTime: string;
  commentCount: number;
  viewCount: number;
  isLike: number;
  imgList: string[];
  imgIdList: string[];

  constructor(
    id: string = '',
    typeId: string = '',
    author: string = '',
    title: string = '',
    content: string = '',
    imageUrl: string = '',
    likeCount: number = 0,
    liked: boolean = false,
    publishTime: string = ''
  ) {
    this.id = id;
    this.typeId = typeId;
    this.author = author;
    this.title = title;
    this.content = content;
    this.imageUrl = imageUrl;
    this.likeCount = likeCount;
    this.liked = liked;
    this.publishTime = publishTime;
    this.commentCount = 0;
    this.viewCount = 0;
    this.isLike = liked ? 1 : 0;
    this.imgList = imageUrl.length > 0 ? [imageUrl] : [];
    this.imgIdList = [];
  }
}
