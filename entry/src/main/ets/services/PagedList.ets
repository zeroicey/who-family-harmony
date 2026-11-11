/**
 * 统一分页模式：下拉刷新 + 上拉加载更多 + 到底提示 + 回到顶部。
 *
 * 用法（页面）：
 *   private pager: PagedListController<CommunityPost> =
 *     new PagedListController<CommunityPost>((cursor: string) => CommunityApi.recommendPosts(...));
 *
 *   aboutToAppear() { this.pager.refresh(); }
 *   onReachEnd() { this.pager.loadMore(); }
 *   List({ scroller: this.scroller }) { ... }
 *     .onScrollIndex((start) => { this.showBackToTop = start > 3; })
 *   // 底部：
 *   Text(this.pager.footerText())
 *   // 下拉刷新：Refresh({ refreshing: $$this.refreshing }) 或手动调用 pager.refresh()
 *
 * 后端分页游标：社区 lastPostId、评论 lastCommentId、招聘 lastId。
 */

/** 单页结果。nextCursor 为空表示无法继续翻页。 */
export class PageResult<T> {
  items: T[] = [];
  nextCursor: string = '';
  hasMore: boolean = false;

  constructor(items: T[], nextCursor: string, hasMore: boolean) {
    this.items = items;
    this.nextCursor = nextCursor;
    this.hasMore = hasMore;
  }
}

export type PageLoader<T> = (cursor: string) => Promise<PageResult<T>>;

export class PagedListController<T> {
  items: T[] = [];
  cursor: string = '';
  hasMore: boolean = true;
  loading: boolean = false;
  refreshing: boolean = false;
  error: string = '';
  private loader: PageLoader<T>;

  constructor(loader: PageLoader<T>) {
    this.loader = loader;
  }

  /** 清空并重新请求第一页。 */
  async refresh(): Promise<void> {
    if (this.refreshing) {
      return;
    }
    this.refreshing = true;
    this.error = '';
    try {
      const page = await (this.loader('') as Promise<PageResult<T>>);
      this.items = page.items;
      this.cursor = page.nextCursor;
      this.hasMore = page.hasMore;
    } catch (err) {
      this.error = (err as Error).message;
    } finally {
      this.refreshing = false;
      this.loading = false;
    }
  }

  /** 加载下一页；无更多、正在加载或刷新中时自动忽略。 */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.loading || this.refreshing) {
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      const page = await (this.loader(this.cursor) as Promise<PageResult<T>>);
      this.items = this.items.concat(page.items);
      this.cursor = page.nextCursor;
      this.hasMore = page.hasMore;
    } catch (err) {
      this.error = (err as Error).message;
    } finally {
      this.loading = false;
    }
  }

  /** 重新加载（保留滚动位置由页面决定）。 */
  async reload(): Promise<void> {
    this.items = [];
    this.cursor = '';
    this.hasMore = true;
    await this.refresh();
  }

  /** 本轮是否已无可加载内容。 */
  isEnd(): boolean {
    return !this.hasMore;
  }

  isEmpty(): boolean {
    return !this.refreshing && !this.loading && this.items.length === 0;
  }

  /** 列表底部提示文案（与小程序一致）。 */
  footerText(): string {
    if (this.loading) {
      return '加载中...';
    }
    if (this.hasMore) {
      return this.items.length > 0 ? '上拉加载更多' : '';
    }
    return this.items.length > 0 ? '没有更多数据了' : '';
  }
}

/** 回到顶部：Scroller 需绑定到 List/Scroll。 */
export class ScrollToTop {
  static toTop(scroller: Scroller): void {
    try {
      scroller.scrollEdge(Edge.Top);
    } catch (err) {
      // 未绑定滚动容器时忽略
    }
  }
}