import AVFoundation
import UIKit

final class PlayerLayerView: UIView {
  let playerLayer: AVPlayerLayer

  init(playerLayer: AVPlayerLayer) {
    self.playerLayer = playerLayer
    super.init(frame: .zero)
    backgroundColor = .clear
    layer.addSublayer(playerLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    playerLayer.frame = bounds
    CATransaction.commit()
  }
}
