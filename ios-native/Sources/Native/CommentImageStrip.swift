import UIKit

/// A compact comment picture grid. One or two pictures use half-width tiles;
/// three or more use three columns. Tapping any tile opens the full-screen
/// pager.
final class CommentImageStrip: UIView {
  private let stack = UIStackView()
  private var urls: [String] = []
  private var heightConstraint: NSLayoutConstraint?

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
    heightConstraint = heightAnchor.constraint(equalToConstant: 0)
    heightConstraint?.isActive = true
    isHidden = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setImages(_ urls: [String], compact: Bool = false) {
    self.urls = urls.filter { !$0.isEmpty }
    stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    guard !self.urls.isEmpty else {
      heightConstraint?.constant = 0
      isHidden = true
      return
    }
    isHidden = false
    let columns = self.urls.count <= 2 ? 2 : 3
    let tileHeight: CGFloat = compact
      ? (columns == 2 ? 92 : 76)
      : (columns == 2 ? 136 : 104)
    let rows = (self.urls.count + columns - 1) / columns
    heightConstraint?.constant = CGFloat(rows) * tileHeight
      + CGFloat(max(0, rows - 1)) * 6
    var index = 0
    while index < self.urls.count {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 6
      row.distribution = .fillEqually
      row.alignment = .fill
      row.translatesAutoresizingMaskIntoConstraints = false
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
    imageView.translatesAutoresizingMaskIntoConstraints = false
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

final class CommentImageViewer: UIViewController, UIScrollViewDelegate,
  UIGestureRecognizerDelegate {
  private let images: [String]
  private let startIndex: Int
  private let scroll = UIScrollView()
  private let pager = UIPageControl()
  private var didSetInitialPage = false
  private var dismissPan: UIPanGestureRecognizer?

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

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    dismissPan = pan
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

  @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
    let translation = max(0, gesture.translation(in: view).y)
    switch gesture.state {
    case .began:
      break
    case .changed:
      let scale = max(0.72, 1 - translation / max(1, view.bounds.height) * 0.55)
      view.transform = CGAffineTransform(translationX: 0, y: translation)
        .scaledBy(x: scale, y: scale)
      view.alpha = max(0.25, 1 - translation / 520)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).y
      if translation > 90 || velocity > 650 {
        UIView.animate(withDuration: 0.22, delay: 0,
                       options: [.curveEaseIn]) {
          self.view.transform = CGAffineTransform(
            translationX: 0, y: max(translation, self.view.bounds.height * 0.55))
            .scaledBy(x: 0.7, y: 0.7)
          self.view.alpha = 0
        } completion: { _ in
          self.dismiss(animated: false)
        }
      } else {
        UIView.animate(withDuration: 0.24, delay: 0,
                       usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.3) {
          self.view.transform = .identity
          self.view.alpha = 1
        }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === dismissPan else { return true }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return translation.y > abs(translation.x) * 1.1
      || velocity.y > abs(velocity.x) * 1.1
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
