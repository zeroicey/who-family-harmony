/**
 * 快递代取本地订单（小程序未提供后端下单接口，鸿蒙版按产品决策使用本地演示订单）。
 * 仅保存在本机缓存，不会提交到后端。
 */
export class ExpressOrder {
  id: string;
  addressId: string;
  addressDetails: string;
  packageSize: string;
  estimatedWeight: string;
  remark: string;
  price: number;
  status: string;
  createdAt: string;

  constructor(
    id: string = '',
    addressId: string = '',
    addressDetails: string = '',
    packageSize: string = '中件',
    estimatedWeight: string = '1-5kg',
    remark: string = '',
    price: number = 0,
    status: string = '待处理',
    createdAt: string = ''
  ) {
    this.id = id;
    this.addressId = addressId;
    this.addressDetails = addressDetails;
    this.packageSize = packageSize;
    this.estimatedWeight = estimatedWeight;
    this.remark = remark;
    this.price = price;
    this.status = status;
    this.createdAt = createdAt;
  }
}

/** 通用成功页参数（router.getParams 的强类型视图）。 */
export class ServiceSuccessParams {
  type: string = '';
  orderId: string = '';
  title: string = '';
  desc: string = '';
}
