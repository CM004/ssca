//
//  ConfettiView.swift
//  The Living Prompt Tree
//
//  Native iOS confetti effect using CAEmitterLayer.
//

import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {

    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView()
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}
}

class ConfettiUIView: UIView {

    private let emitter = CAEmitterLayer()
    private var configured = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !configured, bounds.width > 0 else { return }
        configured = true

        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterShape = .line

        let colors: [UIColor] = [
            .systemGreen, .systemYellow, .systemOrange,
            .systemCyan, .systemPink, .systemPurple,
            .systemRed, .systemMint,
        ]

        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 6
            cell.velocity = 180
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3.0
            cell.spinRange = 6.0
            cell.scale = 0.12
            cell.scaleRange = 0.06
            cell.color = color.cgColor

            let size = CGSize(width: 12, height: 8)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 1.5).fill()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cell.contents = image?.cgImage

            return cell
        }

        layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.emitter.birthRate = 0
        }
    }
}
