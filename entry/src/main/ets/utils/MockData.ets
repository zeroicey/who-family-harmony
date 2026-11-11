import { Banner } from '../models/Banner';
import { StudyTask } from '../models/Task';
import { Job, JobType } from '../models/Job';
import { CommunityPost, PostType } from '../models/CommunityPost';
import { MemberWork } from '../models/UserProfile';
import { AddressItem, ChatMessage, GradeRecord, KnowledgeArticle, PresetQuestion, PrintOrder, PrintPrice, SchoolCourse } from '../models/MiniProgramModels';

export class ServiceItem {
  id: string;
  title: string;
  summary: string;
  iconText: string;
  imageUrl: string;

  constructor(id: string, title: string, summary: string, iconText: string, imageUrl: string) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.iconText = iconText;
    this.imageUrl = imageUrl;
  }
}

export class CampusPlace {
  id: string;
  title: string;
  description: string;
  route: string;

  constructor(id: string, title: string, description: string, route: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.route = route;
  }
}

export class ErrandTask {
  id: string;
  type: string;
  content: string;
  from: string;
  to: string;
  price: number;
  status: string;
  createTime: string;
  userName: string;
  avatarId: string;

  constructor(
    id: string,
    type: string,
    content: string,
    from: string,
    to: string,
    price: number,
    status: string,
    createTime: string,
    userName: string,
    avatarId: string
  ) {
    this.id = id;
    this.type = type;
    this.content = content;
    this.from = from;
    this.to = to;
    this.price = price;
    this.status = status;
    this.createTime = createTime;
    this.userName = userName;
    this.avatarId = avatarId;
  }
}

export class MockData {
  static banners(): Banner[] {
    return [
      new Banner('banner-1', '校园服务聚合', 'https://api.hcyj.xyz/images/dngg.jpg', '把资讯、任务和岗位入口放在同一个首页。'),
      new Banner('banner-2', '学习专注打卡', 'https://api.hcyj.xyz/images/dnfw.png', '记录今日专注分钟，形成稳定学习节奏。'),
      new Banner('banner-3', '校内岗位推荐', 'https://api.hcyj.xyz/images/gdfw.jpg', '浏览社团、勤工助学和实习岗位。')
    ];
  }

