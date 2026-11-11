import { AddressItem, PrintOrder, PrintPrice } from '../models/MiniProgramModels';

export class ServiceMock {
  static addresses(): AddressItem[] {
    return [
      new AddressItem(1, '互成一家用户', '13800000000', '广东东软学院', 'SOVO 公寓 1 栋', true),
      new AddressItem(2, '测试同学', '13900000000', '广东东软学院', '教学楼 A 区门口', false)
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
}
