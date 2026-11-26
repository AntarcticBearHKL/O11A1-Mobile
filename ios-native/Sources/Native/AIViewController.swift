import UIKit

final class AIViewController: UIViewController, UITextViewDelegate {
  private let endpointField = UITextField()
  private let keyField = UITextField()
  private let modelField = UITextField()
  private let promptView = UITextView()
  private let outputView = UITextView()
  private let runButton = UIButton(type: .system)
  private let defaults = UserDefaults.standard

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    let scroll = UIScrollView()
    view.addSubview(scroll)
    let root = UIStackView()
    root.axis = .vertical
    root.spacing = 8
    scroll.addSubview(root)
    [scroll, root].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: view.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      root.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      root.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      root.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 58),
      root.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
      root.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])

    let title = UILabel()
    title.text = "AI 养鱼"
    title.font = NativeTheme.titleFont(26)
    title.textColor = NativeTheme.foreground
    root.addArrangedSubview(title)

    let hint = UILabel()
    hint.text = "OpenAI 兼容接口 · 真实请求 · 结果只在本机显示\n没有 API Key 时不会伪造结果"
    hint.font = NativeTheme.bodyFont(12)
    hint.textColor = NativeTheme.secondary
    hint.numberOfLines = 0
    root.addArrangedSubview(hint)
    root.setCustomSpacing(16, after: hint)

    root.addArrangedSubview(label("API 地址"))
    configure(endpointField, placeholder: "https://api.deepseek.com/chat/completions")
    endpointField.text = defaults.string(forKey: "ai_endpoint") ?? endpointField.placeholder
    root.addArrangedSubview(endpointField)

    root.addArrangedSubview(label("API Key"))
    configure(keyField, placeholder: "sk-...")
    keyField.isSecureTextEntry = true
    keyField.text = defaults.string(forKey: "ai_key") ?? ""
    root.addArrangedSubview(keyField)

    root.addArrangedSubview(label("模型"))
    configure(modelField, placeholder: "deepseek-chat")
    modelField.text = defaults.string(forKey: "ai_model") ?? modelField.placeholder
    root.addArrangedSubview(modelField)

    root.addArrangedSubview(label("饲料 / 提示词"))
    promptView.font = NativeTheme.bodyFont(13)
    promptView.textColor = NativeTheme.foreground
    promptView.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    promptView.layer.cornerRadius = 12
    promptView.layer.cornerCurve = .continuous
    promptView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    promptView.text = defaults.string(forKey: "ai_prompt")
      ?? "用三句话点评今天 B 站最热的一条视频，并给出一个养鱼式的比喻。"
    promptView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    promptView.delegate = self
    root.addArrangedSubview(promptView)

    runButton.setTitle("生成", for: .normal)
    runButton.setTitleColor(.white, for: .normal)
    runButton.titleLabel?.font = NativeTheme.titleFont(15)
    runButton.backgroundColor = NativeTheme.accent
    runButton.layer.cornerRadius = 16
    runButton.layer.cornerCurve = .continuous
    runButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    runButton.addTarget(self, action: #selector(run), for: .touchUpInside)
    root.addArrangedSubview(runButton)

    outputView.font = NativeTheme.bodyFont(14)
    outputView.textColor = NativeTheme.foreground
    outputView.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    outputView.layer.cornerRadius = 16
    outputView.layer.cornerCurve = .continuous
    outputView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
    outputView.text = "等待投喂。"
    outputView.isEditable = false
    outputView.isSelectable = true
    outputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
    root.addArrangedSubview(outputView)
  }

  private func label(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = NativeTheme.bodyFont(12)
    label.textColor = NativeTheme.secondary
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }

  private func configure(_ field: UITextField, placeholder: String) {
    field.placeholder = placeholder
    field.font = NativeTheme.bodyFont(13)
    field.textColor = NativeTheme.foreground
    field.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    field.layer.cornerRadius = 12
    field.layer.cornerCurve = .continuous
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    field.leftViewMode = .always
    field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    field.rightViewMode = .always
    field.heightAnchor.constraint(equalToConstant: 42).isActive = true
  }

  @objc private func run() {
    let endpoint = endpointField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let key = keyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let model = modelField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let prompt = promptView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    defaults.set(endpoint, forKey: "ai_endpoint")
    defaults.set(key, forKey: "ai_key")
    defaults.set(model, forKey: "ai_model")
    defaults.set(prompt, forKey: "ai_prompt")
    if key.isEmpty {
      outputView.text = "需要先填写 API Key。\n这里不会在没 Key 时伪造结果。"
      return
    }
    if prompt.isEmpty {
      outputView.text = "先写点饲料 / 提示词。"
      return
    }
    runButton.isEnabled = false
    runButton.setTitle("生成中…", for: .normal)
    outputView.text = "正在请求 AI…"
    BiliAPI.shared.aiChat(endpoint: endpoint, apiKey: key, model: model, prompt: prompt) { [weak self] result in
      guard let self = self else { return }
      self.runButton.isEnabled = true
      self.runButton.setTitle("生成", for: .normal)
      switch result {
      case .failure(let error):
        self.outputView.text = "请求失败：\n" + error.localizedDescription
      case .success(let text):
        self.outputView.text = text
      }
    }
  }
}
