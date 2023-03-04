import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import MediaPlayer
import TelegramPresentationData

enum CallControllerButtonsSpeakerMode: Equatable {
    enum BluetoothType: Equatable {
        case generic
        case airpods
        case airpodsPro
        case airpodsMax
    }
    
    case none
    case builtin
    case speaker
    case headphones
    case bluetooth(BluetoothType)
}

enum CallControllerButtonsMode: Equatable {
    struct VideoState: Equatable {
        var isAvailable: Bool
        var isCameraActive: Bool
        var isScreencastActive: Bool
        var canChangeStatus: Bool
        var hasVideo: Bool
        var isInitializingCamera: Bool
    }
    
    case active(speakerMode: CallControllerButtonsSpeakerMode, hasAudioRouteMenu: Bool, videoState: VideoState)
    case incoming(speakerMode: CallControllerButtonsSpeakerMode, hasAudioRouteMenu: Bool, videoState: VideoState)
    case outgoingRinging(speakerMode: CallControllerButtonsSpeakerMode, hasAudioRouteMenu: Bool, videoState: VideoState)
}

private enum ButtonDescription: Equatable {
    enum Key: Hashable {
        case accept
        case acceptOrEnd
        case decline
        case enableCamera
        case switchCamera
        case soundOutput
        case mute
    }
    
    enum SoundOutput {
        case builtin
        case speaker
        case bluetooth
        case airpods
        case airpodsPro
        case airpodsMax
        case headphones
    }
    
    enum EndType {
        case decline
        case end
    }
    
    case accept
    case end(EndType)
    case enableCamera(isActive: Bool, isEnabled: Bool, isLoading: Bool, isScreencast: Bool, isIncoming: Bool)
    case switchCamera(Bool, isIncoming: Bool)
    case soundOutput(SoundOutput, isIncoming: Bool)
    case mute(Bool, isIncoming: Bool)
    
    var key: Key {
        switch self {
        case .accept:
            return .acceptOrEnd
        case let .end(type):
            if type == .decline {
                return .decline
            } else {
                return .acceptOrEnd
            }
        case .enableCamera:
            return .enableCamera
        case .switchCamera:
            return .switchCamera
        case .soundOutput:
            return .soundOutput
        case .mute:
            return .mute
        }
    }
}

private struct CameraState {
    let isCameraActive: Bool
    let isScreencastActive: Bool
    let isCameraEnabled: Bool
    let isCameraInitializing: Bool
}

final class CallControllerButtonsNode: ASDisplayNode {
    private var buttonNodes: [ButtonDescription.Key: CallControllerButtonItemNode] = [:]
    
    private var mode: CallControllerButtonsMode?
    
    private var validLayout: (CGFloat, CGFloat)?
    
    var isMuted = false
    
    var acceptOrEnd: (() -> Void)?
    var decline: (() -> Void)?
    var mute: (() -> Void)?
    var speaker: (() -> Void)?
    var toggleVideo: (() -> Void)?
    var rotateCamera: (() -> Void)?
    
    init(strings: PresentationStrings) {
        super.init()
    }
    
    func updateLayout(strings: PresentationStrings, mode: CallControllerButtonsMode, constrainedWidth: CGFloat, bottomInset: CGFloat, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayout = (constrainedWidth, bottomInset)
        
        self.mode = mode
        
        if let mode = self.mode {
            return self.updateButtonsLayout(strings: strings, mode: mode, width: constrainedWidth, bottomInset: bottomInset, animated: transition.isAnimated)
        } else {
            return 0.0
        }
    }
    
    private var appliedMode: CallControllerButtonsMode?
    
    func videoButtonFrame() -> CGRect? {
        return self.buttonNodes[.enableCamera]?.frame
    }
    
