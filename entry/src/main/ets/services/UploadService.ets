import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { LogUtil } from '../utils/LogUtil';

/** 图片体积上限：10MB；文档体积上限：50MB。 */
export class UploadLimits {
  static readonly IMAGE_MAX_BYTES: number = 10 * 1024 * 1024;
  static readonly DOCUMENT_MAX_BYTES: number = 50 * 1024 * 1024;
  static readonly MAX_IMAGES: number = 9;
}

/** 已读取到内存的文件：可产出 ArrayBuffer 或 base64，供上传/内容检查使用。 */
export class PickedFile {
  uri: string;
  name: string;
  mimeType: string;
  size: number;
  data: ArrayBuffer;

  constructor(uri: string, name: string, mimeType: string, size: number, data: ArrayBuffer) {
    this.uri = uri;
    this.name = name;
    this.mimeType = mimeType;
    this.size = size;
    this.data = data;
  }

  base64(): string {
    const helper = new util.Base64Helper();
    return helper.encodeToStringSync(new Uint8Array(this.data));
  }

  /** data:image/xxx;base64,...，部分后端接口直接接受这种格式。 */
  base64DataUrl(): string {
    return `data:${this.mimeType};base64,${this.base64()}`;
  }

  sizeText(): string {
    if (this.size >= 1024 * 1024) {
      return `${(this.size / (1024 * 1024)).toFixed(1)}MB`;
    }
    return `${Math.ceil(this.size / 1024)}KB`;
  }
}

export class UploadService {
  /**
   * 从相册选择图片（PhotoViewPicker）。返回已读入内存的文件。
   */
  static async pickImages(maxCount: number = UploadLimits.MAX_IMAGES): Promise<PickedFile[]> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = Math.min(Math.max(maxCount, 1), UploadLimits.MAX_IMAGES);
    const photoPicker = new photoAccessHelper.PhotoViewPicker();
    const result = await photoPicker.select(options);
    const files: PickedFile[] = [];
    for (let i = 0; i < result.photoUris.length; i++) {
      const uri = result.photoUris[i];
      files.push(await UploadService.readUri(uri, `image_${Date.now()}_${i}.jpg`, 'image/jpeg'));
    }
    LogUtil.info('upload', `pickImages count=${files.length}`);
    return files;
  }

  /**
   * 从文件管理器选择文档（DocumentViewPicker），用于打印等场景。
   */
  static async pickDocuments(
    context: common.UIAbilityContext,
    maxCount: number = 1,
    suffixFilters: string[] = ['文档|.pdf', 'Word|.doc', 'Word|.docx', 'Excel|.xls', 'Excel|.xlsx', 'PPT|.ppt', 'PPT|.pptx', '文本|.txt']
  ): Promise<PickedFile[]> {
    const documentPicker = new picker.DocumentViewPicker(context);
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = maxCount;
    options.fileSuffixFilters = suffixFilters;
    const uris = await documentPicker.select(options);
    const files: PickedFile[] = [];
    for (let i = 0; i < uris.length; i++) {
      const uri = uris[i];
      const name = UploadService.fileNameFromUri(uri);
      files.push(await UploadService.readUri(uri, name, UploadService.mimeForName(name)));
    }
    LogUtil.info('upload', `pickDocuments count=${files.length}`);
    return files;
  }

  /** 读取指定 URI 到 ArrayBuffer。 */
  static async readUri(uri: string, fallbackName: string, fallbackMime: string): Promise<PickedFile> {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(file.fd);
      const size = stat.size;
      const buffer = new ArrayBuffer(size);
      const readLength = fileIo.readSync(file.fd, buffer);
      // readLength 与实际 stat.size 不一致时按实际读取截断
      const data = readLength >= size ? buffer : buffer.slice(0, readLength);
      const name = file.name.length > 0 ? file.name : fallbackName;
      LogUtil.info('upload', `read uri size=${size} read=${readLength} name=${name}`);
      return new PickedFile(uri, name, UploadService.mimeForName(name, fallbackMime), readLength, data);
    } finally {
      fileIo.closeSync(file);
    }
  }

  /** 图片类型/大小校验；通过返回空字符串。 */
  static checkImage(file: PickedFile): string {
    if (!UploadService.isAllowedImageMime(file.mimeType) && !UploadService.isAllowedImageName(file.name)) {
      return '仅支持 JPG、PNG、GIF、WEBP、BMP 格式的图片';
    }
    if (file.size <= 0) {
      return '图片内容为空，请重新选择';
    }
    if (file.size > UploadLimits.IMAGE_MAX_BYTES) {
      return `图片不能超过 ${UploadLimits.IMAGE_MAX_BYTES / (1024 * 1024)}MB`;
    }
    return '';
  }

  /** 文档类型/大小校验；通过返回空字符串。 */
  static checkDocument(file: PickedFile): string {
    if (!UploadService.isAllowedDocumentName(file.name) && !UploadService.isAllowedDocumentMime(file.mimeType)) {
      return '仅支持 PDF、Word、Excel、PPT、TXT 格式的文件';
    }
    if (file.size <= 0) {
      return '文件内容为空，请重新选择';
    }
    if (file.size > UploadLimits.DOCUMENT_MAX_BYTES) {
      return `文件不能超过 ${UploadLimits.DOCUMENT_MAX_BYTES / (1024 * 1024)}MB`;
    }
    return '';
  }

  static isAllowedImageMime(mime: string): boolean {
    const allowed: string[] = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp'];
    return allowed.indexOf(mime.toLowerCase()) >= 0;
  }

  static isAllowedImageName(name: string): boolean {
    const lower = name.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') ||
      lower.endsWith('.gif') || lower.endsWith('.webp') || lower.endsWith('.bmp');
  }

  static isAllowedDocumentName(name: string): boolean {
    const lower = name.toLowerCase();
    return lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx') ||
      lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.ppt') ||
      lower.endsWith('.pptx') || lower.endsWith('.txt');
  }

  static isAllowedDocumentMime(mime: string): boolean {
    const allowed: string[] = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'text/plain'
    ];
    return allowed.indexOf(mime.toLowerCase()) >= 0;
  }

  static mimeForName(name: string, fallback: string = ''): string {
    const lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.bmp')) {
      return 'image/bmp';
    }
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) {
      return 'application/vnd.ms-excel';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.ppt')) {
      return 'application/vnd.ms-powerpoint';
    }
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.txt')) {
      return 'text/plain';
    }
    return fallback.length > 0 ? fallback : 'application/octet-stream';
  }

  static fileNameFromUri(uri: string): string {
    const segments = uri.split('/');
    const last = segments.length > 0 ? segments[segments.length - 1] : '';
    if (last.length === 0) {
      return `file_${Date.now()}`;
    }
    return decodeURIComponent(last);
  }
}