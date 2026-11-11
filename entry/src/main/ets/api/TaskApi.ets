import { StudyTask } from '../models/Task';
import { ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { HttpClient } from './HttpClient';

class AddTaskPayload {
  title: string = '';
  description: string = '';
  deadline: string = '';

  constructor(task: StudyTask) {
    this.title = task.title;
    this.description = task.description;
    this.deadline = task.deadline;
  }
}

class TaskIdPayload {
  id: string = '';

  constructor(id: string) {
    this.id = id;
  }
}

export class TaskApi {
  static async list(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<StudyTask[]> {
    const result = await HttpClient.get<StudyTask[]>('/checkin/todos', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async add(token: string, task: StudyTask, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/checkin/addTodo', token, new AddTaskPayload(task), apiEnvironment);
  }

  static async done(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.put<ApiEmptyResponse>('/checkin/done', token, new TaskIdPayload(id), apiEnvironment);
  }

  static async todo(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.put<ApiEmptyResponse>('/checkin/todo', token, new TaskIdPayload(id), apiEnvironment);
  }

  static async remove(token: string, id: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.delete<ApiEmptyResponse>('/checkin/todo', token, new TaskIdPayload(id), apiEnvironment);
  }
}
