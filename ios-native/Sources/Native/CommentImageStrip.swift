import UIKit

/// A compact comment picture grid. One or two pictures use half-width tiles;
/// three or more use three columns. Tapping any tile opens the full-screen
/// pager.
final class CommentImageStrip: UIView {
  private let stack = UIStackView()
  private var urls: [String] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    stack.axis = .vertical
    stack.spacing = 6
    stack.alignment = .fill
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    isHidden = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setImages(_ urls: [String], compact: Bool = false) {
    self.urls = urls.filter { !$0.isEmpty }
    stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    guard !self.urls.isEmpty else {
      isHidden = true
      return
    }
    isHidden = false
    let columns = self.urls.count <= 2 ? 2 : 3
    let tileHeight: CGFloat = compact
      ? (columns == 2 ? 92 : 76)
      : (columns == 2 ? 136 : 104)
    var index = 0
    while index < self.urls.count {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 6
      row.distribution = .fillEqually
      row.alignment = .fill
      row.heightAnchor.constraint(equalToConstant: tileHeight).isActive = true
      for _ in 0..<columns {
        if index < self.urls.count {
          row.addArrangedSubview(tile(url: self.urls[index], index: index))
          index += 1
        } else {
          let spacer = UIView()
          spacer.backgroundColor = .clear
          row.addArrangedSubview(spacer)
        }
      }
      stack.addArrangedSubview(row)
    }
  }

  private func tile(url: String, index: Int) -> UIView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 9
    imageView.layer.cornerCurve = .continuous
    imageView.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.14)
    imageView.isUserInteractionEnabled = true
    imageView.tag = index
    imageView.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    ImageLoader.shared.load(url, into: imageView)
    return imageView
  }

  @objc private func tapped(_ gesture: UITapGestureRecognizer) {
    guard let index = gesture.view?.tag, urls.indices.contains(index) else {
      return
    }
    CommentImageViewer.present(urls, startIndex: index)
  }
}

final class CommentImageViewer: UIViewController, UIScrollViewDelegate {
  private let images: [String]
  private let startIndex: Int
  private let scroll = UIScrollView()
  private let pager = UIPageControl()
  private let close = UIButton(type: .system)
  private var didSetInitialPage = false

  init(images: [String], startIndex: Int) {
    self.images = images
    self.startIndex = max(0, min(startIndex, images.count - 1))
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    scroll.isPagingEnabled = true
    scroll.showsHorizontalScrollIndicator = false
    scroll.showsVerticalScrollIndicator = false
    scroll.delegate = self
    view.addSubview(scroll)

    for url in images {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.backgroundColor = .black
      ImageLoader.shared.load(url, into: imageView)
      scroll.addSubview(imageView)
    }

    pager.numberOfPages = max(1, images.count)
    pager.currentPage = startIndex
    pager.currentPageIndicatorTintColor = .white
    pager.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.32)
    pager.isUserInteractionEnabled = false
    view.addSubview(pager)

    let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
    close.setImage(UIImage(systemName: "xmark", withConfiguration: configuration),
                   for: .normal)
    close.tintColor = .white
    close.backgroundColor = UIColor.black.withAlphaComponent(0.42)
    close.layer.cornerRadius = 18
    close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    view.addSubview(close)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let size = view.bounds.size
    scroll.frame = view.bounds
    scroll.contentSize = CGSize(width: size.width * CGFloat(max(1, images.count)),
                                height: size.height)
    for (index, subview) in scroll.subviews.enumerated() {
      subview.frame = CGRect(x: size.width * CGFloat(index), y: 0,
                             width: size.width, height: size.height)
    }
    pager.frame = CGRect(x: 0, y: size.height - view.safeAreaInsets.bottom - 34,
                         width: size.width, height: 20)
    close.frame = CGRect(x: size.width - 54, y: view.safeAreaInsets.top + 8,
                         width: 36, height: 36)
    if !didSetInitialPage {
      didSetInitialPage = true
      scroll.contentOffset = CGPoint(x: size.width * CGFloat(startIndex), y: 0)
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.bounds.width > 0 else { return }
    let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
    pager.currentPage = max(0, min(images.count - 1, page))
  }

  @objc private func closeTapped() {
    dismiss(animated: true)
  }

  static func present(_ images: [String], startIndex: Int) {
    guard !images.isEmpty else { return }
    let controller = CommentImageViewer(images: images, startIndex: startIndex)
    var top = keyWindow()?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    top?.present(controller, animated: true)
  }

  private static func keyWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    return scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
  }
}
