import SwiftUI
import UIKit

final class ParticleEmitterHost: UIView {
    let emitter = CAEmitterLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(emitter)
        emitter.emitterShape = .rectangle
        emitter.birthRate = 0
        emitter.emitterSize = bounds.size
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.renderMode = .additive
        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.systemTeal, renderingMode: .alwaysOriginal).cgImage
        cell.alphaRange = 0.4
        cell.alphaSpeed = -0.35
        cell.scale = 0.02
        cell.scaleRange = 0.03
        cell.velocity = 40
        cell.velocityRange = 60
        cell.emissionRange = .pi * 2
        cell.lifetime = 2.0
        emitter.emitterCells = [cell]
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.emitterSize = bounds.size
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.frame = bounds
    }
}

struct ParticleEmitterView: UIViewRepresentable {
    let active: Bool
    func makeUIView(context: Context) -> ParticleEmitterHost {
        ParticleEmitterHost()
    }
    func updateUIView(_ uiView: ParticleEmitterHost, context: Context) {
        uiView.emitter.birthRate = active ? 120 : 0
    }
}
