import { ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';
import { PrintOrder, PrintPrice } from '../models/MiniProgramModels';

class PrintPriceResponse {
  text: string = '';
}

class PrintOpenResponse {
  isOpen: boolean = false;
}

class PrintOrderPayload {
  type: string = '';
  address: string = '';
  name: string = '';
  phone: string = '';
  count: number = 1;
  fileName: string = '';
  remark: string = '';
  file: string = '';

  constructor(order: PrintOrder) {
    this.type = order.type;
    this.address = order.address;
    this.name = order.name;
    this.phone = order.phone;
    this.count = order.count;
    this.fileName = order.fileName;
    this.remark = order.remark;
    this.file = 'data:application/pdf;base64,FILE_UPLOAD_REQUIRES_DEVICE_RETEST';
  }
}

export class PrintApi {
  static async priceText(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<string> {
    const result = await HttpClient.get<PrintPriceResponse>('/print/price', token, apiEnvironment);
    return result.data === null ? '' : result.data.text;
  }

  static async price(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PrintPrice[]> {
    const text = await PrintApi.priceText(token, apiEnvironment);
    return text.length === 0 ? [] : [new PrintPrice('打印价格', text, '')];
  }

  static async isOpen(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<boolean> {
    const result = await HttpClient.get<PrintOpenResponse>('/print/is-open', token, apiEnvironment);
    return result.data === null ? false : result.data.isOpen;
  }

  static async createOrder(token: string, order: PrintOrder, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PrintOrder | null> {
    const result = await HttpClient.post<PrintOrder>('/print/order', token, new PrintOrderPayload(order), apiEnvironment);
    return result.data;
  }

  static async selfOrders(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<PrintOrder[]> {
    const result = await HttpClient.get<PrintOrder[]>('/print/self-orders', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }
}
