export class JobType {
  id: string;
  name: string;

  constructor(id: string = '', name: string = '') {
    this.id = id;
    this.name = name;
  }
}

@Observed
export class Job {
  id: string;
  typeId: string;
  title: string;
  organization: string;
  location: string;
  salary: string;
  tags: string[];
  description: string;
  requirement: string;
  welfare: string;
  contact: string;
  collected: boolean;
  logoUrl: string;
  positions: number;
  deliverCount: number;
  endTime: string;
  createTime: string;
  isHot: boolean;
  isRecommended: boolean;
  isDeliver: boolean;

  constructor(
    id: string = '',
    typeId: string = '',
    title: string = '',
    organization: string = '',
    location: string = '',
    salary: string = '',
    tags: string[] = [],
    description: string = '',
    requirement: string = '',
    welfare: string = '',
    contact: string = '',
    collected: boolean = false
  ) {
    this.id = id;
    this.typeId = typeId;
    this.title = title;
    this.organization = organization;
    this.location = location;
    this.salary = salary;
    this.tags = tags;
    this.description = description;
    this.requirement = requirement;
    this.welfare = welfare;
    this.contact = contact;
    this.collected = collected;
    this.logoUrl = '';
    this.positions = 0;
    this.deliverCount = 0;
    this.endTime = '';
    this.createTime = '';
    this.isHot = false;
    this.isRecommended = false;
    this.isDeliver = false;
  }
}
