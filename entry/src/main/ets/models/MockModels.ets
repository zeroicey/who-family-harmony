export class ServiceItem {
  id: string;
  title: string;
  summary: string;
  iconText: string;
  imageUrl: string;

  constructor(id: string, title: string, summary: string, iconText: string, imageUrl: string) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.iconText = iconText;
    this.imageUrl = imageUrl;
  }
}

export class CampusPlace {
  id: string;
  title: string;
  description: string;
  route: string;

  constructor(id: string, title: string, description: string, route: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.route = route;
  }
}

export class ErrandTask {
  id: string;
  type: string;
  content: string;
  from: string;
  to: string;
  price: number;
  status: string;
  createTime: string;
  userName: string;
  avatarId: string;

  constructor(
    id: string,
    type: string,
    content: string,
    from: string,
    to: string,
    price: number,
    status: string,
    createTime: string,
    userName: string,
    avatarId: string
  ) {
    this.id = id;
    this.type = type;
    this.content = content;
    this.from = from;
    this.to = to;
    this.price = price;
    this.status = status;
    this.createTime = createTime;
    this.userName = userName;
    this.avatarId = avatarId;
  }
}

export class HomeService {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  price: string;
  rating: string;
  orders: string;
  route: string;

  constructor(id: string, title: string, description: string, imageUrl: string, price: string, rating: string, orders: string, route: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.imageUrl = imageUrl;
    this.price = price;
    this.rating = rating;
    this.orders = orders;
    this.route = route;
  }
}

export class CampusNotification {
  id: string;
  typeText: string;
  tagColor: string;
  title: string;
  description: string;
  sender: string;
  time: string;
  readers: string;

  constructor(id: string, typeText: string, tagColor: string, title: string, description: string, sender: string, time: string, readers: string) {
    this.id = id;
    this.typeText = typeText;
    this.tagColor = tagColor;
    this.title = title;
    this.description = description;
    this.sender = sender;
    this.time = time;
    this.readers = readers;
  }
}

/** 协议章节：标题 + 正文（正文保留参考实现的换行结构）。 */
export class AgreementSection {
  heading: string;
  body: string;

  constructor(heading: string, body: string) {
    this.heading = heading;
    this.body = body;
  }
}
