import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import LegacyComponents

private let emojiFont = Font.regular(28.0)
private let textFont = Font.regular(15.0)

final class ModernCallControllerKeyPreviewNode: ASDisplayNode {
    private let keyTextNode: ASTextNode
    private let titleTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    private let topBackgroundNode: ASDisplayNode
    private let bottomBackgroundNode: ASDisplayNode
    private let okButtonNode: HighlightableButtonNode
    
    private let dismiss: () -> Void
    
    init(keyText: String, titleText: String, infoText: String, isDark: Bool, dismiss: @escaping () -> Void) {
        self.keyTextNode = ASTextNode()
        self.keyTextNode.displaysAsynchronously = false
        self.titleTextNode = ASTextNode()
        self.titleTextNode.displaysAsynchronously = false
        self.infoTextNode = ASTextNode()
        self.infoTextNode.displaysAsynchronously = false
        self.okButtonNode = HighlightableButtonNode()
        self.topBackgroundNode = ASDisplayNode()
        self.bottomBackgroundNode = ASDisplayNode()
        self.dismiss = dismiss
        
        super.init()
        
        self.keyTextNode.attributedText = NSAttributedString(string: keyText, attributes: [NSAttributedString.Key.font: Font.regular(48.0), NSAttributedString.Key.kern: 6 as NSNumber])
        
        self.titleTextNode.attributedText = NSAttributedString(string: titleText, font: Font.semibold(16), textColor: .white, paragraphAlignment: .center)
        
        self.infoTextNode.attributedText = NSAttributedString(string: infoText, font: Font.regular(16), textColor: UIColor.white, paragraphAlignment: .center)
        
        self.okButtonNode.setAttributedTitle(NSAttributedString(string: "OK", font: Font.regular(20), textColor: .white, paragraphAlignment: .center), for: .normal)
        
        self.okButtonNode.addTarget(self, action: #selector(okButtonTapped), forControlEvents: .touchUpInside)
        
        layer.cornerRadius = 20
        
        self.topBackgroundNode.layer.cornerRadius = 20
        self.topBackgroundNode.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.topBackgroundNode.backgroundColor = isDark
            ? .black.withAlphaComponent(0.5)
            : .white.withAlphaComponent(0.25)
        
        self.bottomBackgroundNode.layer.cornerRadius = 20
        self.bottomBackgroundNode.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        self.bottomBackgroundNode.backgroundColor = isDark
            ? .black.withAlphaComponent(0.5)
            : .white.withAlphaComponent(0.25)
        
        self.addSubnode(self.topBackgroundNode)
        self.addSubnode(self.bottomBackgroundNode)
        self.addSubnode(self.keyTextNode)
        self.addSubnode(self.titleTextNode)
        self.addSubnode(self.infoTextNode)
        self.addSubnode(self.okButtonNode)
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) -> CGFloat {
        let keyTextSize = self.keyTextNode.measure(CGSize(width: 300.0, height: 300.0))
        transition.updateFrame(node: self.keyTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - keyTextSize.width) / 2), y: 20), size: keyTextSize))
        
        let titleTextY = 20 + keyTextSize.height + 10
        let titleTextSize = self.titleTextNode.measure(CGSize(width: size.width - 32, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - titleTextSize.width) / 2.0), y: titleTextY), size: titleTextSize))
        
        let infoTextY = titleTextY + titleTextSize.height + 10
        let infoTextSize = self.infoTextNode.measure(CGSize(width: size.width - 32.0, height: CGFloat.greatestFiniteMagnitude))
        transition.updateFrame(node: self.infoTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - infoTextSize.width) / 2.0), y: infoTextY), size: infoTextSize))
        
        let okButtonY = infoTextY + infoTextSize.height + 20 + UIScreenPixel
        transition.updateFrame(node: self.okButtonNode, frame: CGRect(origin: CGPoint(x: 0, y: okButtonY), size: CGSize(width: size.width, height: 56)))
        
        self.topBackgroundNode.frame = CGRect(origin: .zero, size: CGSize(width: size.width, height: infoTextY + infoTextSize.height + 20))
        self.bottomBackgroundNode.frame = CGRect(origin: CGPoint(x: 0, y: okButtonY), size: CGSize(width: size.width, height: 56))
        
        return okButtonY + 56
    }
    
    func animateIn(from rect: CGRect, fromNode: ASDisplayNode) {
        let convertedRect = supernode?.convert(rect, to: self) ?? .zero
        
        self.keyTextNode.alpha = 1
        print("dbg::animateIn", CGPoint(x: convertedRect.midX, y: convertedRect.midY))
        self.keyTextNode.layer.animatePosition(from: CGPoint(x: convertedRect.midX, y: convertedRect.midY), to: self.keyTextNode.layer.position, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        self.keyTextNode.layer.animateScale(from: convertedRect.size.width / self.keyTextNode.frame.size.width, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        
        self.titleTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.infoTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.okButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.topBackgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.bottomBackgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
    }
    
    func animateOut(to rect: CGRect, toNode: ASDisplayNode, completion: @escaping () -> Void) {
        let convertedRect = supernode?.convert(rect, to: self) ?? .zero
        
        self.keyTextNode.layer.animatePosition(from: self.keyTextNode.layer.position, to: CGPoint(x: convertedRect.midX + 2.0, y: convertedRect.midY), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { [weak keyTextNode] _ in
            keyTextNode?.alpha = 0
            completion()
        })
        self.keyTextNode.layer.animateScale(from: 1.0, to: convertedRect.size.width / (self.keyTextNode.frame.size.width - 2.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        
        self.titleTextNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        self.infoTextNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        self.okButtonNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        self.topBackgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        self.bottomBackgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
    }
    
    @objc func okButtonTapped() {
        self.dismiss()
    }
}

final class CallControllerKeyPreviewNode: ASDisplayNode {
    private let keyTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    
    private let effectView: UIVisualEffectView
    
    private let dismiss: () -> Void
    
    init(keyText: String, infoText: String, dismiss: @escaping () -> Void) {
        self.keyTextNode = ASTextNode()
        self.keyTextNode.displaysAsynchronously = false
        self.infoTextNode = ASTextNode()
        self.infoTextNode.displaysAsynchronously = false
        self.dismiss = dismiss
        
        self.effectView = UIVisualEffectView()
        if #available(iOS 9.0, *) {
        } else {
            self.effectView.effect = UIBlurEffect(style: .dark)
            self.effectView.alpha = 0.0
        }
        
        super.init()
        
        self.keyTextNode.attributedText = NSAttributedString(string: keyText, attributes: [NSAttributedString.Key.font: Font.regular(58.0), NSAttributedString.Key.kern: 11.0 as NSNumber])
        
        self.infoTextNode.attributedText = NSAttributedString(string: infoText, font: Font.regular(14.0), textColor: UIColor.white, paragraphAlignment: .center)
        
        self.view.addSubview(self.effectView)
        self.addSubnode(self.keyTextNode)
        self.addSubnode(self.infoTextNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.effectView.frame = CGRect(origin: CGPoint(), size: size)
        
        let keyTextSize = self.keyTextNode.measure(CGSize(width: 300.0, height: 300.0))
        transition.updateFrame(node: self.keyTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - keyTextSize.width) / 2) + 6.0, y: floor((size.height - keyTextSize.height) / 2) - 50.0), size: keyTextSize))
        
        let infoTextSize = self.infoTextNode.measure(CGSize(width: size.width - 32.0, height: CGFloat.greatestFiniteMagnitude))
        transition.updateFrame(node: self.infoTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - infoTextSize.width) / 2.0), y: floor((size.height - infoTextSize.height) / 2.0) + 30.0), size: infoTextSize))
    }
    
    func animateIn(from rect: CGRect, fromNode: ASDisplayNode) {
        self.keyTextNode.layer.animatePosition(from: CGPoint(x: rect.midX, y: rect.midY), to: self.keyTextNode.layer.position, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        if let transitionView = fromNode.view.snapshotView(afterScreenUpdates: false) {
            self.view.addSubview(transitionView)
            transitionView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
            transitionView.layer.animatePosition(from: CGPoint(x: rect.midX, y: rect.midY), to: self.keyTextNode.layer.position, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { [weak transitionView] _ in
                transitionView?.removeFromSuperview()
            })
            transitionView.layer.animateScale(from: 1.0, to: self.keyTextNode.frame.size.width / rect.size.width, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        }
        self.keyTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
        
        self.keyTextNode.layer.animateScale(from: rect.size.width / self.keyTextNode.frame.size.width, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        
        self.infoTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        
        UIView.animate(withDuration: 0.3, animations: {
            if #available(iOS 9.0, *) {
                self.effectView.effect = UIBlurEffect(style: .dark)
            } else {
                self.effectView.alpha = 1.0
            }
        })
    }
    
    func animateOut(to rect: CGRect, toNode: ASDisplayNode, completion: @escaping () -> Void) {
        self.keyTextNode.layer.animatePosition(from: self.keyTextNode.layer.position, to: CGPoint(x: rect.midX + 2.0, y: rect.midY), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { _ in
            completion()
        })
        self.keyTextNode.layer.animateScale(from: 1.0, to: rect.size.width / (self.keyTextNode.frame.size.width - 2.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        
        self.infoTextNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
        
        UIView.animate(withDuration: 0.3, animations: {
            if #available(iOS 9.0, *) {
                self.effectView.effect = nil
            } else {
                self.effectView.alpha = 0.0
            }
        })
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.dismiss()
        }
    }
}

