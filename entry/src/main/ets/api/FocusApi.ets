import { ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';

class FocusPayload {
  minutes: number = 0;

  constructor(minutes: number) {
    this.minutes = minutes;
  }
}

/** 后端 /checkin/focus/today 返回 { todayMinutes }。 */
class TodayFocusResponse {
  todayMinutes: number = 0;
}

export class FocusApi {
  static async submit(token: string, minutes: number, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/checkin/focus', token, new FocusPayload(minutes), apiEnvironment);
  }

  static async today(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<number> {
    const result = await HttpClient.get<TodayFocusResponse>('/checkin/focus/today', token, apiEnvironment);
    if (result.data === null || result.data.todayMinutes === null) {
      return 0;
    }
    const minutes = Number(result.data.todayMinutes);
    return Number.isFinite(minutes) ? minutes : 0;
  }
}
