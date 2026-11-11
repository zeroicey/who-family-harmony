export class KnowledgeArticle {
  id: string;
  category: string;
  title: string;
  description: string;
  level: string;
  tags: string[];
  readTime: string;
  wordCount: number;
  author: string;
  views: number;
  likes: number;
  publishDate: string;
  content: string[];
  isRecommended: boolean;

  constructor(
    id: string = '',
    category: string = '',
    title: string = '',
    description: string = '',
    level: string = '初级',
    tags: string[] = [],
    readTime: string = '',
    wordCount: number = 0,
    author: string = '',
    views: number = 0,
    likes: number = 0,
    publishDate: string = '',
    content: string[] = [],
    isRecommended: boolean = false
  ) {
    this.id = id;
    this.category = category;
    this.title = title;
    this.description = description;
    this.level = level;
    this.tags = tags;
    this.readTime = readTime;
    this.wordCount = wordCount;
    this.author = author;
    this.views = views;
    this.likes = likes;
    this.publishDate = publishDate;
    this.content = content;
    this.isRecommended = isRecommended;
  }
}

export class ChatMessage {
  id: string;
  role: string;
  content: string;

  constructor(id: string = '', role: string = 'ai', content: string = '') {
    this.id = id;
    this.role = role;
    this.content = content;
  }
}

export class PresetQuestion {
  id: string;
  title: string;
  content: string;

  constructor(id: string = '', title: string = '', content: string = '') {
    this.id = id;
    this.title = title;
    this.content = content;
  }
}

export class AddressItem {
  id: string;
  name: string;
  phone: string;
  area: string;
  detail: string;
  isDefault: boolean;

  constructor(
    id: string = '',
    name: string = '',
    phone: string = '',
    area: string = '',
    detail: string = '',
    isDefault: boolean = false
  ) {
    this.id = id;
    this.name = name;
    this.phone = phone;
    this.area = area;
    this.detail = detail;
    this.isDefault = isDefault;
  }
}

export class PrintPrice {
  name: string;
  price: string;
  unit: string;

  constructor(name: string = '', price: string = '', unit: string = '') {
    this.name = name;
    this.price = price;
    this.unit = unit;
  }
}

export class PrintOrder {
  id: string;
  type: string;
  address: string;
  name: string;
  phone: string;
  count: number;
  fileName: string;
  remark: string;
  status: string;
  createdAt: string;

  constructor(
    id: string = '',
    type: string = '派送服务',
    address: string = '',
    name: string = '',
    phone: string = '',
    count: number = 1,
    fileName: string = '',
    remark: string = '',
    status: string = '待处理',
    createdAt: string = ''
  ) {
    this.id = id;
    this.type = type;
    this.address = address;
    this.name = name;
    this.phone = phone;
    this.count = count;
    this.fileName = fileName;
    this.remark = remark;
    this.status = status;
    this.createdAt = createdAt;
  }
}

export class SchoolCourse {
  id: string;
  name: string;
  teacher: string;
  location: string;
  day: string;
  section: string;
  courseCode: string;
  className: string;
  dayOfWeek: number;
  startTime: number;
  endTime: number;
  week: number;
  credits: number;

  constructor(
    id: string = '',
    name: string = '',
    teacher: string = '',
    location: string = '',
    day: string = '',
    section: string = '',
    courseCode: string = '',
    className: string = '',
    dayOfWeek: number = 1,
    startTime: number = 1,
    endTime: number = 2,
    week: number = 1,
    credits: number = 0
  ) {
    this.id = id;
    this.name = name;
    this.teacher = teacher;
    this.location = location;
    this.day = day;
    this.section = section;
    this.courseCode = courseCode;
    this.className = className;
    this.dayOfWeek = dayOfWeek;
    this.startTime = startTime;
    this.endTime = endTime;
    this.week = week;
    this.credits = credits;
  }
}

export class GradeRecord {
  id: string;
  course: string;
  credit: string;
  score: string;
  term: string;
  courseCode: string;
  gpa: string;
  type: string;
  category: string;

  constructor(
    id: string = '',
    course: string = '',
    credit: string = '',
    score: string = '',
    term: string = '',
    courseCode: string = '',
    gpa: string = '',
    type: string = '',
    category: string = ''
  ) {
    this.id = id;
    this.course = course;
    this.credit = credit;
    this.score = score;
    this.term = term;
    this.courseCode = courseCode;
    this.gpa = gpa;
    this.type = type;
    this.category = category;
  }
}

export class RouteParams {
  id: string = '';
  type: string = '';
}
