import { StudyTask } from '../models/Task';
import { MemberWork } from '../models/UserProfile';
import { GradeRecord, SchoolCourse } from '../models/MiniProgramModels';

export class TaskMock {
  static tasks(): StudyTask[] {
    return [
      new StudyTask('task-1', '完成 ArkTS 期末报告截图', '补充首页、我的页和水印效果截图。', '2026-06-10', '待完成'),
      new StudyTask('task-2', '整理接口联调说明', '记录 token、缓存和 mock 降级策略。', '2026-06-11', '待完成'),
      new StudyTask('task-3', '检查运行结果', '真机验证页面跳转和 Toast。', '2026-06-12', '已完成')
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
