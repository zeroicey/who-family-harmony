export class StudyTask {
  id: string;
  title: string;
  description: string;
  deadline: string;
  status: string;

  constructor(
    id: string = '',
    title: string = '',
    description: string = '',
    deadline: string = '',
    status: string = '待完成'
  ) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.deadline = deadline;
    this.status = status;
  }
}
