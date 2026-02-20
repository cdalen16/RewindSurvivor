import SpriteKit

class EnemyNode: SKSpriteNode {
    let enemyType: EnemyType
    var hp: CGFloat
    var maxHP: CGFloat
    var moveSpeed: CGFloat
    var contactDamage: CGFloat
    var behavior: EnemyBehavior
    var pointValue: Int
    var behaviorTimer: TimeInterval = 0
    private var animTimer: TimeInterval = 0
    private var currentFrame: Int = 0
    private var chargeDirection: CGVector?
    private var chargeState: ChargeState = .approaching
    private var spawnTimer: TimeInterval = 0
    var isFrozen: Bool = false
    private(set) var baseSpeed: CGFloat = 0
    private var isSlowed: Bool = false

    // Stuck detection
    private var lastPosition: CGPoint = .zero
    private var stuckTimer: TimeInterval = 0
    private var stuckNudgeAngle: CGFloat = 0

    private enum ChargeState {
        case approaching
        case telegraphing
        case charging
        case cooldown
    }

    init(type: EnemyType, wave: Int, ghostCount: Int) {
        self.enemyType = type
        let stats = EnemyType.scaledStats(type: type, wave: wave, ghostCount: ghostCount)
        self.hp = stats.hp
        self.maxHP = stats.hp
        self.moveSpeed = stats.speed
        self.contactDamage = stats.damage
        self.behavior = type.behavior
        self.pointValue = type.basePoints + GameConfig.pointsPerKillPerWave * (wave - 1)

        let texture = SpriteFactory.shared.enemyTexture(type: type, frame: 0)
        let spriteSize = CGSize(width: type.spriteSize, height: type.spriteSize)
        super.init(texture: texture, color: .clear, size: spriteSize)

        self.name = "enemy"
        self.zPosition = 90

        // Physics
        let radius = CGFloat(type.spriteSize) * 0.4
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 0
        body.friction = 0
        self.physicsBody = body
        self.baseSpeed = self.moveSpeed
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(deltaTime: TimeInterval, targets: [SKNode]) {
        guard !isFrozen else {
            physicsBody?.velocity = .zero
            return
        }
        guard let nearest = findNearestTarget(targets) else {
            physicsBody?.velocity = .zero
            return
        }

        // Animation
        animTimer += deltaTime
        if animTimer >= 0.3 {
            animTimer = 0
            currentFrame = (currentFrame + 1) % 2
            self.texture = SpriteFactory.shared.enemyTexture(type: enemyType, frame: currentFrame)
        }

        // Stuck detection
        let distMoved = CGVector(dx: position.x - lastPosition.x, dy: position.y - lastPosition.y).length()
        if distMoved < 1.0 {
            stuckTimer += deltaTime
        } else {
            stuckTimer = 0
        }
        lastPosition = position

        if stuckTimer > 0.5 {
            stuckTimer = 0
            stuckNudgeAngle += .pi / 2
            let nudge = CGVector(dx: cos(stuckNudgeAngle), dy: sin(stuckNudgeAngle))
            physicsBody?.velocity = CGVector(dx: nudge.dx * moveSpeed * 1.5, dy: nudge.dy * moveSpeed * 1.5)
            return
        }

        let toTarget = CGVector(
            dx: nearest.position.x - position.x,
            dy: nearest.position.y - position.y
        )
        let dist = toTarget.length()

        switch behavior {
        case .chase:
            let dir = avoidObstacles(desiredDirection: toTarget.normalized())
            physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)

        case .charger:
            behaviorTimer += deltaTime
            switch chargeState {
            case .approaching:
                if dist < 200 {
                    chargeState = .telegraphing
                    behaviorTimer = 0
                    chargeDirection = toTarget.normalized()
                    physicsBody?.velocity = .zero
                    let flash = SKAction.sequence([
                        SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.1),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
                    ])
                    run(SKAction.repeat(flash, count: 3), withKey: "telegraph")
                } else {
                    let dir = avoidObstacles(desiredDirection: toTarget.normalized())
                    physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed * 0.6, dy: dir.dy * moveSpeed * 0.6)
                }

            case .telegraphing:
                physicsBody?.velocity = .zero
                if behaviorTimer >= 0.6 {
                    chargeState = .charging
                    behaviorTimer = 0
                    removeAction(forKey: "telegraph")
                }

            case .charging:
                if let dir = chargeDirection {
                    // No obstacle avoidance during charge — physics handles wall collision
                    physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed * 4.0, dy: dir.dy * moveSpeed * 4.0)
                }
                if behaviorTimer >= 0.4 {
                    chargeState = .cooldown
                    behaviorTimer = 0
                    physicsBody?.velocity = .zero
                }

