import { AppColors, AppFont, AppRadius, AppSpace } from '../../theme/Theme';

/** 行内片段：支持粗体、斜体、行内代码、链接。 */
export class MdSpan {
  text: string = '';
  bold: boolean = false;
  italic: boolean = false;
  code: boolean = false;
  link: string = '';
}

/** 块级节点。 */
export class MdBlock {
  type: string = 'paragraph';
  level: number = 0;
  text: string = '';
  items: string[] = [];
  ordered: boolean = false;
  lang: string = '';
  code: string = '';
}

export class MdType {
  static readonly HEADING: string = 'heading';
  static readonly PARAGRAPH: string = 'paragraph';
  static readonly LIST: string = 'list';
  static readonly CODE: string = 'code';
  static readonly QUOTE: string = 'quote';
  static readonly DIVIDER: string = 'divider';
}

/**
 * 轻量 Markdown 解析器（无第三方依赖）：
 * ATX 标题、无序/有序列表、围栏代码块、引用、分割线，以及行内粗体/斜体/代码/链接。
 */
export class MarkdownParser {
  static parse(source: string): MdBlock[] {
    const blocks: MdBlock[] = [];
    if (source.length === 0) {
      return blocks;
    }
    const lines: string[] = source.split('\n');
    let index = 0;
    while (index < lines.length) {
      const rawLine = lines[index].split('\r').join('');
      const line = rawLine.trim();
      if (line.length === 0) {
        index++;
        continue;
      }

      // 围栏代码块
      if (line.indexOf('```') === 0) {
        const block = new MdBlock();
        block.type = MdType.CODE;
        block.lang = line.substring(3).trim();
        index++;
        const codeLines: string[] = [];
        while (index < lines.length) {
          const codeLine = lines[index].split('\r').join('');
          if (codeLine.trim().indexOf('```') === 0) {
            index++;
            break;
          }
          codeLines.push(codeLine);
          index++;
        }
        block.code = codeLines.join('\n');
        blocks.push(block);
        continue;
      }

      // 分割线
      if (MarkdownParser.isDivider(line)) {
        const block = new MdBlock();
        block.type = MdType.DIVIDER;
        blocks.push(block);
        index++;
        continue;
      }

      // 标题
      const headingLevel = MarkdownParser.headingLevel(line);
      if (headingLevel > 0) {
        const block = new MdBlock();
        block.type = MdType.HEADING;
        block.level = headingLevel;
        block.text = line.substring(headingLevel).trim();
        blocks.push(block);
        index++;
        continue;
      }

      // 引用（连续多行合并）
      if (line.indexOf('>') === 0) {
        const quoteLines: string[] = [];
        while (index < lines.length) {
          const quoteLine = lines[index].split('\r').join('').trim();
          if (quoteLine.indexOf('>') !== 0) {
            break;
          }
          quoteLines.push(quoteLine.substring(1).trim());
          index++;
        }
        const block = new MdBlock();
        block.type = MdType.QUOTE;
        block.text = quoteLines.join('\n');
        blocks.push(block);
        continue;
      }

      // 列表
      if (MarkdownParser.isListLine(line)) {
        const block = new MdBlock();
        block.type = MdType.LIST;
        const firstOrdered = MarkdownParser.isOrderedLine(line);
        block.ordered = firstOrdered;
        while (index < lines.length) {
          const listLine = lines[index].split('\r').join('').trim();
          if (listLine.length === 0) {
            break;
          }
          if (MarkdownParser.isOrderedLine(listLine) !== firstOrdered || !MarkdownParser.isListLine(listLine)) {
            break;
          }
          block.items.push(MarkdownParser.stripListPrefix(listLine));
          index++;
        }
        blocks.push(block);
        continue;
      }

      // 普通段落：连续非空行合并，遇到其他块起始则停止
      const paragraphLines: string[] = [];
      while (index < lines.length) {
        const paraLine = lines[index].split('\r').join('').trim();
        if (paraLine.length === 0 || MarkdownParser.startsBlock(paraLine)) {
          break;
        }
        paragraphLines.push(paraLine);
        index++;
      }
      const block = new MdBlock();
      block.type = MdType.PARAGRAPH;
      block.text = paragraphLines.join('\n');
      blocks.push(block);
    }
    return blocks;
  }

