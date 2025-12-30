import SwiftUI
import UIKit

struct MoodMetrics {
    let latencyMs: Double
    let jitterMs: Double
    let lossPercent: Double
    let dnsMs: Double
}

final class MoodOrbLayer: CALayer {
    private let circle = CAShapeLayer()
    
    override init() {
        super.init()
        setup()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        circle.fillColor = UIColor.systemTeal.cgColor
        addSublayer(circle)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = UIBezierPath(ovalIn: rect)
        circle.path = path.cgPath
    }
    
    func animate(for m: MoodMetrics) {
        circle.removeAllAnimations()
        removeAllAnimations()
        
        let excellent = m.lossPercent < 0.5 && m.latencyMs < 50 && m.jitterMs < 10 && m.dnsMs < 80
        let highLatency = m.latencyMs >= 150
        let highJitter = m.jitterMs >= 30
        let hasLoss = m.lossPercent >= 2.0
        let dnsSlow = m.dnsMs >= 200
        
        if excellent {
            let breathe = CABasicAnimation(keyPath: "transform.scale")
            breathe.fromValue = 0.95
            breathe.toValue = 1.05
            breathe.duration = 3.0
            breathe.autoreverses = true
            breathe.repeatCount = .infinity
            add(breathe, forKey: "breathe")
        }
        if highLatency {
            let stretchX = CABasicAnimation(keyPath: "transform.scale.x")
            stretchX.fromValue = 1.0
            stretchX.toValue = 1.2
            stretchX.duration = 0.8
            stretchX.autoreverses = true
            stretchX.repeatCount = .infinity
            add(stretchX, forKey: "stretch")
        }
        if highJitter {
            let wobble = CAKeyframeAnimation(keyPath: "transform.rotation")
            wobble.values = [-0.05, 0.05, -0.04, 0.04, 0]
            wobble.duration = 0.5
            wobble.repeatCount = .infinity
            add(wobble, forKey: "wobble")
        }
        if hasLoss {
            let shake = CAKeyframeAnimation(keyPath: "position")
            let p = position
            shake.values = [
                NSValue(cgPoint: CGPoint(x: p.x - 3, y: p.y)),
                NSValue(cgPoint: CGPoint(x: p.x + 3, y: p.y)),
                NSValue(cgPoint: CGPoint(x: p.x - 2, y: p.y)),
                NSValue(cgPoint: CGPoint(x: p.x + 2, y: p.y)),
                NSValue(cgPoint: p)
            ]
            shake.duration = 0.3
            shake.repeatCount = .infinity
            add(shake, forKey: "shake")
            
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.6
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            add(pulse, forKey: "pulse")
        }
        if dnsSlow {
            let blink = CABasicAnimation(keyPath: "opacity")
            blink.fromValue = 1.0
            blink.toValue = 0.3
            blink.duration = 1.2
            blink.autoreverses = true
            blink.repeatCount = .infinity
            blink.beginTime = CACurrentMediaTime() + 0.4
            add(blink, forKey: "blink")
        }
    }
}

struct MoodOrb: UIViewRepresentable {
    let metrics: MoodMetrics
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = MoodOrbLayer()
        layer.frame = CGRect(x: 0, y: 0, width: 160, height: 160)
        view.layer.addSublayer(layer)
        layer.animate(for: metrics)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.compactMap({ $0 as? MoodOrbLayer }).first {
            layer.frame = uiView.bounds
            layer.animate(for: metrics)
        }
    }
}
