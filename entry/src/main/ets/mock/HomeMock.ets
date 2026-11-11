import { Banner } from '../models/Banner';
import { CampusPlace, CampusNotification, HomeService, ServiceItem } from '../models/MockModels';

export class HomeMock {
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

  /** 首页推荐服务卡（与小程序 ServiceRecommend.vue 一致）。 */
  static homeServices(): HomeService[] {
    return [
      new HomeService('flow', '校园人流天气', '实时查看校园各区域人流量分布与空气质量指数，助你避开拥挤，畅享清新校园生活。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAESETBpwP6ugYWtISs6XQ81KokrT4mBIgACnCQAAiLeCFbhCOwpzFtBizoE.png', '', '5.0', '4060', 'pages/ServicePersonInfo'),
      new HomeService('schedule', '查询课表服务', '查询当前学期的课表，方便你及时了解自己的课程安排。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECPRpAZAXQl3cBfhxDxuSt1AojYoeHQAC7iAAAtCQCFQvkTsfSeUnwjYE.jpg', '', '4.8', '1580', 'pages/ServiceSchedule'),
      new HomeService('grade', '查询成绩服务', '查询当前学期的成绩，方便你及时了解自己的学习情况。', 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAEECP5pAZDT2lKDbMs1BC1kkTo76bcj3AAC-CAAAtCQCFQGU12qYNcw8DYE.jpg', '', '4.8', '1580', 'pages/ServiceGrade'),
      new HomeService('print', '远程打印服务', '宿舍也能轻松打印！手机一键上传，即刻获取文件。', 'https://api.hcyj.xyz/images/dnfw.png', '¥0.2/页', '4.9', '2350', 'pages/ServicePrint'),
      new HomeService('more', '更多服务', '更多精彩服务即将上线！我们正在精心准备更多便捷实用的校园服务。', 'https://api.hcyj.xyz/images/gdfw.jpg', '???¥', '5.0', '5000', 'pages/Service')
    ];
  }
  /** 校园动态（与小程序 CampusNotifications.vue 一致，7 条）。 */
  static campusNotifications(): CampusNotification[] {
    return [
      new CampusNotification('n1', '重要', '#ff4d4f', '关于2025年春季学期期末考试安排的通知', '各位同学，2025年春季学期期末考试将于6月15日至6月25日进行，请查看具体安排并做好准备。', '教务处', '2小时前', '1253'),
      new CampusNotification('n2', '活动', '#1890ff', '校园才艺大赛报名开始', '第十二届校园才艺大赛现已开始报名，欢迎各位同学积极参与，展示你的才华！', '学生会', '4小时前', '865'),
      new CampusNotification('n3', '讲座', '#722ed1', '人工智能与未来职业发展讲座', '著名AI研究员张教授将于下周三在主教学楼进行讲座，探讨AI如何改变未来就业格局。', '计算机学院', '昨天', '743'),
      new CampusNotification('n4', '通知', '#faad14', '图书馆开放时间调整', '因维修工程，图书馆自5月1日起将调整开放时间，周一至周五8:00-21:00，周末9:00-18:00。', '图书馆', '昨天', '1028'),
      new CampusNotification('n5', '奖学金', '#52c41a', '2025年国家奖学金申请开始', '2025年国家奖学金申请已开始，请符合条件的同学于5月15日前提交申请材料。', '学生处', '2天前', '1536'),
      new CampusNotification('n6', '就业', '#fa8c16', '腾讯2025校园招聘宣讲会', '腾讯公司将于5月10日在主会场举办校园招聘宣讲会，欢迎应届毕业生参加。', '就业指导中心', '3天前', '1892'),
      new CampusNotification('n7', '社团', '#13c2c2', '摄影协会春季采风活动', '摄影协会将于本周六组织春季采风活动，地点为城市植物园，感兴趣的同学请报名参加。', '摄影协会', '3天前', '456')
    ];
  }
}
