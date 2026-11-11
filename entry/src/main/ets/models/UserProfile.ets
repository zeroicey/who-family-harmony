export class UserProfile {
  id: string;
  name: string;
  nickname: string;
  studentId: string;
  role: string;
  gender: string;
  school: string;
  major: string;
  grade: string;
  avatar: string;
  avaterId: string;
  avatarUrl: string;
  bio: string;
  level: number;

  constructor(
    nickname: string = '互成一家用户',
    studentId: string = '24213310113',
    role: string = '学生',
    gender: string = '未知',
    school: string = '广东东软学院',
    major: string = '软件工程',
    grade: string = '大三',
    avatar: string = 'defaultUserIcon'
  ) {
    this.id = studentId;
    this.name = nickname;
    this.nickname = nickname;
    this.studentId = studentId;
    this.role = role;
    this.gender = gender;
    this.school = school;
    this.major = major;
    this.grade = grade;
    this.avatar = avatar;
    this.avaterId = avatar;
    this.avatarUrl = '';
    this.bio = '';
    this.level = 0;
  }
}

export class MemberWork {
  order: number;
  studentId: string;
  name: string;
  work: string;

  constructor(order: number, studentId: string, name: string, work: string) {
    this.order = order;
    this.studentId = studentId;
    this.name = name;
    this.work = work;
  }
}
