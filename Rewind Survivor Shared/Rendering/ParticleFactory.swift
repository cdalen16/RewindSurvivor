import SpriteKit

class ParticleFactory {

    static func deathExplosion(at position: CGPoint, color: SKColor, scene: SKScene, count: Int = 15) {
        for _ in 0..<count {
            let particle = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = 150
            particle.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...180)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            scene.addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: dx * 0.5, dy: dy * 0.5), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.1, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    static func playerDeathExplosion(at position: CGPoint, scene: SKScene) {
        // Big dramatic explosion
        deathExplosion(at: position, color: ColorPalette.playerPrimary, scene: scene, count: 30)

        // Flash
        let flash = SKSpriteNode(color: .white, size: CGSize(width: 120, height: 120))
        flash.position = position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.9
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 3.0, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = ColorPalette.playerPrimary
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = position
        ring.zPosition = 199
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 15.0, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    static func powerUpPickup(at position: CGPoint, color: SKColor, scene: SKScene) {
        for _ in 0..<10 {
            let p = SKSpriteNode(color: color, size: CGSize(width: 3, height: 3))
            p.position = position
            p.zPosition = 150
            p.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...100)

            scene.addChild(p)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(angle) * speed * 0.4, dy: sin(angle) * speed * 0.4), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.3, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Ring
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.position = position
        ring.zPosition = 149
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 5.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    static func waveTransitionScanline(screenSize: CGSize, scene: SKScene, camera: SKCameraNode) {
        let line = SKSpriteNode(color: ColorPalette.rewindMagenta, size: CGSize(width: screenSize.width, height: 4))
        line.position = CGPoint(x: camera.position.x, y: camera.position.y + screenSize.height / 2)
        line.zPosition = 700
        line.alpha = 0.5
        line.blendMode = .add
        scene.addChild(line)

        line.run(SKAction.sequence([
            SKAction.moveTo(y: camera.position.y - screenSize.height / 2, duration: 0.6),
            SKAction.removeFromParent()
        ]))
    }
}
