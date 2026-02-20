import SpriteKit

class InputManager {
    var currentVelocity: CGVector = .zero
    private var trackingTouch: UITouch?
    private var joystickOrigin: CGPoint = .zero
    private let deadZone: CGFloat = 10
    private let maxRadius: CGFloat = 60

    var isActive: Bool {
        return trackingTouch != nil
    }

    var joystickPosition: CGPoint? {
        guard trackingTouch != nil else { return nil }
        return joystickOrigin
    }

    var knobOffset: CGVector {
        return CGVector(
            dx: currentVelocity.dx * maxRadius,
            dy: currentVelocity.dy * maxRadius
        )
    }

    func touchBegan(_ touch: UITouch, in view: SKView) {
        guard trackingTouch == nil else { return }
        let location = touch.location(in: view)
        trackingTouch = touch
        joystickOrigin = location
    }

    func touchMoved(_ touch: UITouch, in view: SKView) {
        guard touch === trackingTouch else { return }
        let location = touch.location(in: view)
        let dx = location.x - joystickOrigin.x
        let dy = -(location.y - joystickOrigin.y) // Flip Y for SpriteKit
        let distance = sqrt(dx * dx + dy * dy)

        if distance < deadZone {
            currentVelocity = .zero
        } else {
            let clamped = min(distance, maxRadius)
            let magnitude = clamped / maxRadius
            currentVelocity = CGVector(
                dx: (dx / distance) * magnitude,
                dy: (dy / distance) * magnitude
            )
        }
    }

    func touchEnded(_ touch: UITouch) {
        if touch === trackingTouch {
            trackingTouch = nil
            currentVelocity = .zero
        }
    }

    func reset() {
        trackingTouch = nil
        currentVelocity = .zero
    }
}
