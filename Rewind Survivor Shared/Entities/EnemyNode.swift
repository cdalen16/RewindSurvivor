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

    // Juggernaut state
    private var groundPoundState: GroundPoundState = .walking
    private var groundPoundTimer: TimeInterval = 0

    // Wraith state
    private var wraithPhaseTimer: TimeInterval = 0
    private var isPhased: Bool = false

    // Splitter state
    var canSplit: Bool = true

    // Shield Bearer state
    private(set) var shieldFacingDirection: CGVector = CGVector(dx: 0, dy: -1)
    private var shieldAngle: CGFloat = -.pi / 2
    private let shieldTurnSpeed: CGFloat = 1.8  // radians/sec — player can outrun this
    private var shieldVisualNode: SKNode?

    private enum GroundPoundState {
        case walking
        case telegraphing
        case slamming
        case recovering
    }

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

        // Create dynamic shield visual for Shield Bearer
        if type.behavior == .shieldBearer {
            setupShieldVisual()
        }
    }

    private func setupShieldVisual() {
        let container = SKNode()
        container.zPosition = 2

        let shieldColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        let shieldGlow = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.4)

        // Shield barrier (arc shape) — positioned at offset from center
        let barrierWidth: CGFloat = 6
        let barrierHeight: CGFloat = 28

        // Main shield bar
        let shield = SKSpriteNode(color: shieldColor, size: CGSize(width: barrierWidth, height: barrierHeight))
        shield.position = CGPoint(x: 22, y: 0)
        shield.alpha = 0.85
        shield.blendMode = .add
        shield.name = "shieldBar"
        container.addChild(shield)

        // Glow behind shield
        let glow = SKSpriteNode(color: shieldGlow, size: CGSize(width: barrierWidth + 8, height: barrierHeight + 8))
        glow.position = CGPoint(x: 22, y: 0)
        glow.alpha = 0.4
        glow.blendMode = .add
        container.addChild(glow)

        // Edge highlights (top and bottom caps)
        let capSize = CGSize(width: barrierWidth + 2, height: 3)
        let topCap = SKSpriteNode(color: .white, size: capSize)
        topCap.position = CGPoint(x: 22, y: barrierHeight / 2)
        topCap.alpha = 0.7
        topCap.blendMode = .add
        container.addChild(topCap)

        let botCap = SKSpriteNode(color: .white, size: capSize)
        botCap.position = CGPoint(x: 22, y: -barrierHeight / 2)
        botCap.alpha = 0.7
        botCap.blendMode = .add
        container.addChild(botCap)

        addChild(container)
        shieldVisualNode = container
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

        // Face movement direction (flip sprite horizontally) — skip for shield bearer (uses shield rotation)
        if behavior != .shieldBearer, let vel = physicsBody?.velocity, abs(vel.dx) > 10 {
            xScale = vel.dx < 0 ? -abs(xScale) : abs(xScale)
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

        case .juggernaut:
            groundPoundTimer += deltaTime
            switch groundPoundState {
            case .walking:
                let dir = avoidObstacles(desiredDirection: toTarget.normalized())
                physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)
                if dist < 120 {
                    groundPoundState = .telegraphing
                    groundPoundTimer = 0
                    physicsBody?.velocity = .zero
                    // Telegraph: flash red and grow slightly
                    let flash = SKAction.sequence([
                        SKAction.colorize(with: .red, colorBlendFactor: 0.6, duration: 0.15),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.15)
                    ])
                    run(SKAction.repeat(flash, count: 3), withKey: "groundPoundTelegraph")
                    run(SKAction.scale(to: 1.15, duration: 0.8), withKey: "groundPoundGrow")
                }

            case .telegraphing:
                physicsBody?.velocity = .zero
                if groundPoundTimer >= 0.9 {
                    groundPoundState = .slamming
                    groundPoundTimer = 0
                    removeAction(forKey: "groundPoundTelegraph")
                    removeAction(forKey: "groundPoundGrow")
                    // Lunge toward player before slamming
                    let lungeDir = toTarget.normalized()
                    let lungeDist = min(dist, 60.0)
                    let lungeMove = SKAction.move(by: CGVector(dx: lungeDir.dx * lungeDist, dy: lungeDir.dy * lungeDist), duration: 0.08)
                    run(SKAction.group([
                        lungeMove,
                        SKAction.scale(to: 1.0, duration: 0.08)
                    ])) { [weak self] in
                        self?.groundPound()
                    }
                }

            case .slamming:
                physicsBody?.velocity = .zero
                if groundPoundTimer >= 0.3 {
                    groundPoundState = .recovering
                    groundPoundTimer = 0
                }

            case .recovering:
                physicsBody?.velocity = .zero
                if groundPoundTimer >= 0.7 {
                    groundPoundState = .walking
                    groundPoundTimer = 0
                }
            }

        case .wraith:
            wraithPhaseTimer += deltaTime

            if isPhased {
                // Phased: invisible, fast, move toward player
                physicsBody?.velocity = .zero
                // Phase lasts 1.5s, then reappear near target
                if wraithPhaseTimer >= 1.5 {
                    isPhased = false
                    wraithPhaseTimer = 0
                    // Teleport near target
                    let offset = CGVector(
                        dx: CGFloat.random(in: -50...50),
                        dy: CGFloat.random(in: -50...50)
                    )
                    position = CGPoint(x: nearest.position.x + offset.dx, y: nearest.position.y + offset.dy)
                    // Fade in
                    alpha = 0
                    run(SKAction.fadeAlpha(to: 0.85, duration: 0.3), withKey: "wraithAppear")
                    physicsBody?.categoryBitMask = PhysicsCategory.enemy
                    physicsBody?.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.player
                }
            } else {
                // Visible: chase slowly
                let dir = avoidObstacles(desiredDirection: toTarget.normalized())
                physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)
                // Shimmer effect
                alpha = 0.75 + 0.1 * CGFloat(sin(wraithPhaseTimer * 6.0))

                // Phase out every 4 seconds
                if wraithPhaseTimer >= 4.0 {
                    isPhased = true
                    wraithPhaseTimer = 0
                    // Fade out
                    run(SKAction.fadeAlpha(to: 0.0, duration: 0.4), withKey: "wraithPhase")
                    // Become untargetable
                    physicsBody?.categoryBitMask = 0
                    physicsBody?.contactTestBitMask = 0
                    physicsBody?.velocity = .zero
                }
            }

        case .shieldBearer:
            // Chase target
            let dir = avoidObstacles(desiredDirection: toTarget.normalized())
            physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)

            // Shield turns toward target with limited turn speed (player can outmaneuver)
            let targetAngle = atan2(toTarget.dy, toTarget.dx)
            var angleDiff = targetAngle - shieldAngle
            // Normalize to [-pi, pi]
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            let maxTurn = shieldTurnSpeed * CGFloat(deltaTime)
            if abs(angleDiff) <= maxTurn {
                shieldAngle = targetAngle
            } else {
                shieldAngle += angleDiff > 0 ? maxTurn : -maxTurn
            }
            shieldFacingDirection = CGVector(dx: cos(shieldAngle), dy: sin(shieldAngle))

            // Rotate shield visual to match (don't use xScale flip for shield bearer)
            shieldVisualNode?.zRotation = shieldAngle

        case .splitter:
            let dir = avoidObstacles(desiredDirection: toTarget.normalized())
            physicsBody?.velocity = CGVector(dx: dir.dx * moveSpeed, dy: dir.dy * moveSpeed)
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
        isSlowed = true
        moveSpeed = baseSpeed * (1.0 - percent)
        colorBlendFactor = 0.6
        color = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
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

    private func groundPound() {
        guard let scene = self.scene else { return }

        let radius: CGFloat = 120
        // Damage player if in range
        scene.enumerateChildNodes(withName: "player") { node, _ in
            let dx = node.position.x - self.position.x
            let dy = node.position.y - self.position.y
            if sqrt(dx * dx + dy * dy) < radius {
                (node as? PlayerNode)?.takeDamage(self.contactDamage * 1.5)
            }
        }

        // Visual shockwave
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = ColorPalette.enemyJuggernaut
        ring.lineWidth = 4
        ring.fillColor = .clear
        ring.position = position
        ring.zPosition = 85
        ring.blendMode = .add
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: radius / 10, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Ground crack particles
        for _ in 0..<16 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20...radius * 0.8)
            let particle = SKSpriteNode(color: SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1), size: CGSize(width: 4, height: 4))
            particle.position = CGPoint(x: position.x + cos(angle) * dist, y: position.y + sin(angle) * dist)
            particle.zPosition = 85
            particle.blendMode = .add
            scene.addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * 20, y: sin(angle) * 20, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
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
