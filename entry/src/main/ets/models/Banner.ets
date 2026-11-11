export class Banner {
  id: string;
  title: string;
  imageUrl: string;
  summary: string;

  constructor(id: string = '', title: string = '', imageUrl: string = '', summary: string = '') {
    this.id = id;
    this.title = title;
    this.imageUrl = imageUrl;
    this.summary = summary;
  }
}
