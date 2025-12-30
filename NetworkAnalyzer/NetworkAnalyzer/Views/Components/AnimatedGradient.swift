import SwiftUI
import UIKit

final class AnimatedGradientLayer: CAGradientLayer {
    override init() {
        super.init()
        colors = [
            UIColor.systemBlue.withAlphaComponent(0.18).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.18).cgColor
        ]
        startPoint = CGPoint(x: 0, y: 0)
        endPoint = CGPoint(x: 1, y: 1)
        let anim1 = CABasicAnimation(keyPath: "startPoint")
        anim1.fromValue = CGPoint(x: 0, y: 0)
        anim1.toValue = CGPoint(x: 1, y: 0)
        anim1.duration = 6
        anim1.autoreverses = true
        anim1.repeatCount = .infinity
        add(anim1, forKey: "start")
        let anim2 = CABasicAnimation(keyPath: "endPoint")
        anim2.fromValue = CGPoint(x: 1, y: 1)
        anim2.toValue = CGPoint(x: 0, y: 1)
        anim2.duration = 6
        anim2.autoreverses = true
        anim2.repeatCount = .infinity
        add(anim2, forKey: "end")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

struct AnimatedGradient: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        let g = AnimatedGradientLayer()
        g.frame = v.bounds
        v.layer.addSublayer(g)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.layer.sublayers?.forEach { $0.frame = uiView.bounds }
    }
}
