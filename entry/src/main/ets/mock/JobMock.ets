import { Job, JobType } from '../models/Job';

export class JobMock {
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
}
