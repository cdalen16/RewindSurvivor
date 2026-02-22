import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Systems
    private let gameState = GameState()
    private let inputManager = InputManager()
    private let combatSystem = CombatSystem()
    private let waveManager = WaveManager()
    private let ghostRecorder = GhostRecorder()
    private let ghostPlayback = GhostPlaybackController()
    private let powerUpManager = PowerUpManager()
    private let cameraManager = CameraManager()
    private let effectsManager = EffectsManager()
    private let superPowerUpManager = SuperPowerUpManager()

    // MARK: - Entities
    private var player: PlayerNode!

    // MARK: - UI
    private var hud: HUDNode!
    private var joystickNode: JoystickNode!
    private var powerUpSelection: PowerUpSelectionNode!
    private var rewindOverlay: RewindOverlay!
    private var mainMenu: MainMenuNode!
    private var gameOverScreen: GameOverNode!
    private var statsScreen: StatsScreenNode!
    private var shopScreen: ShopScreenNode!
    private var pauseOverlay: PauseOverlayNode!
    private var tutorialScreen: TutorialNode!
    private var superPowerUpSelection: SuperPowerUpSelectionNode!
    private var transitionOverlay: SKSpriteNode!

    // MARK: - Arena
    private var arenaNode: SKNode!
    private var freezeAuraContainer: SKNode?

    // MARK: - Timing
    private var lastUpdateTime: TimeInterval = 0
    private var rewindTimer: TimeInterval = 0
    private var pendingGhostRecording: GhostRecording?
    private var gameOverTapDelay: TimeInterval = 0

    // MARK: - Scene Setup

    class func newGameScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        return scene
    }

    private func getSafeAreaInsets() -> UIEdgeInsets {
        return view?.safeAreaInsets ?? .zero
    }

    override func didMove(to view: SKView) {
        backgroundColor = ColorPalette.arenaFloor
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        // Preload textures
        SpriteFactory.shared.preloadAllTextures()

        // Camera
        addChild(cameraManager.cameraNode)
        camera = cameraManager.cameraNode

        // Effects
        effectsManager.setup(scene: self, camera: cameraManager)

        // Build arena
        buildArena()

        // Player
        player = PlayerNode()
        addChild(player)

        // HUD (child of camera so it stays fixed on screen)
        hud = HUDNode()
        cameraManager.cameraNode.addChild(hud)

        // Layout HUD after a brief delay to ensure safe area insets are available
        DispatchQueue.main.async { [weak self] in
            self?.relayoutHUD()
        }

        // Joystick
        joystickNode = JoystickNode()
        addChild(joystickNode)

        // Power-up selection
        powerUpSelection = PowerUpSelectionNode()
        cameraManager.cameraNode.addChild(powerUpSelection)

        // Rewind overlay
        rewindOverlay = RewindOverlay()
        cameraManager.cameraNode.addChild(rewindOverlay)

        // Main menu
        mainMenu = MainMenuNode()
        cameraManager.cameraNode.addChild(mainMenu)

        // Game over screen
        gameOverScreen = GameOverNode()
        cameraManager.cameraNode.addChild(gameOverScreen)

        // Stats screen
        statsScreen = StatsScreenNode()
        cameraManager.cameraNode.addChild(statsScreen)

        // Shop screen
        shopScreen = ShopScreenNode()
        cameraManager.cameraNode.addChild(shopScreen)

        // Pause overlay
        pauseOverlay = PauseOverlayNode()
        cameraManager.cameraNode.addChild(pauseOverlay)

        // Tutorial screen
        tutorialScreen = TutorialNode()
        cameraManager.cameraNode.addChild(tutorialScreen)

        // Super power-up selection
        superPowerUpSelection = SuperPowerUpSelectionNode()
        cameraManager.cameraNode.addChild(superPowerUpSelection)

        // Transition overlay (dip-to-black between screens)
        transitionOverlay = SKSpriteNode(color: .black, size: size)
        transitionOverlay.zPosition = 999
        transitionOverlay.alpha = 0
        transitionOverlay.isHidden = true
        cameraManager.cameraNode.addChild(transitionOverlay)

        // Arena boundary physics
        let boundary = SKPhysicsBody(edgeLoopFrom: CGRect(
            x: -GameConfig.arenaSize.width / 2,
            y: -GameConfig.arenaSize.height / 2,
            width: GameConfig.arenaSize.width,
            height: GameConfig.arenaSize.height
        ))
        boundary.categoryBitMask = PhysicsCategory.wall
        boundary.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        self.physicsBody = boundary

        // Start at main menu
        showMainMenu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        relayoutHUD()
    }

    private func relayoutHUD() {
        guard let _ = hud else { return }
        let insets = getSafeAreaInsets()
        // Convert safe area from view points to scene points
        let sceneInsets = UIEdgeInsets(
            top: insets.top * size.height / (view?.bounds.height ?? size.height),
            left: insets.left * size.width / (view?.bounds.width ?? size.width),
            bottom: insets.bottom * size.height / (view?.bounds.height ?? size.height),
            right: insets.right * size.width / (view?.bounds.width ?? size.width)
        )
        hud.layout(screenSize: size, safeAreaInsets: sceneInsets)
    }

    // MARK: - Arena

    private func buildArena() {
        arenaNode = SKNode()
        arenaNode.name = "arena"
        arenaNode.zPosition = -10

        let tileSize: CGFloat = 64 * 3 // Each tile covers 192 points (64px at 3x scale)
        let halfArena = GameConfig.arenaSize.width / 2
        let wallThickness: CGFloat = tileSize
        let tilesX = Int(GameConfig.arenaSize.width / tileSize) + 1
        let tilesY = Int(GameConfig.arenaSize.height / tileSize) + 1

        // Floor tiles with 6 variants for visual variety
        for row in 0..<tilesY {
            for col in 0..<tilesX {
                let variant = (row * 7 + col * 13 + (row * col * 3)) % 6
                let texture = SpriteFactory.shared.floorTileTexture(variant: variant)
                let tile = SKSpriteNode(texture: texture, size: CGSize(width: tileSize, height: tileSize))
                tile.position = CGPoint(
                    x: -halfArena + CGFloat(col) * tileSize + tileSize / 2,
                    y: -halfArena + CGFloat(row) * tileSize + tileSize / 2
                )
                arenaNode.addChild(tile)
            }
        }

        // Wall border (4 sides)
        let wallTexture = SpriteFactory.shared.wallTileTexture()
        let wallCount = Int(GameConfig.arenaSize.width / tileSize) + 2
        for i in 0..<wallCount {
            let pos = -halfArena + CGFloat(i) * tileSize
            let topWall = SKSpriteNode(texture: wallTexture, size: CGSize(width: tileSize, height: wallThickness))
            topWall.position = CGPoint(x: pos, y: halfArena + wallThickness / 2)
            topWall.zPosition = 2
            arenaNode.addChild(topWall)
            let bottomWall = SKSpriteNode(texture: wallTexture, size: CGSize(width: tileSize, height: wallThickness))
            bottomWall.position = CGPoint(x: pos, y: -halfArena - wallThickness / 2)
            bottomWall.zPosition = 2
            arenaNode.addChild(bottomWall)
            let leftWall = SKSpriteNode(texture: wallTexture, size: CGSize(width: wallThickness, height: tileSize))
            leftWall.position = CGPoint(x: -halfArena - wallThickness / 2, y: pos)
            leftWall.zPosition = 2
            arenaNode.addChild(leftWall)
            let rightWall = SKSpriteNode(texture: wallTexture, size: CGSize(width: wallThickness, height: tileSize))
            rightWall.position = CGPoint(x: halfArena + wallThickness / 2, y: pos)
            rightWall.zPosition = 2
            arenaNode.addChild(rightWall)
        }

        // Corner glow accents
        let glowTexture = SpriteFactory.shared.cornerGlowTexture()
        let glowSize: CGFloat = 500
        let corners: [(CGFloat, CGFloat)] = [
            (-halfArena, -halfArena), (halfArena, -halfArena),
            (-halfArena, halfArena), (halfArena, halfArena)
        ]
        for (cx, cy) in corners {
            let glow = SKSpriteNode(texture: glowTexture, size: CGSize(width: glowSize, height: glowSize))
            glow.position = CGPoint(x: cx, y: cy)
            glow.zPosition = -5
            glow.blendMode = .add
            glow.alpha = 0.5
            arenaNode.addChild(glow)
        }

        // Ambient light pools scattered across floor
        let lightTexture = SpriteFactory.shared.lightPoolTexture()
        let lightPositions: [(CGFloat, CGFloat)] = [
            (0, 0), (-400, -300), (350, 250), (-200, 500),
            (600, -400), (-550, 200), (150, -650), (500, 600),
            (-700, -600), (700, 100), (-100, -400), (300, -200),
        ]
        for (lx, ly) in lightPositions {
            let pool = SKSpriteNode(texture: lightTexture, size: CGSize(width: 300, height: 300))
            pool.position = CGPoint(x: lx, y: ly)
            pool.zPosition = -6
            pool.blendMode = .add
            pool.alpha = 0.8

            // Gentle pulsing
            let pulseDuration = Double.random(in: 3.0...5.0)
            pool.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: pulseDuration),
                SKAction.fadeAlpha(to: 0.8, duration: pulseDuration),
            ])))
            arenaNode.addChild(pool)
        }

        // Scatter crack decals
        let crackTexture = SpriteFactory.shared.crackDecalTexture()
        let crackPositions: [(CGFloat, CGFloat)] = [
            (-300, -400), (200, 300), (-500, 600), (400, -200),
            (700, 500), (-600, -700), (100, -600), (-200, 400),
            (500, -500), (-400, 200), (300, 700),
        ]
        for (cx, cy) in crackPositions {
            let crack = SKSpriteNode(texture: crackTexture, size: CGSize(width: 96, height: 96))
            crack.position = CGPoint(x: cx, y: cy)
            crack.zPosition = -8
            crack.alpha = 0.35
            crack.zRotation = CGFloat(((Int(cx) * 7 + Int(cy) * 13) % 628)) / 100.0
            arenaNode.addChild(crack)
        }

        // Center arena marker (spawn point)
        let centerRing = SKShapeNode(circleOfRadius: 60)
        centerRing.strokeColor = ColorPalette.playerPrimary.withAlphaComponent(0.12)
        centerRing.fillColor = .clear
        centerRing.lineWidth = 2
        centerRing.position = .zero
        centerRing.zPosition = -4
        arenaNode.addChild(centerRing)

        let innerRing = SKShapeNode(circleOfRadius: 30)
        innerRing.strokeColor = ColorPalette.playerPrimary.withAlphaComponent(0.08)
        innerRing.fillColor = .clear
        innerRing.lineWidth = 1
        innerRing.position = .zero
        innerRing.zPosition = -4
        arenaNode.addChild(innerRing)

        // Floating dust motes
        for _ in 0..<25 {
            let dust = SKSpriteNode(color: SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 0.25),
                                     size: CGSize(width: 2, height: 2))
            dust.position = CGPoint(
                x: CGFloat.random(in: -halfArena...halfArena),
                y: CGFloat.random(in: -halfArena...halfArena)
            )
            dust.zPosition = -3
            dust.alpha = CGFloat.random(in: 0.1...0.25)
            arenaNode.addChild(dust)

            let floatDuration = Double.random(in: 4...8)
            let moveX = CGFloat.random(in: -30...30)
            let moveY = CGFloat.random(in: -30...30)
            dust.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: moveX, y: moveY, duration: floatDuration),
                SKAction.moveBy(x: -moveX, y: -moveY, duration: floatDuration),
            ])))
        }

        // Procedural obstacles
        placeObstacles(halfArena: halfArena)

        addChild(arenaNode)
    }

    private func placeObstacles(halfArena: CGFloat) {
        // Seeded RNG for deterministic but varied layout
        srand48(42)
        var placed: [CGPoint] = []
        let minCenterDist: CGFloat = 150  // Keep center clear for spawn
        let minObstacleDist: CGFloat = 120 // Space between obstacles

        func tryPlace(at pos: CGPoint) -> Bool {
            let cx = pos.x, cy = pos.y
            if sqrt(cx * cx + cy * cy) < minCenterDist { return false }
            for p in placed {
                let dx = p.x - cx, dy = p.y - cy
                if sqrt(dx * dx + dy * dy) < minObstacleDist { return false }
            }
            if abs(cx) > halfArena - 120 || abs(cy) > halfArena - 120 { return false }
            placed.append(pos)
            return true
        }

        func addPhysics(to node: SKSpriteNode, rect size: CGSize) {
            let body = SKPhysicsBody(rectangleOf: size)
            body.isDynamic = false
            body.categoryBitMask = PhysicsCategory.wall
            body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy | PhysicsCategory.ghost
            body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.enemyBullet
            node.physicsBody = body
        }

        func addPhysicsCircle(to node: SKSpriteNode, radius: CGFloat) {
            let body = SKPhysicsBody(circleOfRadius: radius)
            body.isDynamic = false
            body.categoryBitMask = PhysicsCategory.wall
            body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy | PhysicsCategory.ghost
            body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.enemyBullet
            node.physicsBody = body
        }

        // Visual indicator: subtle outline glow on obstacles
        func addObstacleGlow(to node: SKSpriteNode) {
            let outline = SKShapeNode(rectOf: CGSize(width: node.size.width + 4, height: node.size.height + 4), cornerRadius: 3)
            outline.strokeColor = SKColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 0.5)
            outline.fillColor = .clear
            outline.lineWidth = 1.5
            outline.zPosition = -0.5
            node.addChild(outline)
        }

        func addObstacleGlowCircle(to node: SKSpriteNode, radius: CGFloat) {
            let outline = SKShapeNode(circleOfRadius: radius + 2)
            outline.strokeColor = SKColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 0.5)
            outline.fillColor = .clear
            outline.lineWidth = 1.5
            outline.zPosition = -0.5
            node.addChild(outline)
        }

        let scale: CGFloat = 3.0

        // --- Crate clusters (groups of 1-3 crates) ---
        let crateClusterPositions: [(CGFloat, CGFloat)] = [
            (-500, -300), (400, 500), (-300, 600), (600, -500),
            (-700, 100), (200, -700), (700, 700), (-600, -600),
            (100, 400), (-400, -700), (500, 200), (-200, 300),
        ]
        for (cx, cy) in crateClusterPositions {
            let pos = CGPoint(x: cx, y: cy)
            guard tryPlace(at: pos) else { continue }

            let crateCount = 1 + Int(drand48() * 2.5) // 1-3 crates
            for i in 0..<crateCount {
                let variant = Int(drand48() * 3)
                let tex = SpriteFactory.shared.crateTexture(variant: variant)
                let size = CGSize(width: 24 * scale, height: 24 * scale)
                let crate = SKSpriteNode(texture: tex, size: size)
                let offsetX = CGFloat(i % 2) * size.width * 0.9 * (drand48() > 0.5 ? 1 : -1)
                let offsetY = CGFloat(i / 2) * size.height * 0.9
                crate.position = CGPoint(x: cx + offsetX, y: cy + offsetY)
                crate.zPosition = 50
                crate.zRotation = CGFloat(drand48() * 0.15 - 0.075)
                addPhysics(to: crate, rect: size * 0.85)
                addObstacleGlow(to: crate)
                arenaNode.addChild(crate)
            }
        }

        // --- Pillars ---
        let pillarPositions: [(CGFloat, CGFloat)] = [
            (-250, -250), (250, -250), (-250, 250), (250, 250),
            (0, -500), (0, 500), (-500, 0), (500, 0),
            (-650, -450), (650, 450), (450, -650), (-450, 650),
        ]
        let pillarTex = SpriteFactory.shared.pillarTexture()
        for (px, py) in pillarPositions {
            let pos = CGPoint(x: px, y: py)
            guard tryPlace(at: pos) else { continue }

            let pillarSize = CGSize(width: 16 * scale, height: 16 * scale)
            let pillar = SKSpriteNode(texture: pillarTex, size: pillarSize)
            pillar.position = pos
            pillar.zPosition = 50
            addPhysicsCircle(to: pillar, radius: 16 * scale / 2 * 0.8)
            addObstacleGlowCircle(to: pillar, radius: 16 * scale / 2)
            arenaNode.addChild(pillar)
        }

        // --- Barriers (wall segments for cover) ---
        let barrierPositions: [(CGFloat, CGFloat, CGFloat)] = [ // x, y, rotation
            (-350, 150, 0), (350, -150, 0),
            (150, 350, CGFloat.pi / 2), (-150, -350, CGFloat.pi / 2),
            (-600, 400, 0.3), (600, -400, -0.3),
            (300, 700, CGFloat.pi / 2), (-300, -700, CGFloat.pi / 2),
            (-700, -300, 0.5), (700, 300, -0.5),
        ]
        let barrierTex = SpriteFactory.shared.barrierTexture()
        for (bx, by, rot) in barrierPositions {
            let pos = CGPoint(x: bx, y: by)
            guard tryPlace(at: pos) else { continue }

            let barrierSize = CGSize(width: 32 * scale, height: 12 * scale)
            let barrier = SKSpriteNode(texture: barrierTex, size: barrierSize)
            barrier.position = pos
            barrier.zPosition = 50
            barrier.zRotation = rot
            addPhysics(to: barrier, rect: barrierSize * 0.9)
            addObstacleGlow(to: barrier)
            arenaNode.addChild(barrier)
        }

        // --- Terminals ---
        let terminalPositions: [(CGFloat, CGFloat)] = [
            (-180, 500), (180, -500), (-550, -200), (550, 200),
            (400, 350), (-400, -350),
        ]
        let terminalTex = SpriteFactory.shared.terminalTexture()
        for (tx, ty) in terminalPositions {
            let pos = CGPoint(x: tx, y: ty)
            guard tryPlace(at: pos) else { continue }

            let termSize = CGSize(width: 20 * scale, height: 20 * scale)
            let terminal = SKSpriteNode(texture: terminalTex, size: termSize)
            terminal.position = pos
            terminal.zPosition = 50
            addPhysics(to: terminal, rect: termSize * 0.85)
            addObstacleGlow(to: terminal)
            arenaNode.addChild(terminal)

            // Screen glow
            let glow = SKSpriteNode(color: SKColor(red: 0, green: 0.3, blue: 0.15, alpha: 0.15),
                                     size: CGSize(width: termSize.width * 1.5, height: termSize.height * 1.5))
            glow.position = pos
            glow.zPosition = 49
            glow.blendMode = .add
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.08, duration: 2.0),
                SKAction.fadeAlpha(to: 0.15, duration: 2.0),
            ])))
            arenaNode.addChild(glow)
        }

        // --- Barrel clusters ---
        let barrelPositions: [(CGFloat, CGFloat)] = [
            (-100, -600), (100, 600), (650, -150), (-650, 150),
            (350, -400), (-350, 400), (800, 600), (-800, -600),
        ]
        for (bx, by) in barrelPositions {
            let pos = CGPoint(x: bx, y: by)
            guard tryPlace(at: pos) else { continue }

            let count = 1 + Int(drand48() * 2.0) // 1-2 barrels
            for i in 0..<count {
                let variant = Int(drand48() * 2)
                let tex = SpriteFactory.shared.barrelTexture(variant: variant)
                let barrelSize = CGSize(width: 14 * scale, height: 14 * scale)
                let barrel = SKSpriteNode(texture: tex, size: barrelSize)
                let ox = CGFloat(i) * barrelSize.width * 0.8 * (drand48() > 0.5 ? 1 : -1)
                barrel.position = CGPoint(x: bx + ox, y: by)
                barrel.zPosition = 50
                addPhysicsCircle(to: barrel, radius: 14 * scale / 2 * 0.75)
                addObstacleGlowCircle(to: barrel, radius: 14 * scale / 2)
                arenaNode.addChild(barrel)
            }
        }
    }

    // MARK: - Game Flow

    private func transition(swap: @escaping () -> Void) {
        transitionOverlay.isHidden = false
        transitionOverlay.alpha = 0
        transitionOverlay.removeAllActions()
        transitionOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.15),
            SKAction.run { swap() },
            SKAction.fadeAlpha(to: 0.0, duration: 0.15),
            SKAction.run { [weak self] in
                self?.transitionOverlay.isHidden = true
            }
        ]))
    }

    @objc private func appWillResignActive() {
        if gameState.gamePhase == .playing {
            saveCurrentRun()
        }
        pauseGame()
    }

    private func pauseGame() {
        guard gameState.gamePhase == .playing else { return }
        gameState.gamePhase = .paused
        inputManager.reset()
        pauseOverlay.show(screenSize: size,
            onResume: { [weak self] in
                self?.resumeGame()
            },
            onQuit: { [weak self] in
                guard let self = self else { return }
                PersistenceManager.shared.clearSavedRun()
                self.isPaused = false
                self.lastUpdateTime = 0
                self.pauseOverlay.hide()
                self.transition {
                    self.cleanupGameplay()
                    self.showMainMenu()
                }
            }
        )
        self.isPaused = true
    }

    private func resumeGame() {
        self.isPaused = false
        lastUpdateTime = 0
        pauseOverlay.hide()
        gameState.gamePhase = .playing
    }

    private func cleanupGameplay() {
        waveManager.removeAll()
        ghostPlayback.removeAll()
        combatSystem.reset()
        superPowerUpManager.reset()
        freezeAuraContainer?.removeFromParent()
        freezeAuraContainer = nil
        enumerateChildNodes(withName: "//pickup") { node, _ in node.removeFromParent() }
    }

    private func showMainMenu() {
        gameState.gamePhase = .mainMenu
        inputManager.reset()
        joystickNode.isHidden = true
        hud.hide()
        player.isHidden = true
        SpriteFactory.shared.invalidatePlayerTextures()
        let hasSaved = PersistenceManager.shared.hasSavedRun
        mainMenu.show(screenSize: size,
            hasSavedRun: hasSaved,
            onPlay: { [weak self] in
                guard let self = self else { return }
                PersistenceManager.shared.clearSavedRun()
                self.transition {
                    self.mainMenu.hide()
                    self.startNewGame()
                }
            },
            onResume: hasSaved ? { [weak self] in
                guard let self = self else { return }
                self.transition {
                    self.mainMenu.hide()
                    self.resumeFromSavedRun()
                }
            } : nil,
            onShop: { [weak self] in
                guard let self = self else { return }
                self.transition {
                    self.mainMenu.hide()
                    self.gameState.gamePhase = .shopScreen
                    self.shopScreen.show(screenSize: self.size) { [weak self] in
                        guard let self = self else { return }
                        self.transition {
                            self.shopScreen.hide()
                            self.showMainMenu()
                        }
                    }
                }
            },
            onStats: { [weak self] in
                guard let self = self else { return }
                self.transition {
                    self.mainMenu.hide()
                    self.gameState.gamePhase = .statsScreen
                    self.statsScreen.show(screenSize: self.size) { [weak self] in
                        guard let self = self else { return }
                        self.transition {
                            self.statsScreen.hide()
                            self.showMainMenu()
                        }
                    }
                }
            },
            onTutorial: { [weak self] in
                guard let self = self else { return }
                self.transition {
                    self.mainMenu.hide()
                    self.gameState.gamePhase = .tutorial
                    self.tutorialScreen.show(screenSize: self.size) { [weak self] in
                        guard let self = self else { return }
                        self.transition {
                            self.tutorialScreen.hide()
                            self.showMainMenu()
                        }
                    }
                }
            }
        )
    }

    private func startNewGame() {
        gameState.reset()
        gameState.gamePhase = .playing
        inputManager.reset()
        joystickNode.isHidden = false

        // Clean up freeze aura visual
        freezeAuraContainer?.removeFromParent()
        freezeAuraContainer = nil

        player.isHidden = false
        player.resetForNewGame(gameState: gameState)
        combatSystem.reset()
        superPowerUpManager.reset()
        ghostRecorder.reset()
        ghostPlayback.removeAll()
        waveManager.removeAll()

        hud.show()

        // Start wave 1
        gameState.currentWave = 1
        beginWave()
    }

    private func beginWave() {
        let enemyCount = EnemyType.enemyCount(forWave: gameState.currentWave)
        hud.showWaveBanner(wave: gameState.currentWave, enemyCount: enemyCount)
        waveManager.beginWave(
            wave: gameState.currentWave,
            scene: self,
            gameState: gameState,
            ghostCount: ghostPlayback.activeGhosts.count
        )

        if let cam = camera {
            ParticleFactory.waveTransitionScanline(screenSize: size, scene: self, camera: cam)
        }
    }

    private func onWaveComplete() {
        gameState.currentWave += 1
        // Check for super power-up selection before normal power-ups
        if superPowerUpManager.shouldShowSuperSelection(
            wave: gameState.currentWave,
            deathsAvailable: gameState.deathsRemaining,
            acquired: gameState.acquiredSuperPowerUps
        ) && superPowerUpManager.canAffordAny(
            deathsAvailable: gameState.deathsRemaining,
            acquired: gameState.acquiredSuperPowerUps
        ) {
            beginSuperPowerUpSelect()
        } else {
            beginPowerUpSelect()
        }
    }

    private func beginSuperPowerUpSelect() {
        gameState.gamePhase = .superPowerUpSelect
        inputManager.reset()
        let choices = superPowerUpManager.generateChoices(
            deathsAvailable: gameState.deathsRemaining,
            acquired: gameState.acquiredSuperPowerUps
        )
        superPowerUpSelection.show(
            choices: choices,
            deathsAvailable: gameState.deathsRemaining,
            screenSize: size,
            onSelect: { [weak self] selected in
                guard let self = self else { return }
                self.superPowerUpManager.apply(
                    selected, gameState: self.gameState, scene: self,
                    player: self.player, enemies: self.waveManager.activeEnemies,
                    combatSystem: self.combatSystem
                )
                // Visual feedback
                ParticleFactory.powerUpPickup(at: self.player.position, color: selected.iconColor, scene: self)
                // Proceed to normal power-up selection
                self.beginPowerUpSelect()
            },
            onSkip: { [weak self] in
                self?.beginPowerUpSelect()
            }
        )
    }

    private func beginPowerUpSelect() {
        gameState.gamePhase = .powerUpSelect
        inputManager.reset()
        let choices = powerUpManager.generateChoices(count: 3, gameState: gameState)
        powerUpSelection.show(choices: choices, gameState: gameState, screenSize: size) { [weak self] selected in
            guard let self = self else { return }
            self.powerUpManager.apply(selected, to: self.gameState, player: self.player)

            // Visual feedback
            ParticleFactory.powerUpPickup(at: self.player.position, color: selected.iconColor, scene: self)

            self.gameState.gamePhase = .playing
            self.beginWave()
        }
    }

    private func onPlayerDeath() {
        if gameState.deathsRemaining > 0 {
            gameState.deathsRemaining -= 1

            // Extract ghost recording
            let recording = ghostRecorder.extractRecording()
            pendingGhostRecording = recording

            // Player death VFX
            ParticleFactory.playerDeathExplosion(at: player.position, scene: self)
            effectsManager.shakeHeavy()

            // Start rewind
            gameState.gamePhase = .deathRewind
            rewindTimer = GameConfig.rewindEffectDuration
            inputManager.reset()
            rewindOverlay.show(screenSize: size)

            // Freeze enemies
            waveManager.freezeAll()

            // Hide player during rewind
            player.isHidden = true
        } else {
            // Game over
            PersistenceManager.shared.clearSavedRun()
            gameState.gamePhase = .gameOver
            gameState.isGameOver = true
            inputManager.reset()
            ParticleFactory.playerDeathExplosion(at: player.position, scene: self)
            effectsManager.shakeExtreme()
            player.isHidden = true
            hud.hide()

            // Save stats
            let ghostsUsed = gameState.nextDeathThresholdIndex + GameConfig.initialDeaths - gameState.deathsRemaining
            PersistenceManager.shared.recordGameEnd(
                score: gameState.score,
                wave: gameState.currentWave,
                kills: gameState.killsThisRun,
                deaths: ghostsUsed,
                playTime: gameState.gameTime,
                coinsEarned: gameState.coinsEarnedThisRun
            )

            gameOverTapDelay = 2.0
            gameOverScreen.show(screenSize: size, gameState: gameState) { [weak self] in
                guard let self = self else { return }
                self.transition {
                    self.gameOverScreen.hide()
                    self.showMainMenu()
                }
            }
        }
    }

    private func completeRewind() {
        // Spawn ghost
        if let recording = pendingGhostRecording, !recording.snapshots.isEmpty {
            ghostPlayback.spawnGhost(from: recording, scene: self)
        }
        pendingGhostRecording = nil

        // Reset player
        player.isHidden = false
        player.position = .zero
        player.maxHP = GameConfig.playerBaseHP + gameState.playerHPBonus
        player.hp = player.maxHP
        player.applyInvincibility()

        // Reset recorder
        ghostRecorder.reset()

        // Unfreeze enemies
        waveManager.unfreezeAll()

        // Hide rewind overlay
        rewindOverlay.hide()

        // Flash
        effectsManager.flashWhite(duration: 0.2)

        gameState.gamePhase = .playing
    }

    // MARK: - Save / Resume

    private func saveCurrentRun() {
        guard gameState.gamePhase == .playing else { return }

        // Serialize enemies
        let savedEnemies: [SavedEnemy] = waveManager.activeEnemies.compactMap { enemy in
            guard enemy.parent != nil && enemy.hp > 0 else { return nil }
            return SavedEnemy(
                typeName: enemy.enemyType.name,
                position: CodablePoint(x: Double(enemy.position.x), y: Double(enemy.position.y)),
                hp: Double(enemy.hp),
                maxHP: Double(enemy.maxHP),
                splitGeneration: enemy.splitGeneration,
                scale: Double(abs(enemy.xScale))
            )
        }

        // Serialize ghosts
        let savedGhosts: [SavedGhostRecording] = ghostPlayback.activeGhosts.enumerated().map { (index, ghost) in
            let snaps = ghost.recording.snapshots.map { s in
                SavedSnapshot(
                    position: CodablePoint(x: Double(s.position.x), y: Double(s.position.y)),
                    facingDirection: CodableVector(dx: Double(s.facingDirection.dx), dy: Double(s.facingDirection.dy)),
                    isFiring: s.isFiring,
                    timestamp: s.timestamp
                )
            }
            return SavedGhostRecording(snapshots: snaps, ghostLevel: ghost.ghostLevel, orbitIndex: index)
        }

        // Serialize spawn queue
        let savedQueue: [SavedSpawnEntry] = waveManager.currentSpawnQueue.map { entry in
            SavedSpawnEntry(typeName: entry.0.name, count: entry.1)
        }

        // Serialize acquired power-ups
        let acquiredPUs: [String: Int] = Dictionary(uniqueKeysWithValues:
            gameState.acquiredPowerUps.map { ($0.key.rawValue, $0.value) }
        )
        let acquiredSupers: [String] = gameState.acquiredSuperPowerUps.map { $0.rawValue }

        let state = SavedRunState(
            score: gameState.score,
            currentWave: gameState.currentWave,
            deathsRemaining: gameState.deathsRemaining,
            nextDeathThresholdIndex: gameState.nextDeathThresholdIndex,
            gameTime: gameState.gameTime,
            playerSpeedMultiplier: Double(gameState.playerSpeedMultiplier),
            playerDamageMultiplier: Double(gameState.playerDamageMultiplier),
            playerAttackSpeedMultiplier: Double(gameState.playerAttackSpeedMultiplier),
            playerProjectileCountBonus: gameState.playerProjectileCountBonus,
            playerHPBonus: Double(gameState.playerHPBonus),
            playerProjectilePiercing: gameState.playerProjectilePiercing,
            playerGhostDamageMultiplier: Double(gameState.playerGhostDamageMultiplier),
            pickupMagnetRange: Double(gameState.pickupMagnetRange),
            orbitalCount: gameState.orbitalCount,
            chainLightningBounces: gameState.chainLightningBounces,
            lifeStealPercent: Double(gameState.lifeStealPercent),
            explosionRadius: Double(gameState.explosionRadius),
            thornsDamage: Double(gameState.thornsDamage),
            freezeAuraRadius: Double(gameState.freezeAuraRadius),
            freezeAuraSlowPercent: Double(gameState.freezeAuraSlowPercent),
            critChance: Double(gameState.critChance),
            acquiredPowerUps: acquiredPUs,
            acquiredSuperPowerUps: acquiredSupers,
            coinsEarnedThisRun: gameState.coinsEarnedThisRun,
            killsThisRun: gameState.killsThisRun,
            playerPosition: CodablePoint(x: Double(player.position.x), y: Double(player.position.y)),
            playerHP: Double(player.hp),
            playerMaxHP: Double(player.maxHP),
            enemies: savedEnemies,
            ghosts: savedGhosts,
            spawnQueue: savedQueue,
            totalToSpawn: waveManager.currentTotalToSpawn,
            totalSpawned: waveManager.currentTotalSpawned,
            spawnTimer: waveManager.currentSpawnTimer,
            spawnInterval: waveManager.currentSpawnInterval,
            attackTimer: combatSystem.currentAttackTimer,
            orbitalAngle: Double(combatSystem.currentOrbitalAngle)
        )

        PersistenceManager.shared.saveRun(state)
    }

    private func resumeFromSavedRun() {
        guard let state = PersistenceManager.shared.loadSavedRun() else {
            showMainMenu()
            return
        }
        PersistenceManager.shared.clearSavedRun()

        // Reset everything first
        gameState.reset()
        cleanupGameplay()

        // Restore GameState
        gameState.score = state.score
        gameState.currentWave = state.currentWave
        gameState.deathsRemaining = state.deathsRemaining
        gameState.nextDeathThresholdIndex = state.nextDeathThresholdIndex
        gameState.gameTime = state.gameTime
        gameState.playerSpeedMultiplier = CGFloat(state.playerSpeedMultiplier)
        gameState.playerDamageMultiplier = CGFloat(state.playerDamageMultiplier)
        gameState.playerAttackSpeedMultiplier = CGFloat(state.playerAttackSpeedMultiplier)
        gameState.playerProjectileCountBonus = state.playerProjectileCountBonus
        gameState.playerHPBonus = CGFloat(state.playerHPBonus)
        gameState.playerProjectilePiercing = state.playerProjectilePiercing
        gameState.playerGhostDamageMultiplier = CGFloat(state.playerGhostDamageMultiplier)
        gameState.pickupMagnetRange = CGFloat(state.pickupMagnetRange)
        gameState.orbitalCount = state.orbitalCount
        gameState.chainLightningBounces = state.chainLightningBounces
        gameState.lifeStealPercent = CGFloat(state.lifeStealPercent)
        gameState.explosionRadius = CGFloat(state.explosionRadius)
        gameState.thornsDamage = CGFloat(state.thornsDamage)
        gameState.freezeAuraRadius = CGFloat(state.freezeAuraRadius)
        gameState.freezeAuraSlowPercent = CGFloat(state.freezeAuraSlowPercent)
        gameState.critChance = CGFloat(state.critChance)
        gameState.coinsEarnedThisRun = state.coinsEarnedThisRun
        gameState.killsThisRun = state.killsThisRun

        // Restore acquired power-ups
        for (rawValue, count) in state.acquiredPowerUps {
            if let type = PowerUpType(rawValue: rawValue) {
                gameState.acquiredPowerUps[type] = count
            }
        }
        for rawValue in state.acquiredSuperPowerUps {
            if let type = SuperPowerUpType(rawValue: rawValue) {
                gameState.acquiredSuperPowerUps.insert(type)
            }
        }

        // Set phase to playing
        gameState.gamePhase = .playing
        inputManager.reset()
        joystickNode.isHidden = false

        // Restore player
        player.isHidden = false
        player.maxHP = CGFloat(state.playerMaxHP)
        player.hp = CGFloat(state.playerHP)
        player.position = CGPoint(x: state.playerPosition.x, y: state.playerPosition.y)
        player.isInvincible = false

        // Restore freeze aura visual
        freezeAuraContainer?.removeFromParent()
        freezeAuraContainer = nil

        // Restore enemies
        let ghostCount = state.ghosts.count
        for savedEnemy in state.enemies {
            guard let enemyType = EnemyType.typeByName(savedEnemy.typeName) else { continue }
            let enemy = EnemyNode(type: enemyType, wave: state.currentWave, ghostCount: ghostCount)
            enemy.position = CGPoint(x: savedEnemy.position.x, y: savedEnemy.position.y)
            enemy.restoreHP(CGFloat(savedEnemy.hp), maxHP: CGFloat(savedEnemy.maxHP))
            enemy.splitGeneration = savedEnemy.splitGeneration

            if savedEnemy.scale != 1.0 {
                let scaleFactor = CGFloat(savedEnemy.scale)
                enemy.setScale(scaleFactor)
                // Recreate physics body for scaled enemies
                let scaledRadius = CGFloat(enemyType.spriteSize) * 0.4 * scaleFactor
                let body = SKPhysicsBody(circleOfRadius: scaledRadius)
                body.categoryBitMask = PhysicsCategory.enemy
                body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.player
                body.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy
                body.allowsRotation = false
                body.affectedByGravity = false
                body.linearDamping = 0
                body.friction = 0
                enemy.physicsBody = body
            }

            addChild(enemy)
            waveManager.registerEnemy(enemy)
        }

        // Restore wave manager spawn state
        let restoredQueue: [(EnemyType, Int)] = state.spawnQueue.compactMap { entry in
            guard let type = EnemyType.typeByName(entry.typeName) else { return nil }
            return (type, entry.count)
        }
        waveManager.restoreState(
            spawnQueue: restoredQueue,
            totalToSpawn: state.totalToSpawn,
            totalSpawned: state.totalSpawned,
            spawnTimer: state.spawnTimer,
            spawnInterval: state.spawnInterval
        )

        // Restore combat system
        combatSystem.restoreState(
            attackTimer: state.attackTimer,
            orbitalAngle: CGFloat(state.orbitalAngle)
        )

        // Restore ghosts
        ghostRecorder.reset()
        for savedGhost in state.ghosts {
            let snapshots = savedGhost.snapshots.map { s in
                PlayerSnapshot(
                    position: CGPoint(x: s.position.x, y: s.position.y),
                    facingDirection: CGVector(dx: s.facingDirection.dx, dy: s.facingDirection.dy),
                    isFiring: s.isFiring,
                    timestamp: s.timestamp
                )
            }
            let recording = GhostRecording(snapshots: snapshots)
            ghostPlayback.spawnGhost(from: recording, scene: self)
            // Upgrade to saved level
            if let ghost = ghostPlayback.activeGhosts.last {
                for _ in 1..<savedGhost.ghostLevel {
                    ghost.upgrade()
                }
            }
        }

        // Respawn shadow clone if acquired
        if gameState.acquiredSuperPowerUps.contains(.shadowClone) {
            superPowerUpManager.respawnShadowClone(scene: self, player: player)
        }

        hud.show()
        hud.showWaveBanner(wave: gameState.currentWave, enemyCount: waveManager.enemiesRemaining)
        lastUpdateTime = 0
    }

    // MARK: - Minion Spawning (called by Necromancer)

    func spawnMinion(at position: CGPoint) {
        waveManager.spawnMinion(
            at: position,
            scene: self,
            wave: gameState.currentWave,
            ghostCount: ghostPlayback.activeGhosts.count
        )
    }

    // MARK: - Splitter Spawning

    private func handleSplitterDeath(_ enemy: EnemyNode) {
        guard enemy.behavior == .splitter && enemy.canSplit else { return }
        let nextGen = enemy.splitGeneration + 1
        let wave = gameState.currentWave
        let ghostCount = ghostPlayback.activeGhosts.count
        // Each generation is smaller and weaker (spawned at lower effective wave)
        let effectiveWave = max(1, wave - nextGen * 2)
        let scaleFactor = pow(0.7, CGFloat(nextGen))
        for i in 0..<2 {
            let spread = 18.0 * scaleFactor
            let offset = CGFloat(i == 0 ? -spread : spread)
            let child = EnemyNode(type: .splitter, wave: effectiveWave, ghostCount: ghostCount)
            child.splitGeneration = nextGen
            child.position = CGPoint(x: enemy.position.x + offset, y: enemy.position.y)
            child.setScale(scaleFactor)
            // Recreate physics body to match scaled size
            let scaledRadius = CGFloat(EnemyType.splitter.spriteSize) * 0.4 * scaleFactor
            let body = SKPhysicsBody(circleOfRadius: scaledRadius)
            body.categoryBitMask = PhysicsCategory.enemy
            body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.player
            body.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy
            body.allowsRotation = false
            body.affectedByGravity = false
            body.linearDamping = 0
            body.friction = 0
            child.physicsBody = body
            child.alpha = 0
            addChild(child)
            waveManager.registerEnemy(child)
            child.run(SKAction.fadeIn(withDuration: 0.2))
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let rawDT = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = min(rawDT, 1.0 / 30.0) // Clamp to prevent spiral

        switch gameState.gamePhase {
        case .playing:
            updatePlaying(dt: dt)

        case .deathRewind:
            updateRewind(dt: dt)

        case .gameOver:
            gameOverTapDelay -= dt

        case .paused, .powerUpSelect, .superPowerUpSelect, .mainMenu, .waveComplete, .statsScreen, .shopScreen, .tutorial:
            break
        }
    }

    private func updatePlaying(dt: TimeInterval) {
        gameState.gameTime += dt

        // Input
        let velocity = inputManager.currentVelocity

        // Player
        player.update(deltaTime: dt, velocity: velocity, gameState: gameState)

        // Ghost recorder
        ghostRecorder.record(
            player: player,
            gameTime: gameState.gameTime,
            isFiring: combatSystem.currentTarget != nil
        )

        // Ghost playback
        ghostPlayback.update(
            deltaTime: dt,
            scene: self,
            gameState: gameState,
            enemies: waveManager.activeEnemies,
            combatSystem: combatSystem,
            playerPosition: player.position
        )

        // Combat
        combatSystem.update(
            deltaTime: dt,
            player: player,
            enemies: waveManager.activeEnemies,
            scene: self,
            gameState: gameState
        )

        // Handle orbital kills and hits
        for kill in combatSystem.pendingOrbitalKills {
            gameState.score += kill.enemy.pointValue
            gameState.killsThisRun += 1
            spawnCoinPickups(at: kill.position, value: kill.enemy.pointValue)
            handleSplitterDeath(kill.enemy)
            kill.enemy.die(scene: self)
            waveManager.enemyDied(kill.enemy)
            effectsManager.spawnScoreNumber(at: kill.position, score: kill.enemy.pointValue)
            effectsManager.shakeLight()
        }
        for (hitPos, damage) in combatSystem.pendingOrbitalHits {
            effectsManager.spawnDamageNumber(at: hitPos, text: "\(Int(damage))", color: ColorPalette.playerPrimary)
        }

        // Enemies
        var targets: [SKNode] = [player]
        targets.append(contentsOf: ghostPlayback.ghostTargetNodes)
        for enemy in waveManager.activeEnemies {
            enemy.update(deltaTime: dt, targets: targets)
        }

        // Wave manager
        waveManager.update(
            deltaTime: dt,
            scene: self,
            gameState: gameState,
            ghostCount: ghostPlayback.activeGhosts.count,
            playerPosition: player.position
        )

        // Super power-ups
        superPowerUpManager.update(
            deltaTime: dt, scene: self, enemies: waveManager.activeEnemies,
            player: player, gameState: gameState, combatSystem: combatSystem
        )

        // Camera
        cameraManager.update(target: player.position, deltaTime: dt, sceneSize: size)

        // Joystick visual
        joystickNode.update(inputManager: inputManager, camera: cameraManager.cameraNode, scene: self)

        // HUD
        hud.refresh(
            gameState: gameState,
            playerHP: player.hp,
            playerMaxHP: player.maxHP,
            ghostCount: ghostPlayback.activeGhosts.count,
            enemiesRemaining: waveManager.enemiesRemaining
        )

        // Freeze aura
        if gameState.freezeAuraRadius > 0 {
            let radius = gameState.freezeAuraRadius

            // Build container if needed
            if freezeAuraContainer == nil {
                let container = SKNode()
                container.name = "freezeAuraContainer"
                container.zPosition = 95

                // Layer 1: Outer frost ring — thick, bright border
                let outerRing = SKShapeNode(circleOfRadius: radius)
                outerRing.name = "outerRing"
                outerRing.strokeColor = SKColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.7)
                outerRing.fillColor = .clear
                outerRing.lineWidth = 3.5
                outerRing.glowWidth = 4.0
                outerRing.blendMode = .add
                outerRing.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.8),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.8),
                ])))
                container.addChild(outerRing)

                // Layer 2: Inner fill — noticeably visible frost tint
                let innerFill = SKShapeNode(circleOfRadius: radius)
                innerFill.name = "innerFill"
                innerFill.strokeColor = .clear
                innerFill.fillColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.18)
                innerFill.blendMode = .add
                container.addChild(innerFill)

                // Layer 3: Core glow — brighter center pool
                let coreGlow = SKShapeNode(circleOfRadius: radius * 0.4)
                coreGlow.name = "coreGlow"
                coreGlow.strokeColor = .clear
                coreGlow.fillColor = SKColor(red: 0.6, green: 0.88, blue: 1.0, alpha: 0.12)
                coreGlow.blendMode = .add
                coreGlow.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.06, duration: 1.2),
                    SKAction.fadeAlpha(to: 0.18, duration: 1.2),
                ])))
                container.addChild(coreGlow)

                // Layer 4: Drifting snowflakes (8 inside the aura)
                for i in 0..<8 {
                    let variant = i % 3
                    let tex = SpriteFactory.shared.snowflakeTexture(variant: variant)
                    let flakeSize: CGFloat = CGFloat.random(in: 14...22)
                    let snowflake = SKSpriteNode(texture: tex, size: CGSize(width: flakeSize, height: flakeSize))
                    snowflake.name = "snowflake_\(i)"
                    snowflake.blendMode = .add
                    snowflake.alpha = 0
                    snowflake.zRotation = CGFloat.random(in: 0...(2 * .pi))
                    container.addChild(snowflake)
                }

                // Layer 5: Sparkle twinkles (8 random positions)
                for i in 0..<8 {
                    let sparkle = SKSpriteNode(color: SKColor.white, size: CGSize(width: 2, height: 2))
                    sparkle.name = "iceSparkle_\(i)"
                    sparkle.blendMode = .add
                    sparkle.alpha = 0
                    container.addChild(sparkle)
                }

                addChild(container)
                freezeAuraContainer = container
            }

            // Update container position to follow player
            if let container = freezeAuraContainer {
                container.position = player.position

                // Update ring/fill sizes if radius changed
                if let outerRing = container.childNode(withName: "outerRing") as? SKShapeNode {
                    let newPath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
                    outerRing.path = newPath
                }
                if let innerFill = container.childNode(withName: "innerFill") as? SKShapeNode {
                    let newPath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
                    innerFill.path = newPath
                }
                if let coreGlow = container.childNode(withName: "coreGlow") as? SKShapeNode {
                    let coreR = radius * 0.4
                    coreGlow.path = CGPath(ellipseIn: CGRect(x: -coreR, y: -coreR, width: coreR * 2, height: coreR * 2), transform: nil)
                }

                // Update drifting snowflakes — float gently inside the aura
                for i in 0..<8 {
                    if let snowflake = container.childNode(withName: "snowflake_\(i)") as? SKSpriteNode {
                        if snowflake.alpha <= 0.01 && !snowflake.hasActions() {
                            // Spawn at random position inside the aura, drift downward and rotate
                            let spawnAngle = CGFloat.random(in: 0...(2 * .pi))
                            let spawnDist = CGFloat.random(in: 0...(radius * 0.8))
                            snowflake.position = CGPoint(x: cos(spawnAngle) * spawnDist, y: sin(spawnAngle) * spawnDist)
                            snowflake.alpha = 0
                            snowflake.setScale(CGFloat.random(in: 0.8...1.2))

                            let driftDuration = CGFloat.random(in: 1.5...3.0)
                            let driftX = CGFloat.random(in: -20...20)
                            let driftY = CGFloat.random(in: -25 ... -10)
                            let spin = CGFloat.random(in: -1.5...1.5)
                            snowflake.run(SKAction.sequence([
                                SKAction.group([
                                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.4...0.75), duration: 0.3),
                                    SKAction.move(by: CGVector(dx: driftX * 0.3, dy: driftY * 0.3), duration: TimeInterval(driftDuration * 0.3)),
                                    SKAction.rotate(byAngle: spin * 0.3, duration: TimeInterval(driftDuration * 0.3))
                                ]),
                                SKAction.group([
                                    SKAction.move(by: CGVector(dx: driftX * 0.7, dy: driftY * 0.7), duration: TimeInterval(driftDuration * 0.7)),
                                    SKAction.rotate(byAngle: spin * 0.7, duration: TimeInterval(driftDuration * 0.7)),
                                    SKAction.fadeOut(withDuration: TimeInterval(driftDuration * 0.7))
                                ])
                            ]), withKey: "snowflakeDrift")
                        }
                    }
                }

                // Update sparkles — twinkle at random positions
                for i in 0..<8 {
                    if let sparkle = container.childNode(withName: "iceSparkle_\(i)") as? SKSpriteNode {
                        if sparkle.alpha <= 0.01 && !sparkle.hasActions() {
                            let angle = CGFloat.random(in: 0...(2 * .pi))
                            let dist = CGFloat.random(in: 0...(radius * 0.9))
                            sparkle.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
                            sparkle.run(SKAction.sequence([
                                SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...0.9), duration: CGFloat.random(in: 0.15...0.3)),
                                SKAction.fadeOut(withDuration: CGFloat.random(in: 0.2...0.5))
                            ]), withKey: "sparkleAnim")
                        }
                    }
                }
            }

            for enemy in waveManager.activeEnemies {
                let dx = enemy.position.x - player.position.x
                let dy = enemy.position.y - player.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < gameState.freezeAuraRadius {
                    enemy.applySlow(gameState.freezeAuraSlowPercent)
                } else {
                    enemy.removeSlow()
                }
            }
        } else {
            freezeAuraContainer?.removeFromParent()
            freezeAuraContainer = nil
        }

        // Coin pickups + magnet
        updatePickups(dt: dt)

        // Check death threshold
        if gameState.checkDeathThreshold() {
            hud.showDeathEarned()
            effectsManager.flashWhite(duration: 0.15)
        }

        // Check wave complete
        if waveManager.isWaveComplete {
            onWaveComplete()
        }
    }

    private func updateRewind(dt: TimeInterval) {
        rewindTimer -= dt
        let progress = 1.0 - CGFloat(rewindTimer / GameConfig.rewindEffectDuration)
        rewindOverlay.update(progress: progress)

        if rewindTimer <= 0 {
            completeRewind()
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = sortBodies(contact)
        let maskA = bodyA.categoryBitMask
        let maskB = bodyB.categoryBitMask

        // After sorting: bodyA has the LOWER bitmask
        // Order: player(1) < enemy(2) < playerBullet(4) < enemyBullet(8) < ghost(16) < ghostBullet(32)

        // Player contacts enemy: player(1) + enemy(2)
        if maskA == PhysicsCategory.player && maskB == PhysicsCategory.enemy {
            handleEnemyContactPlayer(enemy: bodyB.node as? EnemyNode)
        }
        // Player hit by enemy bullet: player(1) + enemyBullet(8)
        else if maskA == PhysicsCategory.player && maskB == PhysicsCategory.enemyBullet {
            handleEnemyBulletHitPlayer(projectile: bodyB.node as? ProjectileNode)
        }
        // Enemy hit by player bullet: enemy(2) + playerBullet(4)
        else if maskA == PhysicsCategory.enemy && maskB == PhysicsCategory.playerBullet {
            handleProjectileHitEnemy(projectile: bodyB.node as? ProjectileNode, enemy: bodyA.node as? EnemyNode)
        }
        // Enemy hit by ghost bullet: enemy(2) + ghostBullet(32)
        else if maskA == PhysicsCategory.enemy && maskB == PhysicsCategory.ghostBullet {
            handleProjectileHitEnemy(projectile: bodyB.node as? ProjectileNode, enemy: bodyA.node as? EnemyNode)
        }
        // Player picks up coin: player(1) + pickup(128)
        else if maskA == PhysicsCategory.player && maskB == PhysicsCategory.pickup {
            handlePickupCollected(pickup: bodyB.node as? PickupNode)
        }
        // Shadow clone hit by enemy bullet: ghost(16) + enemyBullet(8)
        else if maskA == PhysicsCategory.enemyBullet && maskB == PhysicsCategory.ghost {
            handleEnemyBulletHitClone(projectile: bodyA.node as? ProjectileNode, clone: bodyB.node as? ShadowCloneNode)
        }
        else if maskA == PhysicsCategory.ghost && maskB == PhysicsCategory.enemyBullet {
            handleEnemyBulletHitClone(projectile: bodyB.node as? ProjectileNode, clone: bodyA.node as? ShadowCloneNode)
        }
        // Bullet hits wall/obstacle: bullet(4/8/32) + wall(64)
        // Always destroy on wall hit, even if piercing
        else if maskB == PhysicsCategory.wall {
            if let projectile = bodyA.node as? ProjectileNode {
                projectile.onWallHit()
            }
        }
    }

    private func sortBodies(_ contact: SKPhysicsContact) -> (SKPhysicsBody, SKPhysicsBody) {
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            return (contact.bodyA, contact.bodyB)
        }
        return (contact.bodyB, contact.bodyA)
    }

    private func handleProjectileHitEnemy(projectile: ProjectileNode?, enemy: EnemyNode?) {
        guard let projectile = projectile, let enemy = enemy else { return }
        guard enemy.parent != nil && enemy.hp > 0 else { return }

        // Shield Bearer: block projectiles hitting from the front
        if enemy.behavior == .shieldBearer {
            let incomingDir = projectile.projectileVelocity.normalized()
            let dot = enemy.shieldFacingDirection.dx * incomingDir.dx + enemy.shieldFacingDirection.dy * incomingDir.dy
            if dot < 0 {
                // Projectile hitting the shielded side — block it
                effectsManager.spawnShieldBlockSpark(at: enemy.position, shieldDirection: enemy.shieldFacingDirection)
                projectile.removeFromParent()
                return
            }
        }

        let damage = projectile.damage
        let killed = enemy.takeDamage(damage)

        // Life steal
        if gameState.lifeStealPercent > 0 && (projectile.projectileType == .player || projectile.projectileType == .ghost) {
            let healAmount = damage * gameState.lifeStealPercent
            player.heal(healAmount)
        }

        if killed {
            let points = enemy.pointValue
            gameState.score += points
            gameState.killsThisRun += 1
            spawnCoinPickups(at: enemy.position, value: points)
            handleSplitterDeath(enemy)
            enemy.die(scene: self)
            waveManager.enemyDied(enemy)
            effectsManager.spawnScoreNumber(at: enemy.position, score: points)
            effectsManager.shakeLight()
        } else {
            let dmgColor: SKColor = projectile.isCrit ? ColorPalette.gold : .white
            let dmgText = projectile.isCrit ? "\(Int(damage))!" : "\(Int(damage))"
            effectsManager.spawnDamageNumber(at: enemy.position, text: dmgText, color: dmgColor)
        }

        // Chain lightning
        if gameState.chainLightningBounces > 0 && (projectile.projectileType == .player || projectile.projectileType == .ghost) {
            chainLightning(from: enemy.position, damage: damage * 0.7, bouncesRemaining: gameState.chainLightningBounces, hitEnemies: [ObjectIdentifier(enemy)])
        }

        // Explosive rounds
        if gameState.explosionRadius > 0 && (projectile.projectileType == .player || projectile.projectileType == .ghost) {
            let explosionDmg = damage * 0.5
            let hitPos = enemy.position
            for other in waveManager.activeEnemies {
                guard other !== enemy, other.parent != nil, other.hp > 0 else { continue }
                let dx = other.position.x - hitPos.x
                let dy = other.position.y - hitPos.y
                if sqrt(dx * dx + dy * dy) < gameState.explosionRadius {
                    let otherKilled = other.takeDamage(explosionDmg)
                    if otherKilled {
                        gameState.score += other.pointValue
                        gameState.killsThisRun += 1
                        spawnCoinPickups(at: other.position, value: other.pointValue)
                        handleSplitterDeath(other)
                        other.die(scene: self)
                        waveManager.enemyDied(other)
                        effectsManager.spawnScoreNumber(at: other.position, score: other.pointValue)
                    }
                }
            }
            // Visual explosion — 4 layers
            let expRadius = gameState.explosionRadius

            // Layer 1: Bright center flash (white/yellow)
            let centerFlash = SKShapeNode(circleOfRadius: expRadius * 0.3)
            centerFlash.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
            centerFlash.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.8)
            centerFlash.lineWidth = 2
            centerFlash.position = hitPos
            centerFlash.zPosition = 88
            centerFlash.blendMode = .add
            addChild(centerFlash)
            centerFlash.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 2.5, duration: 0.15),
                    SKAction.fadeOut(withDuration: 0.15)
                ]),
                SKAction.removeFromParent()
            ]))

            // Layer 2: Orange fireball
            let fireball = SKShapeNode(circleOfRadius: expRadius * 0.5)
            fireball.fillColor = SKColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 0.7)
            fireball.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.5)
            fireball.lineWidth = 3
            fireball.position = hitPos
            fireball.zPosition = 87
            fireball.blendMode = .add
            addChild(fireball)
            fireball.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 2.0, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                SKAction.removeFromParent()
            ]))

            // Layer 3: Shockwave ring
            let shockwave = SKShapeNode(circleOfRadius: expRadius * 0.2)
            shockwave.fillColor = .clear
            shockwave.strokeColor = SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.8)
            shockwave.lineWidth = 2.5
            shockwave.position = hitPos
            shockwave.zPosition = 86
            shockwave.blendMode = .add
            addChild(shockwave)
            shockwave.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: expRadius / (expRadius * 0.2), duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                SKAction.removeFromParent()
            ]))

            // Layer 4: Debris particles
            let debrisColors: [SKColor] = [
                SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1),
                SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1),
                SKColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 1),
                SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1)
            ]
            for _ in 0..<12 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let speed = CGFloat.random(in: 80...180)
                let particleSize = CGFloat.random(in: 2...5)
                let debris = SKSpriteNode(color: debrisColors[Int.random(in: 0..<debrisColors.count)], size: CGSize(width: particleSize, height: particleSize))
                debris.position = hitPos
                debris.zPosition = 89
                debris.blendMode = .add
                addChild(debris)
                debris.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.move(by: CGVector(dx: cos(angle) * speed * 0.3, dy: sin(angle) * speed * 0.3), duration: 0.3),
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.scale(to: 0.2, duration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        projectile.onHit()
    }

    private func chainLightning(from position: CGPoint, damage: CGFloat, bouncesRemaining: Int, hitEnemies: Set<ObjectIdentifier>) {
        guard bouncesRemaining > 0 else { return }
        let chainRange: CGFloat = 120

        var nearest: EnemyNode?
        var nearestDistSq: CGFloat = chainRange * chainRange
        for enemy in waveManager.activeEnemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            guard !hitEnemies.contains(ObjectIdentifier(enemy)) else { continue }
            let dx = enemy.position.x - position.x
            let dy = enemy.position.y - position.y
            let distSq = dx * dx + dy * dy
            if distSq < nearestDistSq {
                nearestDistSq = distSq
                nearest = enemy
            }
        }

        guard let target = nearest else { return }

        // Lightning bolt visual
        let bolt = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: position)
        let midX = (position.x + target.position.x) / 2 + CGFloat.random(in: -15...15)
        let midY = (position.y + target.position.y) / 2 + CGFloat.random(in: -15...15)
        path.addLine(to: CGPoint(x: midX, y: midY))
        path.addLine(to: target.position)
        bolt.path = path
        bolt.strokeColor = ColorPalette.powerUpCyan
        bolt.lineWidth = 2
        bolt.zPosition = 85
        bolt.blendMode = .add
        addChild(bolt)
        bolt.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))

        // Apply damage
        let killed = target.takeDamage(damage)
        if killed {
            gameState.score += target.pointValue
            gameState.killsThisRun += 1
            spawnCoinPickups(at: target.position, value: target.pointValue)
            handleSplitterDeath(target)
            target.die(scene: self)
            waveManager.enemyDied(target)
            effectsManager.spawnScoreNumber(at: target.position, score: target.pointValue)
        } else {
            // Show damage number so chain lightning feels impactful
            effectsManager.spawnDamageNumber(at: target.position, text: "\(Int(damage))", color: ColorPalette.powerUpCyan)
        }

        var newHitSet = hitEnemies
        newHitSet.insert(ObjectIdentifier(target))
        chainLightning(from: target.position, damage: damage * 0.7, bouncesRemaining: bouncesRemaining - 1, hitEnemies: newHitSet)
    }

    // MARK: - Coin Pickups

    private func spawnCoinPickups(at position: CGPoint, value: Int) {
        let coinCount = max(1, value / 10)
        // Cap at 5 coins per kill to avoid clutter
        let count = min(coinCount, 5)
        let valuePerCoin = max(1, coinCount / count)
        for _ in 0..<count {
            let pickup = PickupNode(value: valuePerCoin, position: position)
            addChild(pickup)
        }
    }

    private func handlePickupCollected(pickup: PickupNode?) {
        guard let pickup = pickup, pickup.parent != nil else { return }
        gameState.coinsEarnedThisRun += pickup.coinValue
        pickup.collect()
    }

    private func updatePickups(dt: TimeInterval) {
        let magnetRange = gameState.pickupMagnetRange
        enumerateChildNodes(withName: "pickup") { node, _ in
            guard let pickup = node as? PickupNode else { return }
            let dx = self.player.position.x - pickup.position.x
            let dy = self.player.position.y - pickup.position.y
            let dist = sqrt(dx * dx + dy * dy)

            if dist < magnetRange && dist > 1 {
                // Attract toward player
                let speed: CGFloat = 300 + (magnetRange - dist) * 3
                let dirX = dx / dist
                let dirY = dy / dist
                pickup.physicsBody?.velocity = CGVector(dx: dirX * speed, dy: dirY * speed)
            }

            // Auto-collect when very close
            if dist < 15 {
                self.gameState.coinsEarnedThisRun += pickup.coinValue
                pickup.collect()
            }
        }
    }

    private func handleEnemyContactPlayer(enemy: EnemyNode?) {
        guard let enemy = enemy, gameState.gamePhase == .playing else { return }
        guard !player.isInvincible else { return }

        let died = player.takeDamage(enemy.contactDamage)
        effectsManager.showDamageVignette()
        effectsManager.shakeMedium()

        // Thorns
        if gameState.thornsDamage > 0 {
            let thornKilled = enemy.takeDamage(gameState.thornsDamage)
            if thornKilled {
                gameState.score += enemy.pointValue
                gameState.killsThisRun += 1
                spawnCoinPickups(at: enemy.position, value: enemy.pointValue)
                handleSplitterDeath(enemy)
                enemy.die(scene: self)
                waveManager.enemyDied(enemy)
                effectsManager.spawnScoreNumber(at: enemy.position, score: enemy.pointValue)
            } else {
                effectsManager.spawnDamageNumber(at: enemy.position, text: "\(Int(gameState.thornsDamage))", color: ColorPalette.powerUpPurple)
            }

            // Visual thorns burst on the enemy
            let thornSpark = SKSpriteNode(color: ColorPalette.powerUpPurple, size: CGSize(width: 8, height: 8))
            thornSpark.position = enemy.position
            thornSpark.zPosition = 95
            thornSpark.blendMode = .add
            addChild(thornSpark)
            thornSpark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.scale(to: 3.0, duration: 0.2)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        if died {
            onPlayerDeath()
        }
    }

    private func handleEnemyBulletHitClone(projectile: ProjectileNode?, clone: ShadowCloneNode?) {
        guard let projectile = projectile, let clone = clone else { return }
        guard clone.parent != nil else { return }
        clone.takeDamage(projectile.damage)
        projectile.removeFromParent()
    }

    private func handleEnemyBulletHitPlayer(projectile: ProjectileNode?) {
        guard let projectile = projectile, gameState.gamePhase == .playing else { return }
        guard !player.isInvincible else {
            projectile.removeFromParent()
            return
        }

        let died = player.takeDamage(projectile.damage)
        projectile.removeFromParent()
        effectsManager.showDamageVignette()

        if died {
            onPlayerDeath()
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = self.view else { return }

        switch gameState.gamePhase {
        case .mainMenu:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                mainMenu.handleTouch(at: location)
            }

        case .playing:
            for touch in touches {
                let cameraLocation = touch.location(in: cameraManager.cameraNode)
                if hud.handleTap(at: cameraLocation) {
                    pauseGame()
                    return
                }
                inputManager.touchBegan(touch, in: view)
            }

        case .paused:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                pauseOverlay.handleTouch(at: location)
            }

        case .powerUpSelect:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                powerUpSelection.handleTouch(at: location)
            }

        case .gameOver:
            if gameOverTapDelay <= 0 {
                gameOverScreen.handleTouch()
            }

        case .statsScreen:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                statsScreen.handleTouch(at: location)
            }

        case .shopScreen:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                shopScreen.handleTouchBegan(at: location)
            }

        case .tutorial:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                tutorialScreen.handleTouchBegan(at: location)
            }

        case .superPowerUpSelect:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                superPowerUpSelection.handleTouch(at: location)
            }

        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = self.view else { return }
        switch gameState.gamePhase {
        case .playing:
            for touch in touches {
                inputManager.touchMoved(touch, in: view)
            }
        case .shopScreen:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                shopScreen.handleTouchMoved(at: location)
            }
        default:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.gamePhase {
        case .playing:
            for touch in touches {
                inputManager.touchEnded(touch)
            }
        case .shopScreen:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                shopScreen.handleTouchEnded(at: location)
            }
        case .tutorial:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                tutorialScreen.handleTouchEnded(at: location)
            }
        default:
            break
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.gamePhase {
        case .playing:
            for touch in touches {
                inputManager.touchEnded(touch)
            }
        case .shopScreen:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                shopScreen.handleTouchEnded(at: location)
            }
        case .tutorial:
            for touch in touches {
                let location = touch.location(in: cameraManager.cameraNode)
                tutorialScreen.handleTouchEnded(at: location)
            }
        default:
            break
        }
    }
}
