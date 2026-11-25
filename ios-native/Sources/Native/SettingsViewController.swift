import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let table = UITableView(frame: .zero, style: .insetGrouped)
  private let closeButton = UIButton(type: .system)
  private var account = AccountInfo()
  private let themes = AppTheme.allCases
  private let qualities: [(String, Int)] = [("1080P", 80), ("720P", 64), ("480P", 32)]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background
    navigationItem.title = "设置"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "xmark"),
      style: .plain,
      target: self,
      action: #selector(close)
    )

    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: view.topAnchor),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    BiliAPI.shared.account { [weak self] info in
      self?.account = info
      self?.table.reloadData()
    }
  }

  @objc private func close() {
    dismiss(animated: true)
  }

  func numberOfSections(in tableView: UITableView) -> Int { return 4 }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0: return themes.count
    case 1: return qualities.count
    case 2: return account.loggedIn ? 2 : 1
    default: return 2
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "外观"
    case 1: return "默认清晰度"
    case 2: return "账号"
    default: return "关于"
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.04)
    cell.textLabel?.textColor = NativeTheme.foreground
    cell.detailTextLabel?.textColor = NativeTheme.secondary
    switch indexPath.section {
    case 0:
      let theme = themes[indexPath.row]
      cell.textLabel?.text = theme.title
      cell.accessoryType = ThemeManager.shared.theme == theme ? .checkmark : .none
      cell.tintColor = NativeTheme.accent
    case 1:
      let quality = qualities[indexPath.row]
      cell.textLabel?.text = quality.0
      cell.accessoryType = ThemeManager.shared.quality == quality.1 ? .checkmark : .none
      cell.tintColor = NativeTheme.accent
    case 2:
      if account.loggedIn {
        if indexPath.row == 0 {
          cell.textLabel?.text = account.name.isEmpty ? "已登录" : account.name
          cell.accessoryType = .none
        } else {
          cell.textLabel?.text = "退出登录"
          cell.textLabel?.textColor = NativeTheme.accent
          cell.accessoryType = .none
        }
      } else {
        cell.textLabel?.text = "未登录"
        cell.accessoryType = .none
      }
    default:
      if indexPath.row == 0 {
        cell.textLabel?.text = "O11A1 0.5.0 (108)"
      } else {
        cell.textLabel?.text = "纯原生 · 无 WebView"
      }
      cell.accessoryType = .none
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch indexPath.section {
    case 0:
      ThemeManager.shared.theme = themes[indexPath.row]
      table.reloadData()
    case 1:
      ThemeManager.shared.quality = qualities[indexPath.row].1
      table.reloadData()
    case 2:
      if account.loggedIn && indexPath.row == 1 {
        BiliAPI.shared.logout()
        account = AccountInfo()
        table.reloadData()
      }
    default:
      break
    }
  }
}
