import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';
import { GradeRecord, SchoolCourse } from '../models/MiniProgramModels';
import { LogUtil } from '../utils/LogUtil';

class SchoolCourseRaw {
  dgksdm: string | number = '';
  kcmc: string = '';
  teaxms: string = '';
  jxcdmc: string = '';
  kcbh: string = '';
  jxbmc: string = '';
  xq: string | number = '';
  jcdm2: string = '';
  zc: string | number = '';
  xs: string | number = '';
}

class SchoolScheduleResponse {
  success: boolean = false;
  message: string = '';
  items: SchoolCourseRaw[][] = [];
  data: SchoolCourseRaw[][] = [];
}

class SchoolGradeRaw {
  rownum_: string | number = '';
  kcmc: string = '';
  kcbh: string = '';
  zcj: string | number = '';
  xf: string | number = '';
  cjjd: string | number = '';
  xdfsmc: string = '';
  kcdlmc: string = '';
  xnxqmc: string = '';
}

class SchoolGradeResponse {
  success: boolean = false;
  message: string = '';
  items: SchoolGradeRaw[] = [];
  data: SchoolGradeRaw[] = [];
}

export class SchoolApi {
  private static readonly dayNames: string[] = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  private static async directGet<T>(url: string): Promise<T> {
    LogUtil.info('school-api', `GET ${url}`);
    return await new Promise<T>((resolve, reject) => {
      const requestTask = http.createHttp();
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: ApiConfig.TIMEOUT,
        connectTimeout: ApiConfig.TIMEOUT,
        usingCache: false
      };
      requestTask.request(url, options, (err: Error, response: http.HttpResponse) => {
        requestTask.destroy();
        if (err) {
          reject(err);
          return;
        }
        if (response.responseCode < 200 || response.responseCode >= 300) {
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }
        try {
          resolve(JSON.parse(response.result as string) as T);
        } catch (_) {
          reject(new Error('学校接口响应 JSON 解析失败'));
        }
      });
    });
  }

  private static safeText(value: string | number | null): string {
    return value ? `${value}` : '';
  }

  private static safeNumber(value: string | number | null): number {
    if (!value) {
      return 0;
    }
    const parsed = Number(value);
    if (parsed >= 0 || parsed < 0) {
      return parsed;
    }
    return 0;
  }

  private static periodBounds(periodsText: string): number[] {
    const periods = periodsText.split(',');
    let start = 99;
    let end = 0;
    periods.forEach((item: string) => {
      const value = Number(item);
      if (value >= 0 || value < 0) {
        if (value < start) {
          start = value;
        }
        if (value > end) {
          end = value;
        }
      }
    });
    if (start === 99 || end === 0) {
      return [1, 2];
    }
    return [start, end];
  }

  private static mapCourse(raw: SchoolCourseRaw, index: number): SchoolCourse {
    const dayOfWeek = SchoolApi.safeNumber(raw.xq);
    const bounds = SchoolApi.periodBounds(raw.jcdm2);
    const day = dayOfWeek >= 1 && dayOfWeek <= 7 ? SchoolApi.dayNames[dayOfWeek] : '周一';
    return new SchoolCourse(
      SchoolApi.safeText(raw.dgksdm).length > 0 ? SchoolApi.safeText(raw.dgksdm) : `course-${index}`,
      SchoolApi.safeText(raw.kcmc),
      SchoolApi.safeText(raw.teaxms),
      SchoolApi.safeText(raw.jxcdmc),
      day,
      `${bounds[0]}-${bounds[1]}节`,
      SchoolApi.safeText(raw.kcbh),
      SchoolApi.safeText(raw.jxbmc),
      dayOfWeek > 0 ? dayOfWeek : 1,
      bounds[0],
      bounds[1],
      SchoolApi.safeNumber(raw.zc),
      SchoolApi.safeNumber(raw.xs)
    );
  }

  private static mapGrade(raw: SchoolGradeRaw, index: number, term: string): GradeRecord {
    return new GradeRecord(
      SchoolApi.safeText(raw.rownum_).length > 0 ? SchoolApi.safeText(raw.rownum_) : `grade-${index}`,
      SchoolApi.safeText(raw.kcmc),
      SchoolApi.safeText(raw.xf),
      SchoolApi.safeText(raw.zcj),
      SchoolApi.safeText(raw.xnxqmc).length > 0 ? SchoolApi.safeText(raw.xnxqmc) : term,
      SchoolApi.safeText(raw.kcbh),
      SchoolApi.safeText(raw.cjjd),
      SchoolApi.safeText(raw.xdfsmc),
      SchoolApi.safeText(raw.kcdlmc)
    );
  }

  static async schedule(studentNo: string, password: string, term: string, week: string): Promise<SchoolCourse[]> {
    const url = `${ApiConfig.BASE_URL}/yeciorez/neusoft/schedule?studentNo=${encodeURIComponent(studentNo)}&password=${encodeURIComponent(password)}&term=${encodeURIComponent(term)}&week=${encodeURIComponent(week)}`;
    const result = await SchoolApi.directGet<SchoolScheduleResponse>(url);
    if (result.success === false) {
      throw new Error(result.message.length > 0 ? result.message : '课表查询失败');
    }
    const rows = result.items && result.items.length > 0 ? result.items[0] : result.data && result.data.length > 0 ? result.data[0] : [];
    const courses: SchoolCourse[] = [];
    rows.forEach((raw: SchoolCourseRaw, index: number) => {
      courses.push(SchoolApi.mapCourse(raw, index));
    });
    return courses;
  }

  static async grades(studentNo: string, password: string, term: string): Promise<GradeRecord[]> {
    const url = `${ApiConfig.BASE_URL}/yeciorez/neusoft/grades?studentNo=${encodeURIComponent(studentNo)}&password=${encodeURIComponent(password)}&term=${encodeURIComponent(term)}`;
    const result = await SchoolApi.directGet<SchoolGradeResponse>(url);
    if (result.success === false) {
      throw new Error(result.message.length > 0 ? result.message : '成绩查询失败');
    }
    const rows = result.data && result.data.length > 0 ? result.data : result.items;
    const grades: GradeRecord[] = [];
    rows.forEach((raw: SchoolGradeRaw, index: number) => {
      grades.push(SchoolApi.mapGrade(raw, index, term));
    });
    return grades;
  }
}
