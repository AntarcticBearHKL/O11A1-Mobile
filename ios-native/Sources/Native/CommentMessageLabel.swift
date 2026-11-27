import UIKit

/// UILabel that understands Bilibili's inline emote shortcodes (`[爱心]`),
/// numeric HTML entities and ordinary Unicode emoji. Emote artwork is loaded
/// asynchronously at a fixed inline size, so the line height never jumps.
final class CommentMessageLabel: UILabel {
  private var rawText = ""
  private var emoteMap: [String: String] = [:]
  private var emoteImages: [String: UIImage] = [:]
  private var failedEmotes = Set<String>()
  private var renderToken = 0
  private var textFont = UIFont.systemFont(ofSize: 16.5)
  private var textColorValue = UIColor.label
  private var lineHeight: CGFloat = 28
  private var tracking: CGFloat = 0.15
  private var emoteSize: CGFloat = 20
  private var paragraphSpacing: CGFloat = 6

  override init(frame: CGRect) {
    super.init(frame: frame)
    numberOfLines = 0
    lineBreakMode = .byWordWrapping
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    text: String,
    emotes: [String: String],
    font: UIFont,
    color: UIColor,
    lineHeight: CGFloat,
    tracking: CGFloat = 0.15,
    emoteSize: CGFloat = 20,
    paragraphSpacing: CGFloat = 6
  ) {
    renderToken += 1
    let token = renderToken
    rawText = text
    emoteMap = emotes
    emoteImages.removeAll()
    failedEmotes.removeAll()
    textFont = font
    textColorValue = color
    self.lineHeight = lineHeight
    self.tracking = tracking
    self.emoteSize = emoteSize
    self.paragraphSpacing = paragraphSpacing
    accessibilityLabel = text

    for (key, url) in emotes {
      if let cached = ImageLoader.shared.cachedImage(url) {
        emoteImages[key] = cached
        continue
      }
      ImageLoader.shared.loadImage(url) { [weak self] image in
        guard let self = self, token == self.renderToken else { return }
        if let image = image {
          self.emoteImages[key] = image
        } else {
          self.failedEmotes.insert(key)
        }
        self.render()
      }
    }
    render()
  }

  private func render() {
    let style = NSMutableParagraphStyle()
    style.minimumLineHeight = lineHeight
    style.maximumLineHeight = lineHeight
    style.lineBreakMode = .byWordWrapping
    style.paragraphSpacing = paragraphSpacing
    let attributes: [NSAttributedString.Key: Any] = [
      .font: textFont,
      .foregroundColor: textColorValue,
      .kern: tracking,
      .paragraphStyle: style,
    ]

    let result = NSMutableAttributedString(string: "")
    let keys = emoteMap.keys.filter { !$0.isEmpty }.sorted { $0.count > $1.count }
    var index = rawText.startIndex
    while index < rawText.endIndex {
      if let key = keys.first(where: { rawText[index...].hasPrefix($0) }) {
        if failedEmotes.contains(key) {
          result.append(NSAttributedString(
            string: CommentMessageLabel.fallbackEmoji(key),
            attributes: attributes))
        } else {
          result.append(emoteAttachment(for: key))
        }
        index = rawText.index(index, offsetBy: key.count)
      } else {
        let next = rawText.index(after: index)
        result.append(NSAttributedString(
          string: String(rawText[index..<next]),
          attributes: attributes))
        index = next
      }
    }
    attributedText = result
  }

  private func emoteAttachment(for key: String) -> NSAttributedString {
    let image = emoteImages[key] ?? placeholderImage()
    let attachment = NSTextAttachment()
    attachment.image = image
    let baseline = (textFont.capHeight - emoteSize) / 2
    attachment.bounds = CGRect(x: 0, y: baseline,
                               width: emoteSize, height: emoteSize)
    return NSAttributedString(attachment: attachment)
  }

  private static func fallbackEmoji(_ key: String) -> String {
    let name = key.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    let map: [String: String] = [
      "大笑": "😄", "笑哭": "😂", "妙啊": "👏", "doge": "🐶",
      "吃瓜": "🍉", "星星眼": "🤩", "打call": "💪", "OK": "👌",
      "喜极而泣": "😭", "笑": "😊", "呲牙": "😁", "调皮": "😜",
      "思考": "🤔", "辣眼睛": "😵", "嫌弃": "😒", "奋斗": "💪",
      "加油": "💪", "藏狐": "🦊", "滑稽": "🙂", "惊喜": "😲",
      "支持": "👏", "热词系列_泪目": "🥲", "热词系列_好耶": "🥳",
    ]
    return map[name] ?? key
  }

  private func placeholderImage() -> UIImage {
    let size = CGSize(width: emoteSize, height: emoteSize)
    return UIGraphicsImageRenderer(size: size).image { context in
      UIColor.tertiaryLabel.withAlphaComponent(0.16).setFill()
      UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                   cornerRadius: max(3, emoteSize * 0.22)).fill()
    }
  }
}