  /** 解析行内样式。 */
  static parseInline(text: string): MdSpan[] {
    const spans: MdSpan[] = [];
    let index = 0;
    let plain = '';
    while (index < text.length) {
      const ch = text.charAt(index);
      if (ch === '\\' && index + 1 < text.length) {
        plain += text.charAt(index + 1);
        index += 2;
        continue;
      }
      if (text.substring(index, index + 3) === '***') {
        const end = text.indexOf('***', index + 3);
        if (end > index) {
          MarkdownParser.pushPlain(spans, plain);
          plain = '';
          const span = new MdSpan();
          span.text = text.substring(index + 3, end);
          span.bold = true;
          span.italic = true;
          spans.push(span);
          index = end + 3;
          continue;
        }
      }
      if (text.substring(index, index + 2) === '**') {
        const end = text.indexOf('**', index + 2);
        if (end > index) {
          MarkdownParser.pushPlain(spans, plain);
          plain = '';
          const span = new MdSpan();
          span.text = text.substring(index + 2, end);
          span.bold = true;
          spans.push(span);
          index = end + 2;
          continue;
        }
      }
      if (ch === '*' || ch === '_') {
        const end = text.indexOf(ch, index + 1);
        if (end > index + 1) {
          MarkdownParser.pushPlain(spans, plain);
          plain = '';
          const span = new MdSpan();
          span.text = text.substring(index + 1, end);
          span.italic = true;
          spans.push(span);
          index = end + 1;
          continue;
        }
      }
      if (ch === '`') {
        const end = text.indexOf('`', index + 1);
        if (end > index) {
          MarkdownParser.pushPlain(spans, plain);
          plain = '';
          const span = new MdSpan();
          span.text = text.substring(index + 1, end);
          span.code = true;
          spans.push(span);
          index = end + 1;
          continue;
        }
      }
      if (ch === '[') {
        const closeBracket = text.indexOf(']', index + 1);
        const openParen = closeBracket >= 0 ? text.indexOf('(', closeBracket + 1) : -1;
        const closeParen = openParen >= 0 ? text.indexOf(')', openParen + 1) : -1;
        if (closeBracket > index && openParen === closeBracket + 1 && closeParen > openParen) {
          MarkdownParser.pushPlain(spans, plain);
          plain = '';
          const span = new MdSpan();
          span.text = text.substring(index + 1, closeBracket);
          span.link = text.substring(openParen + 1, closeParen);
          spans.push(span);
          index = closeParen + 1;
          continue;
        }
      }
      plain += ch;
      index++;
    }
    MarkdownParser.pushPlain(spans, plain);
    return spans;
  }

  private static pushPlain(spans: MdSpan[], text: string): void {
    if (text.length === 0) {
      return;
    }
    const span = new MdSpan();
    span.text = text;
    spans.push(span);
  }

  private static headingLevel(line: string): number {
    let level = 0;
    while (level < line.length && level < 6 && line.charAt(level) === '#') {
      level++;
    }
    if (level > 0 && level < line.length && line.charAt(level) === ' ') {
      return level;
    }
    return 0;
  }

  private static isDivider(line: string): boolean {
    if (line.length < 3) {
      return false;
    }
    const first = line.charAt(0);
    if (first !== '-' && first !== '*' && first !== '_') {
      return false;
    }
    for (let i = 1; i < line.length; i++) {
      if (line.charAt(i) !== first) {
        return false;
      }
    }
    return true;
  }

  private static isOrderedLine(line: string): boolean {
    let i = 0;
    while (i < line.length && line.charAt(i) >= '0' && line.charAt(i) <= '9') {
      i++;
    }
    if (i === 0 || i >= line.length) {
      return false;
    }
    const mark = line.charAt(i);
    return (mark === '.' || mark === ')') && i + 1 < line.length && line.charAt(i + 1) === ' ';
  }

  private static isUnorderedLine(line: string): boolean {
    if (line.length < 2) {
      return false;
    }
    const mark = line.charAt(0);
    return (mark === '-' || mark === '*' || mark === '+') && line.charAt(1) === ' ';
  }

  private static isListLine(line: string): boolean {
    return MarkdownParser.isOrderedLine(line) || MarkdownParser.isUnorderedLine(line);
  }

  private static stripListPrefix(line: string): string {
    if (MarkdownParser.isUnorderedLine(line)) {
      return line.substring(2).trim();
    }
    let i = 0;
    while (i < line.length && line.charAt(i) >= '0' && line.charAt(i) <= '9') {
      i++;
    }
    return line.substring(i + 2).trim();
  }

  private static startsBlock(line: string): boolean {
    if (line.indexOf('```') === 0 || line.indexOf('>') === 0) {
      return true;
    }
    if (MarkdownParser.headingLevel(line) > 0 || MarkdownParser.isDivider(line)) {
      return true;
    }
    return MarkdownParser.isListLine(line);
  }
}

export class MarkdownStyle {
  static headingSize(level: number): number {
    if (level <= 1) {
      return AppFont.title;
    }
    if (level === 2) {
      return AppFont.xl;
    }
    if (level === 3) {
      return AppFont.lg;
    }
    return AppFont.base;
  }
}

/**
 * Markdown 渲染视图：助手回复、知识正文、AI 解读共用。
 * 链接点击通过 onLinkClick 回调交给宿主页面处理。
 */
@Component
export struct MarkdownView {
  @Prop @Watch('onMarkdownChange') markdown: string = '';
  @Prop textColor: string = AppColors.textPrimary;
  @Prop baseFontSize: number = AppFont.base;
  onLinkClick: (url: string) => void = () => {
  };
  @State private blocks: MdBlock[] = [];