            case .cooldown:
                physicsBody?.velocity = .zero
                if behaviorTimer >= 1.0 {
                    chargeState = .approaching
                    behaviorTimer = 0
                }
            }

        case .strafe:
            let preferredDist: CGFloat = 180
            let radialDir = toTarget.normalized()
            let tangentDir = CGVector(dx: -radialDir.dy, dy: radialDir.dx)
            let radialForce = (dist - preferredDist) / preferredDist
            let moveDir = CGVector(
                dx: radialDir.dx * radialForce + tangentDir.dx,
                dy: radialDir.dy * radialForce + tangentDir.dy
            ).normalized()

            let dir = avoidObstacles(desiredDirection: moveDir)
            physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)

            // Shoot periodically
            spawnTimer += deltaTime
            if spawnTimer >= 2.0 {
                spawnTimer = 0
                shootAtTarget(nearest)
            }

        case .bomber:
            let dir = avoidObstacles(desiredDirection: toTarget.normalized())
            physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)

            // Pulse glow as we get closer
            let closeness = max(0, 1.0 - dist / 200)
            if !isSlowed { colorBlendFactor = closeness * 0.5 }

            if dist < 35 {
                explode()
            }

        case .spawner:
            let preferredDist: CGFloat = 300
            if dist < preferredDist {
                let flee = CGVector(dx: -toTarget.normalized().dx, dy: -toTarget.normalized().dy)
                let dir = avoidObstacles(desiredDirection: flee)
                physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)
            } else if dist > preferredDist + 100 {
                let dir = avoidObstacles(desiredDirection: toTarget.normalized())
                physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed * 0.5, dy: dir.dy * moveSpeed * 0.5)
            } else {
                physicsBody?.velocity = .zero
            }

            spawnTimer += deltaTime
            if spawnTimer >= 4.0 {
                spawnTimer = 0
                spawnMinion()
            }
        }

        // Safety clamp (failsafe only, physics boundary should handle this)
        let hardLimit = GameConfig.arenaSize.width / 2 + 50
        if abs(position.x) > hardLimit || abs(position.y) > hardLimit {
            position.x = max(-hardLimit, min(hardLimit, position.x))
            position.y = max(-hardLimit, min(hardLimit, position.y))
            physicsBody?.velocity = .zero
        }
    }

    // MARK: - Obstacle Avoidance

    private func avoidObstacles(desiredDirection: CGVector) -> CGVector {
        guard let scene = self.scene else { return desiredDirection }

        let lookAhead = CGFloat(enemyType.spriteSize) * 1.5
        let angles: [CGFloat] = [0, .pi / 6, -.pi / 6]
        var centerBlocked = false
        var bestDir = desiredDirection

        for angle in angles {
            let rayDir = desiredDirection.rotated(by: angle)
            let rayEnd = CGPoint(
                x: position.x + rayDir.dx * lookAhead,
                y: position.y + rayDir.dy * lookAhead
            )

            if let hit = scene.physicsWorld.body(alongRayStart: position, end: rayEnd),
               hit.categoryBitMask == PhysicsCategory.wall,
               hit.isDynamic == false {
                if angle == 0 {
                    centerBlocked = true
                }
            } else if angle != 0 && centerBlocked {
                bestDir = desiredDirection.rotated(by: angle * 2.5)
                break
            }
        }

        return bestDir.normalized()
    }

    // MARK: - Slow/Freeze Aura Support

    func applySlow(_ percent: CGFloat) {
        if !isSlowed {
            isSlowed = true
            moveSpeed = baseSpeed * (1.0 - percent)
            colorBlendFactor = 0.3
            color = SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0)
        }
    }

    func removeSlow() {
        if isSlowed {
            isSlowed = false
            moveSpeed = baseSpeed
            colorBlendFactor = 0
        }
    }

    private func findNearestTarget(_ targets: [SKNode]) -> SKNode? {
        var closest: SKNode?
        var closestDistSq: CGFloat = .greatestFiniteMagnitude
        for target in targets {
            guard target.parent != nil else { continue }
            let dx = target.position.x - position.x
            let dy = target.position.y - position.y
            let distSq = dx * dx + dy * dy
            if distSq < closestDistSq {
                closestDistSq = distSq
                closest = target
            }
        }
        return closest
    }

    @discardableResult
    func takeDamage(_ amount: CGFloat) -> Bool {
        hp -= amount

        // Flash white
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.7, duration: 0.03),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.03)
        ])
        run(flash, withKey: "hit")

        return hp <= 0
    }

    func die(scene: SKScene) {
        // Spawn death particles
        let particleCount = 12
        for _ in 0..<particleCount {
            let particle = SKSpriteNode(color: enemyType.color, size: CGSize(width: 3, height: 3))
            particle.position = position
            particle.zPosition = 95
            particle.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...150)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            scene.addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: dx * 0.5, dy: dy * 0.5), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.1, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        removeFromParent()
    }

    private func shootAtTarget(_ target: SKNode) {
        guard let scene = self.scene else { return }
        let dir = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        ).normalized()

        let projectile = ProjectileNode(
            damage: contactDamage * 0.5,
            velocity: CGVector(dx: dir.dx * 200, dy: dir.dy * 200),
            piercing: 0,
            type: .enemy
        )
        projectile.position = position
        scene.addChild(projectile)
    }

    private func explode() {
        guard let scene = self.scene else { return }

        // Damage area
        let explosionRadius: CGFloat = 80
        scene.enumerateChildNodes(withName: "player") { node, _ in
            let dx = node.position.x - self.position.x
            let dy = node.position.y - self.position.y
            if sqrt(dx * dx + dy * dy) < explosionRadius {
                (node as? PlayerNode)?.takeDamage(self.contactDamage)
            }
        }

        // Visual explosion
        let particleCount = 24
        for _ in 0..<particleCount {
            let particle = SKSpriteNode(color: ColorPalette.bulletEnemy, size: CGSize(width: 5, height: 5))
            particle.position = position
            particle.zPosition = 95
            particle.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...200)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            scene.addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: dx * 0.5, dy: dy * 0.5), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.2, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Flash
        let flash = SKSpriteNode(color: .orange, size: CGSize(width: explosionRadius * 2, height: explosionRadius * 2))
        flash.position = position
        flash.zPosition = 94
        flash.blendMode = .add
        flash.alpha = 0.6
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 1.5, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        die(scene: scene)
    }

    private func spawnMinion() {
        guard let scene = self.scene as? GameScene else { return }
        let offset = CGVector(
            dx: CGFloat.random(in: -40...40),
            dy: CGFloat.random(in: -40...40)
        )
        let minionPos = CGPoint(x: position.x + offset.dx, y: position.y + offset.dy)
        scene.spawnMinion(at: minionPos)
    }
}

// MARK: - CGSize Extensions
extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

// MARK: - CGVector Extensions
extension CGVector {
    func length() -> CGFloat {
        return sqrt(dx * dx + dy * dy)
    }

    func normalized() -> CGVector {
        let len = length()
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    func rotated(by angle: CGFloat) -> CGVector {
        let cosA = cos(angle)
        let sinA = sin(angle)
        return CGVector(
            dx: dx * cosA - dy * sinA,
            dy: dx * sinA + dy * cosA
        )
    }
}