    private func updateButtonsLayout(strings: PresentationStrings, mode: CallControllerButtonsMode, width: CGFloat, bottomInset: CGFloat, animated: Bool) -> CGFloat {
        let transition: ContainedViewLayoutTransition
        if animated {
            transition = .animated(duration: 0.3, curve: .spring)
        } else {
            transition = .immediate
        }
        
        let previousMode = self.appliedMode
        self.appliedMode = mode
        
        var animatePositionsWithDelay = false
        if let previousMode = previousMode {
            switch previousMode {
            case .incoming, .outgoingRinging:
                if case .active = mode {
                    animatePositionsWithDelay = true
                }
            default:
                break
            }
        }
        
        struct PlacedButton {
            let button: ButtonDescription
            let frame: CGRect
        }
        
        let height: CGFloat
        
        let speakerMode: CallControllerButtonsSpeakerMode
        var videoState: CallControllerButtonsMode.VideoState
        let hasAudioRouteMenu: Bool
        switch mode {
        case .incoming(let speakerModeValue, let hasAudioRouteMenuValue, let videoStateValue), .outgoingRinging(let speakerModeValue, let hasAudioRouteMenuValue, let videoStateValue), .active(let speakerModeValue, let hasAudioRouteMenuValue, let videoStateValue):
            speakerMode = speakerModeValue
            videoState = videoStateValue
            hasAudioRouteMenu = hasAudioRouteMenuValue
        }
        
        let soundOutput = speakerMode.toSoundOutput()
        
        enum MappedState {
            case incomingRinging
            case outgoingRinging
            case active
        }
        
        let mappedState: MappedState
        switch mode {
        case .incoming:
            mappedState = .incomingRinging
        case .outgoingRinging:
            mappedState = .outgoingRinging
        case let .active(_, _, videoStateValue):
            mappedState = .active
            videoState = videoStateValue
        }
        
        let cameraState = CameraState(from: videoState)
        let isCameraActive = cameraState.isCameraActive
        let isScreencastActive = cameraState.isScreencastActive
        let isCameraEnabled = cameraState.isCameraEnabled
        let isCameraInitializing = cameraState.isCameraInitializing
        
        var buttons: [PlacedButton] = []
        switch mappedState {
        case .incomingRinging:
            var topButtons: [ButtonDescription] = []
            var bottomButtons: [ButtonDescription] = []
            
            if videoState.isAvailable {
                topButtons.append(.enableCamera(isActive: isCameraActive || isScreencastActive, isEnabled: false, isLoading: isCameraInitializing, isScreencast: isScreencastActive, isIncoming: true))
                if !videoState.hasVideo {
                    topButtons.append(.mute(self.isMuted, isIncoming: true))
                    topButtons.append(.soundOutput(soundOutput, isIncoming: true))
                } else {
                    if hasAudioRouteMenu {
                        topButtons.append(.soundOutput(soundOutput, isIncoming: true))
                    } else {
                        topButtons.append(.mute(self.isMuted, isIncoming: true))
                    }
                    if !isScreencastActive {
                        topButtons.append(.switchCamera(isCameraActive && !isCameraInitializing, isIncoming: true))
                    }
                }
            } else {
                topButtons.append(.mute(self.isMuted, isIncoming: true))
                topButtons.append(.soundOutput(soundOutput, isIncoming: true))
            }
            
            let maxLargeButtonSpacing: CGFloat = 115.0
            let largeButtonSize: CGFloat = 72.0
            let minSmallButtonSideInset: CGFloat = width > 320.0 ? 34.0 : 16.0
            let minLargeButtonSideInset: CGFloat = minSmallButtonSideInset - 6.0
            let maxSmallButtonSpacing: CGFloat = 34.0
            let topBottomSpacing: CGFloat = 84.0
            
            let topButtonsContentWidth = CGFloat(topButtons.count) * largeButtonSize
            let topButtonsAvailableSpacingWidth = width - topButtonsContentWidth - minSmallButtonSideInset * 2.0
            let topButtonsSpacing = min(maxSmallButtonSpacing, topButtonsAvailableSpacingWidth / CGFloat(topButtons.count - 1))
            let topButtonsWidth = CGFloat(topButtons.count) * largeButtonSize + CGFloat(topButtons.count - 1) * topButtonsSpacing
            var topButtonsLeftOffset = floor((width - topButtonsWidth) / 2.0)
            for button in topButtons {
                buttons.append(PlacedButton(button: button, frame: CGRect(origin: CGPoint(x: topButtonsLeftOffset, y: 0.0), size: CGSize(width: largeButtonSize, height: largeButtonSize))))
                topButtonsLeftOffset += largeButtonSize + topButtonsSpacing
            }
            
            bottomButtons.append(.end(.decline))
            bottomButtons.append(.accept)
            
            let bottomButtonsContentWidth = CGFloat(bottomButtons.count) * largeButtonSize
            let bottomButtonsAvailableSpacingWidth = width - bottomButtonsContentWidth - minLargeButtonSideInset * 2.0
            let bottomButtonsSpacing = min(maxLargeButtonSpacing, bottomButtonsAvailableSpacingWidth / CGFloat(bottomButtons.count - 1))
            let bottomButtonsWidth = CGFloat(bottomButtons.count) * largeButtonSize + CGFloat(bottomButtons.count - 1) * bottomButtonsSpacing
            var bottomButtonsLeftOffset = floor((width - bottomButtonsWidth) / 2.0)
            for button in bottomButtons {
                buttons.append(PlacedButton(button: button, frame: CGRect(origin: CGPoint(x: bottomButtonsLeftOffset, y: largeButtonSize + topBottomSpacing), size: CGSize(width: largeButtonSize, height: largeButtonSize))))
                bottomButtonsLeftOffset += largeButtonSize + bottomButtonsSpacing
            }
            
            height = largeButtonSize + topBottomSpacing + largeButtonSize + max(bottomInset + 32.0, 46.0)
        case .outgoingRinging:
            var outgoingButtons: [ButtonDescription] = []
            
            if videoState.isAvailable {
                if !videoState.hasVideo {
                    outgoingButtons.append(.soundOutput(soundOutput, isIncoming: false))
                    outgoingButtons.append(.enableCamera(isActive: isCameraActive || isScreencastActive, isEnabled: false, isLoading: isCameraInitializing, isScreencast: isScreencastActive, isIncoming: false))
                    outgoingButtons.append(.mute(self.isMuted, isIncoming: false))
                } else {
                    if !isScreencastActive {
                        outgoingButtons.append(.switchCamera(isCameraActive && !isCameraInitializing, isIncoming: false))
                    }
                    outgoingButtons.append(.enableCamera(isActive: isCameraActive || isScreencastActive, isEnabled: false, isLoading: isCameraInitializing, isScreencast: isScreencastActive, isIncoming: false))
                    if hasAudioRouteMenu {
                        outgoingButtons.append(.soundOutput(soundOutput, isIncoming: false))
                    } else {
                        outgoingButtons.append(.mute(self.isMuted, isIncoming: false))
                    }
                }
            } else {
                outgoingButtons.append(.soundOutput(soundOutput, isIncoming: false))
                outgoingButtons.append(.mute(self.isMuted, isIncoming: false))
            }
                
            outgoingButtons.append(.end(.end))
            
            let minSmallButtonSideInset: CGFloat = width > 320.0 ? 30.5 : 16.0
            let maxSmallButtonSpacing: CGFloat = 36
            let smallButtonSize: CGFloat = 56
            
            let buttonsContentWidth = CGFloat(outgoingButtons.count) * smallButtonSize
            let buttonsAvailableSpacingWidth = width - buttonsContentWidth - minSmallButtonSideInset * 2.0
            let buttonsSpacing = min(maxSmallButtonSpacing, buttonsAvailableSpacingWidth / CGFloat(outgoingButtons.count - 1))
            let buttonsWidth = CGFloat(outgoingButtons.count) * smallButtonSize + CGFloat(outgoingButtons.count - 1) * buttonsSpacing
            var buttonsLeftOffset = floor((width - buttonsWidth) / 2.0)
            for button in outgoingButtons {
                buttons.append(PlacedButton(button: button, frame: CGRect(origin: CGPoint(x: buttonsLeftOffset, y: 0.0), size: CGSize(width: smallButtonSize, height: smallButtonSize))))
                buttonsLeftOffset += smallButtonSize + buttonsSpacing
            }
            
            height = smallButtonSize + max(bottomInset + 19.0, 86)
        case .active:
            var activeButtons: [ButtonDescription] = []
            
            if videoState.hasVideo {
                if !isScreencastActive {
                    activeButtons.append(.switchCamera(isCameraActive && !isCameraInitializing, isIncoming: false))
                }
                activeButtons.append(.enableCamera(isActive: isCameraActive || isScreencastActive, isEnabled: isCameraEnabled, isLoading: isCameraInitializing, isScreencast: isScreencastActive, isIncoming: false))
                if hasAudioRouteMenu {
                    activeButtons.append(.soundOutput(soundOutput, isIncoming: false))
                } else {
                    activeButtons.append(.mute(isMuted, isIncoming: false))
                }
            } else {
                activeButtons.append(.soundOutput(soundOutput, isIncoming: false))
                activeButtons.append(.enableCamera(isActive: isCameraActive || isScreencastActive, isEnabled: isCameraEnabled, isLoading: isCameraInitializing, isScreencast: isScreencastActive, isIncoming: false))
                activeButtons.append(.mute(self.isMuted, isIncoming: false))
            }
            
            activeButtons.append(.end(.end))
            
            let minSmallButtonSideInset: CGFloat = width > 320.0 ? 30.5 : 16.0
            let maxSmallButtonSpacing: CGFloat = 36
            let smallButtonSize: CGFloat = 56
            
            let buttonsContentWidth = CGFloat(activeButtons.count) * smallButtonSize
            let buttonsAvailableSpacingWidth = width - buttonsContentWidth - minSmallButtonSideInset * 2.0
            let buttonsSpacing = min(maxSmallButtonSpacing, buttonsAvailableSpacingWidth / CGFloat(activeButtons.count - 1))
            let buttonsWidth = CGFloat(activeButtons.count) * smallButtonSize + CGFloat(activeButtons.count - 1) * buttonsSpacing
            var buttonsLeftOffset = floor((width - buttonsWidth) / 2.0)
            for button in activeButtons {
                buttons.append(PlacedButton(button: button, frame: CGRect(origin: CGPoint(x: buttonsLeftOffset, y: 0.0), size: CGSize(width: smallButtonSize, height: smallButtonSize))))
                buttonsLeftOffset += smallButtonSize + buttonsSpacing
            }
            
            height = smallButtonSize + max(bottomInset + 19.0, 86)
        }
        
        let delayIncrement = 0.015
        var validKeys: [ButtonDescription.Key] = []
        for button in buttons {
            validKeys.append(button.button.key)
            var buttonTransition = transition
            var animateButtonIn = false
            let buttonNode: CallControllerButtonItemNode
            if let current = self.buttonNodes[button.button.key] {
                buttonNode = current
            } else {
                buttonNode = CallControllerButtonItemNode()
                self.buttonNodes[button.button.key] = buttonNode
                self.addSubnode(buttonNode)
                buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: .touchUpInside)
                buttonTransition = .immediate
                animateButtonIn = transition.isAnimated
            }
            let buttonContent: CallControllerButtonItemNode.Content
            let buttonText: String
            var buttonAccessibilityLabel = ""
            var buttonAccessibilityValue = ""
            var buttonAccessibilityTraits: UIAccessibilityTraits = [.button]
            switch button.button {
            case .accept:
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .color(.green),
                    image: .accept
                )
                buttonText = strings.Call_Accept
                buttonAccessibilityLabel = buttonText
            case let .end(type):
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .color(.red),
                    image: .end(isDecline: type == .decline)
                )
                switch type {
                case .decline:
                    buttonText = strings.Call_Decline
                case .end:
                    buttonText = strings.Call_End
                }
                if !buttonText.isEmpty {
                    buttonAccessibilityLabel = buttonText
                } else {
                    buttonAccessibilityLabel = strings.Call_End
                }
            case let .enableCamera(isActivated, isEnabled, isInitializing, isScreencastActive, isIncoming):
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .blurred(isFilled: isActivated),
                    image: isScreencastActive ? .screencast : .camera(isModern: !isIncoming),
                    isEnabled: isEnabled,
                    hasProgress: isInitializing
                )
                buttonText = strings.Call_Camera
                buttonAccessibilityLabel = buttonText
                if !isEnabled {
                    buttonAccessibilityTraits.insert(.notEnabled)
                }
                if isActivated {
                    buttonAccessibilityTraits.insert(.selected)
                }
            case let .switchCamera(isEnabled, isIncoming):
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .blurred(isFilled: false),
                    image: .flipCamera(isModern: !isIncoming),
                    isEnabled: isEnabled
                )
                buttonText = strings.Call_Flip
                buttonAccessibilityLabel = buttonText
                if !isEnabled {
                    buttonAccessibilityTraits.insert(.notEnabled)
                }
            case let .soundOutput(value, isIncoming):
                let image: CallControllerButtonItemNode.Content.Image
                var isFilled = false
                var title: String = strings.Call_Speaker
                switch value {
                case .builtin:
                    image = .speaker(isModern: !isIncoming)
                case .speaker:
                    image = .speaker(isModern: !isIncoming)
                    isFilled = true
                case .bluetooth:
                    image = .bluetooth(isModern: !isIncoming)
                    title = strings.Call_Audio
                    buttonAccessibilityValue = "Bluetooth"
                case .airpods:
                    image = .airpods(isModern: !isIncoming)
                    title = strings.Call_Audio
                    buttonAccessibilityValue = "Airpods"
                case .airpodsPro:
                    image = .airpodsPro(isModern: !isIncoming)
                    title = strings.Call_Audio
                    buttonAccessibilityValue = "Airpods Pro"
                case .airpodsMax:
                    image = .airpodsMax(isModern: !isIncoming)
                    title = strings.Call_Audio
                    buttonAccessibilityValue = "Airpods Max"
                case .headphones:
                    image = .headphones
                    title = strings.Call_Audio
                    buttonAccessibilityValue = strings.Call_AudioRouteHeadphones
                }
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .blurred(isFilled: isFilled),
                    image: image
                )
                buttonText = title
                buttonAccessibilityLabel = buttonText
                if isFilled {
                    buttonAccessibilityTraits.insert(.selected)
                }
            case let .mute(isMuted, isIncoming):
                buttonContent = CallControllerButtonItemNode.Content(
                    appearance: .blurred(isFilled: isMuted),
                    image: .mute(isModern: !isIncoming)
                )
                buttonText = strings.Call_Mute
                buttonAccessibilityLabel = buttonText
                if isMuted {
                    buttonAccessibilityTraits.insert(.selected)
                }
            }
            var buttonDelay = 0.0
            if animatePositionsWithDelay {
                switch button.button.key {
                case .enableCamera:
                    buttonDelay = 0.0
                case .mute:
                    buttonDelay = delayIncrement * 1.0
                case .switchCamera:
                    buttonDelay = delayIncrement * 2.0
                case .acceptOrEnd:
                    buttonDelay = delayIncrement * 3.0
                default:
                    break
                }
            }
            buttonTransition.updateFrame(node: buttonNode, frame: button.frame, delay: buttonDelay)
            buttonNode.update(size: button.frame.size, content: buttonContent, text: buttonText, transition: buttonTransition)
            buttonNode.accessibilityLabel = buttonAccessibilityLabel
            buttonNode.accessibilityValue = buttonAccessibilityValue
            buttonNode.accessibilityTraits = buttonAccessibilityTraits
            
            if animateButtonIn {
                buttonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
        
        var removedKeys: [ButtonDescription.Key] = []
        for (key, button) in self.buttonNodes {
            if !validKeys.contains(key) {
                removedKeys.append(key)
                if animated {
                    if case .decline = key {
                        transition.updateTransformScale(node: button, scale: 0.1)
                        transition.updateAlpha(node: button, alpha: 0.0, completion: { [weak button] _ in
                            button?.removeFromSupernode()
                        })
                    } else {
                        transition.updateAlpha(node: button, alpha: 0.0, completion: { [weak button] _ in
                            button?.removeFromSupernode()
                        })
                    }
                } else {
                    button.removeFromSupernode()
                }
            }
        }
        for key in removedKeys {
            self.buttonNodes.removeValue(forKey: key)
        }
        
        return height
    }
    
    @objc func buttonPressed(_ button: CallControllerButtonItemNode) {
        for (key, listButton) in self.buttonNodes {
            if button === listButton {
                switch key {
                case .accept:
                    self.acceptOrEnd?()
                case .acceptOrEnd:
                    self.acceptOrEnd?()
                case .decline:
                    self.decline?()
                case .enableCamera:
                    self.toggleVideo?()
                case .switchCamera:
                    self.rotateCamera?()
                case .soundOutput:
                    self.speaker?()
                case .mute:
                    self.mute?()
                }
                break
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for (_, button) in self.buttonNodes {
            if let result = button.view.hitTest(self.view.convert(point, to: button.view), with: event) {
                return result
            }
        }
        
        return super.hitTest(point, with: event)
    }
}

private extension CallControllerButtonsSpeakerMode {
    func toSoundOutput() -> ButtonDescription.SoundOutput {
        switch self {
            case .none, .builtin:
                return .builtin
            case .speaker:
                return .speaker
            case .headphones:
                return .bluetooth
            case let .bluetooth(type):
                switch type {
                    case .generic:
                        return .bluetooth
                    case .airpods:
                        return .airpods
                    case .airpodsPro:
                        return .airpodsPro
                    case .airpodsMax:
                        return .airpodsMax
            }
        }
    }
}

private extension CameraState {
    init(from videoState: CallControllerButtonsMode.VideoState) {
        if videoState.hasVideo {
            isCameraActive = videoState.isCameraActive
            isScreencastActive = videoState.isScreencastActive
            isCameraEnabled = videoState.canChangeStatus
            isCameraInitializing = videoState.isInitializingCamera
        } else {
            isCameraActive = false
            isScreencastActive = false
            isCameraEnabled = videoState.canChangeStatus
            isCameraInitializing = videoState.isInitializingCamera
        }
    }
}