  aboutToAppear(): void {
    this.blocks = MarkdownParser.parse(this.markdown);
  }

  onMarkdownChange(): void {
    this.blocks = MarkdownParser.parse(this.markdown);
  }

  @Builder
  InlineText(text: string, size: number, color: string, weight: FontWeight) {
    Text() {
      ForEach(MarkdownParser.parseInline(text), (span: MdSpan, spanIndex: number) => {
        Span(span.text)
          .fontSize(span.code ? size - 1 : size)
          .fontColor(span.link.length > 0 ? AppColors.brandBlue : (span.code ? AppColors.error : color))
          .fontWeight(span.bold ? FontWeight.Bold : weight)
          .fontStyle(span.italic ? FontStyle.Italic : FontStyle.Normal)
          .fontFamily(span.code ? 'monospace' : 'sans-serif')
          .decoration({
            type: span.link.length > 0 ? TextDecorationType.Underline : TextDecorationType.None,
            color: span.link.length > 0 ? AppColors.brandBlue : color
          })
          .onClick(() => {
            if (span.link.length > 0) {
              this.onLinkClick(span.link);
            }
          })
      }, (span: MdSpan, spanIndex: number) => `${spanIndex}-${span.text}`)
    }
    .width('100%')
    .lineHeight(size + 8)
  }

  @Builder
  HeadingBlock(block: MdBlock) {
    Column() {
      Text() {
        ForEach(MarkdownParser.parseInline(block.text), (span: MdSpan, spanIndex: number) => {
          Span(span.text)
            .fontSize(MarkdownStyle.headingSize(block.level))
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.textPrimary)
        }, (span: MdSpan, spanIndex: number) => `${spanIndex}-${span.text}`)
      }
      .width('100%')
      .lineHeight(MarkdownStyle.headingSize(block.level) + 8)
      if (block.level <= 2) {
        Divider()
          .color(AppColors.divider)
          .margin({ top: 6 })
      }
    }
    .width('100%')
    .margin({ top: block.level <= 2 ? AppSpace.md : AppSpace.xs, bottom: AppSpace.xs })
  }

  @Builder
  ParagraphBlock(block: MdBlock) {
    Column() {
      this.InlineText(block.text, this.baseFontSize, this.textColor, FontWeight.Normal)
    }
    .width('100%')
    .margin({ top: AppSpace.sm })
  }

  @Builder
  ListBlock(block: MdBlock) {
    Column() {
      ForEach(block.items, (item: string, itemIndex: number) => {
        Row() {
          Text(block.ordered ? `${itemIndex + 1}.` : '•')
            .fontSize(this.baseFontSize)
            .fontColor(block.ordered ? AppColors.textSecondary : AppColors.primary)
            .lineHeight(this.baseFontSize + 8)
            .width(block.ordered ? 22 : 16)
          Column() {
            this.InlineText(item, this.baseFontSize, this.textColor, FontWeight.Normal)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ top: 2 })
      }, (item: string, itemIndex: number) => `${itemIndex}-${item}`)
    }
    .width('100%')
    .margin({ top: AppSpace.sm })
  }

  @Builder
  CodeBlock(block: MdBlock) {
    Column() {
      if (block.lang.length > 0) {
        Text(block.lang)
          .fontSize(AppFont.xs)
          .fontColor(AppColors.textTertiary)
          .width('100%')
          .margin({ bottom: AppSpace.xs })
      }
      Text(block.code)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textPrimary)
        .fontFamily('monospace')
        .lineHeight(19)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppSpace.md)
    .backgroundColor('#F6F8FA')
    .borderRadius(AppRadius.sm)
    .margin({ top: AppSpace.sm })
  }

  @Builder
  QuoteBlock(block: MdBlock) {
    Row() {
      Column() {
        this.InlineText(block.text, this.baseFontSize, AppColors.textSecondary, FontWeight.Normal)
      }
      .layoutWeight(1)
      .padding({ left: AppSpace.md, top: AppSpace.sm, bottom: AppSpace.sm, right: AppSpace.md })
      .border({ width: { left: 3 }, color: { left: AppColors.primary } })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor(AppColors.bgPage)
    .borderRadius(AppRadius.xs)
    .margin({ top: AppSpace.sm })
  }

  build() {
    Column() {
      ForEach(this.blocks, (block: MdBlock, blockIndex: number) => {
        if (block.type === MdType.HEADING) {
          this.HeadingBlock(block)
        } else if (block.type === MdType.LIST) {
          this.ListBlock(block)
        } else if (block.type === MdType.CODE) {
          this.CodeBlock(block)
        } else if (block.type === MdType.QUOTE) {
          this.QuoteBlock(block)
        } else if (block.type === MdType.DIVIDER) {
          Divider()
            .color(AppColors.border)
            .margin({ top: AppSpace.md, bottom: AppSpace.md })
        } else {
          this.ParagraphBlock(block)
        }
      }, (block: MdBlock, blockIndex: number) => `${blockIndex}-${block.type}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}