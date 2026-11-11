import { CommunityPost, PostType } from '../models/CommunityPost';
import { ErrandTask } from '../models/MockModels';

export class CommunityMock {
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
}
