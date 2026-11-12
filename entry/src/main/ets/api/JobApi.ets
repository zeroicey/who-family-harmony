import { Job, JobType } from '../models/Job';
import { ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';

class CollectJobPayload {
  id: string = '';
  collect: boolean = false;

  constructor(id: string, collect: boolean) {
    this.id = id;
    this.collect = collect;
  }
}

class JobIdPayload {
  id: string = '';

  constructor(id: string) {
    this.id = id;
  }
}

class JobResponse {
  id: string | number = '';
  typeId: string | number = '';
  name: string = '';
  title: string = '';
  organizationName: string = '';
  organization: string = '';
  location: string = '';
  salary: string = '';
  type: string = '';
  description: string = '';
  requirements: string = '';
  requirement: string = '';
  benefits: string = '';
  welfare: string = '';
  contact: string = '';
  logoUrl: string = '';
  positions: number | string = 0;
  deliverCount: number | string = 0;
  endTime: string = '';
  createTime: string = '';
  isHot: number | string | boolean = false;
  isRecommended: number | string | boolean = false;
  isDeliver: number | string | boolean = false;
  isCollect: number | string | boolean = 0;
  collected: boolean = false;
}

export class JobApi {
  private static safeText(value: string | number | boolean | null): string {
    return value ? `${value}` : '';
  }

  private static safeCollect(value: number | string | boolean | null): boolean {
    return value === true || value === 1 || value === '1' || value === 'true';
  }

  private static safeNumber(value: number | string | null): number {
    if (!value) {
      return 0;
    }
    const parsed = Number(value);
    if (parsed >= 0 || parsed < 0) {
      return parsed;
    }
    return 0;
  }

  private static normalizeJob(job: JobResponse): Job {
    const title = JobApi.safeText(job.name).length > 0 ? JobApi.safeText(job.name) : JobApi.safeText(job.title);
    const organization = JobApi.safeText(job.organizationName).length > 0 ? JobApi.safeText(job.organizationName) : JobApi.safeText(job.organization);
    const requirement = JobApi.safeText(job.requirements).length > 0 ? JobApi.safeText(job.requirements) : JobApi.safeText(job.requirement);
    const welfare = JobApi.safeText(job.benefits).length > 0 ? JobApi.safeText(job.benefits) : JobApi.safeText(job.welfare);
    const normalized = new Job(
      JobApi.safeText(job.id),
      JobApi.safeText(job.typeId),
      title,
      organization,
      JobApi.safeText(job.location),
      JobApi.safeText(job.salary),
      [JobApi.safeText(job.type)],
      JobApi.safeText(job.description),
      requirement,
      welfare,
      JobApi.safeText(job.contact),
      job.collected || JobApi.safeCollect(job.isCollect)
    );
    normalized.logoUrl = JobApi.safeText(job.logoUrl);
    normalized.positions = JobApi.safeNumber(job.positions);
    normalized.deliverCount = JobApi.safeNumber(job.deliverCount);
    normalized.endTime = JobApi.safeText(job.endTime);
    normalized.createTime = JobApi.safeText(job.createTime);
    normalized.isHot = JobApi.safeCollect(job.isHot);
    normalized.isRecommended = JobApi.safeCollect(job.isRecommended);
    normalized.isDeliver = JobApi.safeCollect(job.isDeliver);
    return normalized;
  }

  private static normalizeJobs(jobs: JobResponse[]): Job[] {
    const normalizedJobs: Job[] = [];
    jobs.forEach((job: JobResponse) => {
      normalizedJobs.push(JobApi.normalizeJob(job));
    });
    return normalizedJobs;
  }

  static async types(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<JobType[]> {
    const result = await HttpClient.get<JobType[]>('/hire/job-types', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async recommend(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<Job[]> {
    const result = await HttpClient.get<JobResponse[]>('/hire/recommend-jobs', token, apiEnvironment);
    return result.data === null ? [] : JobApi.normalizeJobs(result.data);
  }

  /** 分页加载：lastId 为当前列表最后一条岗位 id（与小程序 fetchMoreRecruits 一致）。 */
  static async recommendMore(token: string, lastId: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<Job[]> {
    const result = await HttpClient.get<JobResponse[]>(`/hire/recommend-jobs?lastId=${encodeURIComponent(lastId)}`, token,
      apiEnvironment);
    return result.data === null ? [] : JobApi.normalizeJobs(result.data);
  }

  static async detail(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<Job | null> {
    const result = await HttpClient.get<JobResponse>(`/hire/job?id=${id}`, token, apiEnvironment);
    return result.data === null ? null : JobApi.normalizeJob(result.data);
  }

  static async collect(token: string, id: string, collect: boolean, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/hire/collect-job', token, new CollectJobPayload(id, collect), apiEnvironment);
  }

  static async submit(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/hire/submit', token, new JobIdPayload(id), apiEnvironment);
  }
}