  static services(): ServiceItem[] {
    return [
      new ServiceItem('flow', '校园人流天气', '实时查看校园各区域人流量分布与空气质量指数。', 'tab_service', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAESETBpwP6ugYWtISs6XQ81KokrT4mBIgACnCQAAiLeCFbhCOwpzFtBizoE.png'),
      new ServiceItem('schedule', '查询课表服务', '查询当前学期课表，及时了解课程安排。', 'learn', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECPRpAZAXQl3cBfhxDxuSt1AojYoeHQAC7iAAAtCQCFQvkTsfSeUnwjYE.jpg'),
      new ServiceItem('grade', '查询成绩服务', '查询当前学期成绩，了解学习情况。', 'profile_grade', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECP5pAZDT2lKDbMs1BC1kkTo76bcj3AAC-CAAAtCQCFQGU12qYNcw8DYE.jpg'),
      new ServiceItem('print', '远程打印服务', '宿舍也能轻松打印，手机填写信息后提交订单。', 'profile_publish', 'https://api.hcyj.xyz/images/dnfw.png'),
      new ServiceItem('express', '快递代取', '展示取件点、代取说明和安全提醒。', 'me_address', 'https://api.hcyj.xyz/images/dngg.jpg')
    ];
  }

  static places(): CampusPlace[] {
    return [
      new CampusPlace('library', '图书馆', '适合自习、借阅和小组讨论，晚间人流较多。', '从教学楼出发沿中轴路向北，经过广场后右转。'),
      new CampusPlace('building', '教学楼', '主要课程和实验课集中区域，课间需要预留通行时间。', '从宿舍区出发经东侧连廊到达，雨天优先走连廊。'),
      new CampusPlace('canteen', '食堂', '午晚高峰建议错峰就餐，也可先查看校园人流提示。', '从图书馆南门出发沿主路向西，约 5 分钟到达。'),
      new CampusPlace('dorm', '宿舍区', '生活服务和快递取件入口集中在宿舍区周边。', '从食堂北门出发穿过篮球场侧路到达。')
    ];
  }

  static tasks(): StudyTask[] {
    return [
      new StudyTask('task-1', '完成 ArkTS 期末报告截图', '补充首页、我的页和水印效果截图。', '2026-06-10', '待完成'),
      new StudyTask('task-2', '整理接口联调说明', '记录 token、缓存和 mock 降级策略。', '2026-06-11', '待完成'),
      new StudyTask('task-3', '检查运行结果', '真机验证页面跳转和 Toast。', '2026-06-12', '已完成')
    ];
  }

  static jobTypes(): JobType[] {
    return [
      new JobType('all', '全部'),
      new JobType('study', '学习助理'),
      new JobType('service', '校园服务'),
      new JobType('intern', '实习实践')
    ];
  }

  static jobs(): Job[] {
    return [
      new Job('job-1', 'study', '课程助教', '软件工程学院', '教学楼 A305', '80元/次', ['ArkTS', '答疑', '课后辅导'], '协助教师整理课程资料、答疑和课堂签到。', '熟悉基础编程，沟通耐心，每周可投入 4 小时。', '获得课程实践证明和教师推荐。', 'teacher@example.edu.cn', false),
      new Job('job-2', 'service', '图书馆志愿者', '校图书馆', '图书馆二层', '志愿时长', ['整理书架', '读者服务'], '参与图书上架、阅览室秩序维护和借阅咨询。', '细心守时，熟悉图书馆基础规则。', '累计志愿服务时长，可参与优秀志愿者评选。', 'library@example.edu.cn', false),
      new Job('job-3', 'intern', '前端实习生', '互成一家校园项目组', '线上/实验室', '面议', ['ArkUI', '组件化', '接口联调'], '参与校园服务助手 HarmonyOS 页面维护。', '了解 ArkTS 或 TypeScript，能阅读接口文档。', '项目经历、作品集和团队导师反馈。', 'hcyj@example.edu.cn', false)
    ];
  }

  static postTypes(): PostType[] {
    return [
      new PostType('all', '全部'),
      new PostType('dynamic', '动态'),
      new PostType('errand', '跑腿'),
      new PostType('secondhand', '二手'),
      new PostType('rating', '评分')
    ];
  }

  static posts(): CommunityPost[] {
    return [
      new CommunityPost('post-1', 'dynamic', '梁胤佳', '有人一起去图书馆自习吗', '今晚 19:00 到 21:00 准备复习 ArkTS 页面路由和组件封装。', 'https://api.hcyj.xyz/images/dnfw.png', 16, false, '今天 18:20'),
      new CommunityPost('post-2', 'errand', '校园跑腿同学', '帮取 SOVO 快递', '取件码已准备好，宿舍区 20:00 前送达，备注楼栋即可。', 'https://api.hcyj.xyz/images/gdfw.jpg', 28, true, '今天 17:10'),
      new CommunityPost('post-3', 'secondhand', '古栋', '出一套算法资料', '动态规划、图论和面试题整理，适合期末复习和竞赛入门。', 'https://api.hcyj.xyz/images/dngg.jpg', 9, false, '昨天 21:30'),
      new CommunityPost('post-4', 'rating', '郭嘉荣', '图书馆二楼自习体验', '插座充足，空调偏冷，晚高峰座位紧张，建议 18 点前到。', 'https://api.hcyj.xyz/images/dnfw.png', 12, false, '昨天 20:05')
    ];
  }

  static errandTasks(): ErrandTask[] {
    return [
      new ErrandTask('1', '校园跑腿', '帮忙取个快递', '菜鸟驿站', 'J4 212', 5, 'pending', '2024-03-04 14:30:00', '张三', 'avatar1'),
      new ErrandTask('2', '快递代取', '京东快递，中等包裹', '京东快递点', 'J3 101', 8, 'completed', '2024-03-04 13:20:00', '李四', 'avatar2'),
      new ErrandTask('3', '东南门代拿', '取外卖，急', '东南门', '小镇1栋 321', 6, 'cancelled', '2024-03-04 12:15:00', '王五', 'avatar3'),
      new ErrandTask('4', '快递到寝', '大件包裹，帮忙送上楼', '快递站', 'J2 408', 10, 'pending', '2024-03-04 11:00:00', '赵六', 'avatar4'),
      new ErrandTask('5', '东北门代拿', '取个外卖', '东北门', 'J1 201', 5, 'completed', '2024-03-04 10:30:00', '孙七', 'avatar5'),
      new ErrandTask('6', '校园跑腿', '帮忙买份午饭', '食堂', '图书馆', 7, 'pending', '2024-03-04 09:45:00', '周八', 'avatar6'),
      new ErrandTask('7', '快递代取', '顺丰快递，小件', '顺丰快递点', 'J4 109', 6, 'pending', '2024-03-03 18:20:00', '吴九', 'avatar7'),
      new ErrandTask('8', '西门代拿', '取外卖，两份', '西门', '小镇2栋 502', 8, 'completed', '2024-03-03 17:10:00', '郑十', 'avatar8'),
      new ErrandTask('9', '快递到寝', '两个包裹，送上楼', '中通快递点', 'J3 210', 12, 'cancelled', '2024-03-03 16:00:00', '陈十一', 'avatar9'),
      new ErrandTask('10', '东南门代拿', '取快递', '东南门快递点', 'J4 318', 5, 'pending', '2024-03-03 14:30:00', '刘十二', 'avatar10'),
      new ErrandTask('11', '其他跑腿', '帮忙打印资料，30页', '打印店', '图书馆', 8, 'completed', '2024-03-03 13:15:00', '黄十三', 'avatar11'),
      new ErrandTask('12', '校园跑腿', '帮忙带瓶水', '超市', 'J2 411', 4, 'pending', '2024-03-03 11:40:00', '林十四', 'avatar12'),
      new ErrandTask('13', '快递代取', '圆通快递', '圆通快递点', '小镇3栋 205', 6, 'pending', '2024-03-02 19:20:00', '何十五', 'avatar13'),
      new ErrandTask('14', '东北门代拿', '取外卖', '东北门', 'J1 408', 5, 'completed', '2024-03-02 18:00:00', '罗十六', 'avatar14'),
      new ErrandTask('15', '快递到寝', '大件家电', '快递站', '小镇4栋 102', 15, 'pending', '2024-03-02 16:45:00', '高十七', 'avatar15')
    ];
  }

  static knowledgeTabs(): string[] {
    return ['前端', '后端', '数据库', '算法', '设计模式', '运维', '测试', '安全', '网络', '移动开发', '大数据', '人工智能', '云计算', '架构', '工具'];
  }

  static knowledgeArticles(): KnowledgeArticle[] {
    return [
      new KnowledgeArticle('k-1', '前端', 'Vue3 响应式原理', '深入理解 Vue3 的 Proxy 响应式系统，掌握 Composition API 的核心思想', '高级', ['Vue3', '响应式', 'Proxy'], '15分钟', 4500, '前端小黑', 12850, 342, '2025-03-01', [
        '深入理解 Vue3 的 Proxy 响应式系统，掌握 Composition API 的核心思想。',
        '本文整理了 Vue3 响应式原理的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-2', '前端', 'React Hooks 最佳实践', '掌握 useState、useEffect 等 Hooks 的正确使用方式，避免常见陷阱', '中级', ['React', 'Hooks', '状态管理'], '12分钟', 3800, 'React大神', 9680, 256, '2025-02-28', [
        '掌握 useState、useEffect 等 Hooks 的正确使用方式，避免常见陷阱。',
        '本文整理了 React Hooks 最佳实践的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-3', '前端', 'Webpack 打包优化', '学习 Webpack 性能优化技巧，提升构建速度和减小包体积', '高级', ['Webpack', '性能优化', '构建工具'], '20分钟', 6200, '性能优化专家', 7540, 189, '2025-02-25', [
        '学习 Webpack 性能优化技巧，提升构建速度和减小包体积。',
        '本文整理了 Webpack 打包优化的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-4', '前端', '小程序开发要点', 'uni-app 跨平台开发实战，微信小程序 API 使用技巧', '初级', ['小程序', 'uni-app', '跨平台'], '10分钟', 3200, 'UniApp布道者', 15230, 467, '2025-03-02', [
        'uni-app 跨平台开发实战，微信小程序 API 使用技巧。',
        '本文整理了小程序开发要点的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-5', '后端', 'Spring Boot 实战', '从零搭建 Spring Boot 项目，RESTful API 设计与实现', '中级', ['Spring Boot', 'Java', 'RESTful'], '18分钟', 5600, 'Java架构师', 8920, 234, '2025-02-20', [
        '从零搭建 Spring Boot 项目，RESTful API 设计与实现。',
        '本文整理了 Spring Boot 实战的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-6', '后端', 'Node.js 异步编程', '深入理解 Event Loop，掌握 Promise、async/await 的使用', '中级', ['Node.js', '异步', 'Event Loop'], '14分钟', 4200, 'Node极客', 11340, 312, '2025-02-18', [
        '深入理解 Event Loop，掌握 Promise、async/await 的使用。',
        '本文整理了 Node.js 异步编程的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-7', '后端', '微服务架构设计', '微服务拆分原则，服务间通信，分布式事务处理', '高级', ['微服务', '分布式', '架构'], '25分钟', 7800, '架构之道', 6580, 178, '2025-02-15', [
        '微服务拆分原则，服务间通信，分布式事务处理。',
        '本文整理了微服务架构设计的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-8', '数据库', 'MySQL 索引优化', '深入理解 B+ 树索引结构，掌握索引优化技巧', '中级', ['MySQL', '索引', '性能优化'], '16分钟', 5100, 'DBA老张', 13670, 389, '2025-02-22', [
        '深入理解 B+ 树索引结构，掌握索引优化技巧。',
        '本文整理了 MySQL 索引优化的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-9', '数据库', 'Redis 缓存设计', 'Redis 数据类型选择，缓存策略，防止缓存穿透和雪崩', '高级', ['Redis', '缓存', '分布式'], '20分钟', 6400, 'Redis达人', 9830, 278, '2025-02-19', [
        'Redis 数据类型选择，缓存策略，防止缓存穿透和雪崩。',
        '本文整理了 Redis 缓存设计的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-10', '数据库', 'MongoDB 最佳实践', 'NoSQL 数据库设计模式，聚合查询优化', '中级', ['MongoDB', 'NoSQL', '文档数据库'], '15分钟', 4900, 'NoSQL爱好者', 7250, 198, '2025-02-16', [
        'NoSQL 数据库设计模式，聚合查询优化。',
        '本文整理了 MongoDB 最佳实践的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-11', '算法', '动态规划经典题', '掌握动态规划思想，刷透 LeetCode 经典 DP 问题', '高级', ['动态规划', 'LeetCode', '算法'], '30分钟', 9200, 'LeetCode高手', 18450, 567, '2025-02-28', [
        '动态规划的核心是把大问题拆成可以复用的小问题，并用状态转移方程描述它们之间的关系。',
        '解题时先定义 dp[i] 的含义，再确认初始化、转移方程和遍历顺序。',
        '常见题型包括爬楼梯、最长递增子序列、最长公共子序列和 0-1 背包。'
      ], true),
      new KnowledgeArticle('k-12', '算法', '二叉树遍历', '前序、中序、后序遍历的递归与非递归实现', '初级', ['二叉树', '遍历', '递归'], '12分钟', 3800, '算法小白', 21340, 645, '2025-03-03', [
        '前序、中序、后序遍历的递归与非递归实现。',
        '本文整理了二叉树遍历的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-13', '算法', '图论算法入门', 'BFS 和 DFS 算法，最短路径问题解决方案', '中级', ['图论', 'BFS', 'DFS'], '22分钟', 6800, '图论专家', 10920, 312, '2025-02-24', [
        'BFS 和 DFS 算法，最短路径问题解决方案。',
        '本文整理了图论算法入门的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-20', '算法', '快速排序与归并排序', '深入理解分治思想，掌握经典排序算法的实现与优化', '中级', ['排序算法', '分治', '快速排序'], '18分钟', 5600, '排序大师', 15670, 423, '2025-03-01', [
        '深入理解分治思想，掌握经典排序算法的实现与优化。',
        '本文整理了快速排序与归并排序的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-21', '算法', '二分查找及其变种', '掌握二分查找的标准写法，理解边界条件处理', '初级', ['搜索', '二分查找', '数组'], '14分钟', 4200, '搜索达人', 18930, 512, '2025-02-27', [
        '掌握二分查找的标准写法，理解边界条件处理。',
        '本文整理了二分查找及其变种的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-22', '算法', '贪心算法实战', '贪心算法的设计思想与经典应用场景解析', '中级', ['贪心', '算法思想', 'LeetCode'], '20分钟', 6300, '贪心策略', 9450, 267, '2025-02-20', [
        '贪心算法的设计思想与经典应用场景解析。',
        '本文整理了贪心算法实战的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-23', '算法', '回溯算法解题模板', '掌握回溯算法核心框架，解决排列组合与子集问题', '高级', ['回溯', 'DFS', '排列组合'], '25分钟', 7800, '回溯专家', 11280, 345, '2025-02-18', [
        '掌握回溯算法核心框架，解决排列组合与子集问题。',
        '本文整理了回溯算法解题模板的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-24', '算法', '滑动窗口技巧', '滑动窗口解决子串、子数组问题的通用方法', '中级', ['滑动窗口', '双指针', '字符串'], '16分钟', 4900, '窗口侠', 13450, 389, '2025-02-23', [
        '滑动窗口解决子串、子数组问题的通用方法。',
        '本文整理了滑动窗口技巧的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-25', '算法', '链表高频题汇总', '反转链表、环形链表、链表相交等经典题型', '初级', ['链表', '数据结构', '指针'], '15分钟', 4600, '链表杀手', 20150, 587, '2025-03-02', [
        '反转链表、环形链表、链表相交等经典题型。',
        '本文整理了链表高频题汇总的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-26', '算法', '哈希表应用技巧', '利用哈希表优化查找和去重操作的时间复杂度', '中级', ['哈希表', '查找', '优化'], '13分钟', 4000, '哈希达人', 14320, 412, '2025-02-25', [
        '利用哈希表优化查找和去重操作的时间复杂度。',
        '本文整理了哈希表应用技巧的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-27', '算法', '栈与队列经典应用', '单调栈、括号匹配、表达式求值等实际问题', '中级', ['栈', '队列', '数据结构'], '17分钟', 5300, '栈队精通', 11760, 334, '2025-02-21', [
        '单调栈、括号匹配、表达式求值等实际问题。',
        '本文整理了栈与队列经典应用的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-28', '算法', '字符串处理技巧', 'KMP算法、正则表达式、字符串常用操作总结', '高级', ['字符串', 'KMP', '模式匹配'], '22分钟', 6900, '字符串专家', 8940, 256, '2025-02-19', [
        'KMP算法、正则表达式、字符串常用操作总结。',
        '本文整理了字符串处理技巧的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-14', '设计模式', '单例模式的多种实现', '饿汉式、懒汉式、双重检查锁等单例模式实现方式', '初级', ['单例模式', '创建型', '设计模式'], '10分钟', 3100, '设计模式爱好者', 14230, 423, '2025-02-27', [
        '饿汉式、懒汉式、双重检查锁等单例模式实现方式。',
        '本文整理了单例模式的多种实现的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-15', '设计模式', '观察者模式应用', '发布-订阅模式在 Vue 和 React 中的实际应用', '中级', ['观察者模式', '行为型', '响应式'], '15分钟', 4700, '设计模式精通', 11890, 334, '2025-02-23', [
        '发布-订阅模式在 Vue 和 React 中的实际应用。',
        '本文整理了观察者模式应用的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-16', '设计模式', '工厂模式实战', '简单工厂、工厂方法、抽象工厂的使用场景', '中级', ['工厂模式', '创建型', 'OOP'], '18分钟', 5400, 'OOP实践者', 9670, 276, '2025-02-21', [
        '简单工厂、工厂方法、抽象工厂的使用场景。',
        '本文整理了工厂模式实战的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ]),
      new KnowledgeArticle('k-17', '运维', 'Docker 容器化部署', 'Docker 基础命令，Dockerfile 编写，容器编排', '中级', ['Docker', '容器化', 'DevOps'], '20分钟', 6100, 'Docker达人', 13450, 387, '2025-02-26', [
        'Docker 基础命令，Dockerfile 编写，容器编排。',
        '本文整理了 Docker 容器化部署的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-18', '运维', 'Linux 常用命令', '文件操作、进程管理、网络排查等必备命令', '初级', ['Linux', 'Shell', '命令行'], '15分钟', 4600, 'Linux老司机', 24560, 723, '2025-03-04', [
        '文件操作、进程管理、网络排查等必备命令。',
        '本文整理了 Linux 常用命令的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ], true),
      new KnowledgeArticle('k-19', '运维', 'Nginx 配置优化', '反向代理、负载均衡、缓存配置与性能优化', '高级', ['Nginx', 'Web服务器', '负载均衡'], '25分钟', 7600, '运维专家', 8790, 245, '2025-02-17', [
        '反向代理、负载均衡、缓存配置与性能优化。',
        '本文整理了 Nginx 配置优化的核心知识点、实践步骤和校园学习场景中的应用建议。',
        '建议结合示例代码、课堂项目或社团实践反复练习，形成自己的知识清单。'
      ])
    ];
  }

  static presetQuestions(): PresetQuestion[] {
    return [
      new PresetQuestion('q-1', '💙 如何克服想家情绪？', '刚上大学总是想家，晚上经常想哭，怎么调节这种情绪？有什么好的方法适应大学生活吗？'),
      new PresetQuestion('q-2', '🤝 怎样和室友友好相处？', '和室友生活习惯不同，有时会有小摩擦，怎么处理室友关系？如何建立良好的宿舍氛围？'),
      new PresetQuestion('q-3', '😔 不想上学怎么办？', '最近对学习失去兴趣，不想去上课，感觉很迷茫，这种状态该如何调整？'),
      new PresetQuestion('q-4', '👥 如何交到真心朋友？', '在大学里感觉很孤单，不知道怎么交朋友，怎样才能找到志同道合的人？'),
      new PresetQuestion('q-5', '📱 如何控制手机依赖？', '总是忍不住刷手机，影响学习和睡眠，怎么戒掉手机瘾，提高自控力？'),
      new PresetQuestion('q-6', '⚖️ 怎样平衡学习和社交？', '想要好好学习，但也想参加社团活动交朋友，如何在学业和社交之间找到平衡？')
    ];
  }

  static initialMessages(): ChatMessage[] {
    return [
      new ChatMessage('ai-welcome', 'ai', '👋 你好！我是校园AI助手，很高兴为你服务！\n\n我可以帮助你解决各种校园生活问题，比如：\n\n• 📚 学习相关问题\n\n• 🏫 校园生活指导\n\n• 📋 各类手续办理\n\n• 🎯 社团活动咨询\n\n• 💡 生活小贴士\n\n有什么问题尽管问我吧～')
    ];
  }

  static addresses(): AddressItem[] {
    return [
      new AddressItem('addr-1', '互成一家用户', '13800000000', '广东东软学院', 'SOVO 公寓 1 栋', true),
      new AddressItem('addr-2', '测试同学', '13900000000', '广东东软学院', '教学楼 A 区门口', false)
    ];
  }

  static printPrices(): PrintPrice[] {
    return [
      new PrintPrice('黑白打印', '0.20', '元/页'),
      new PrintPrice('彩色打印', '1.00', '元/页'),
      new PrintPrice('装订服务', '2.00', '元/份')
    ];
  }

  static printOrders(): PrintOrder[] {
    return [
      new PrintOrder('po-1', '派送服务', '广东东软学院 SOVO 公寓', '互成一家用户', '13800000000', 2, '实验报告.pdf', '下课后送达', '待处理'),
      new PrintOrder('po-2', '自取服务', '打印店自取', '测试同学', '13900000000', 1, '简历.pdf', 'A4 单面', '已完成')
    ];
  }

  static courses(): SchoolCourse[] {
    return [
      new SchoolCourse('c-1', 'HarmonyOS 应用开发', '陈老师', 'A305', '周一', '1-2节'),
      new SchoolCourse('c-2', '软件工程实践', '李老师', 'B204', '周三', '3-4节'),
      new SchoolCourse('c-3', '数据库系统', '王老师', 'C101', '周五', '5-6节')
    ];
  }

  static grades(): GradeRecord[] {
    return [
      new GradeRecord('g-1', 'HarmonyOS 应用开发', '2.0', '92', '2025-2026-2'),
      new GradeRecord('g-2', '软件工程实践', '3.0', '88', '2025-2026-2'),
      new GradeRecord('g-3', '数据库系统', '3.0', '85', '2025-2026-2')
    ];
  }

  static members(): MemberWork[] {
    return [
      new MemberWork(1, '24213310113', '张开鑫', '组长，32%。总体架构、ArkTS 页面框架、网络请求封装、缓存封装、首页/Tab/路由、最终整合与答辩材料。'),
      new MemberWork(2, '24213310125', '郭嘉荣', '28%。服务页、社区页、图片水印复用、校园定位导航、Mock 数据整理、页面视觉统一与功能联调补充。'),
      new MemberWork(3, '20213110210', '梁胤佳', '20%。待办专注模块、招聘模块、详情页、弹框/Toast/交互状态、接口联调说明。'),
      new MemberWork(4, '21253610117', '古栋', '20%。实验报告、截图占位、代码示例整理、coding Agent 辅助开发过程记录、测试与总结。')
    ];
  }
}
