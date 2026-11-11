import { Banner } from '../models/Banner';
import { ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';

export class BannerApi {
  static async list(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<Banner[]> {
    const result = await HttpClient.get<Banner[]>('/sys/banners', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }
}
