import SpriteKit

class SpriteFactory {
    static let shared = SpriteFactory()
    private var textureCache: [String: SKTexture] = [:]
    private let pixelScale: Int = 3 // 3x for crisp retina pixel art

    func invalidatePlayerTextures() {
        // Clear cached player/ghost textures so they regenerate with new cosmetic colors
        let keysToRemove = textureCache.keys.filter {
            $0.hasPrefix("player_") || $0.hasPrefix("ghost_") || $0.hasPrefix("shop_preview_") || $0.hasPrefix("trail_preview_")
        }
        for key in keysToRemove {
            textureCache.removeValue(forKey: key)
        }
    }

    func preloadAllTextures() {
        for dir in Direction.allCases {
            for f in 0...1 {
                _ = playerTexture(facing: dir, frame: f)
                _ = ghostPlayerTexture(facing: dir, frame: f)
            }
        }
        for type in EnemyType.allTypes {
            _ = enemyTexture(type: type, frame: 0)
            _ = enemyTexture(type: type, frame: 1)
        }
        _ = projectileTexture(isGhost: false)
        _ = projectileTexture(isGhost: true)
        _ = enemyProjectileTexture()
        _ = joystickBaseTexture()
        _ = joystickKnobTexture()
        for type in PowerUpType.allCases {
            _ = powerUpIconTexture(type: type)
        }
        // Arena tiles
        for i in 0..<6 { _ = floorTileTexture(variant: i) }
        _ = wallTileTexture()
        _ = cornerGlowTexture()
        _ = crackDecalTexture()
        _ = lightPoolTexture()
        // Obstacles
        for i in 0..<3 { _ = crateTexture(variant: i) }
        _ = pillarTexture()
        _ = barrierTexture()
        _ = terminalTexture()
        for i in 0..<2 { _ = barrelTexture(variant: i) }
    }

    // MARK: - Pixel Drawing Helper

    private func makeCanvas(size: Int, draw: (_ px: (Int, Int, SKColor) -> Void) -> Void) -> SKTexture {
        let s = pixelScale
        let imgSize = CGSize(width: size * s, height: size * s)
        let renderer = UIGraphicsImageRenderer(size: imgSize)
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            c.interpolationQuality = .none
            func px(_ x: Int, _ y: Int, _ color: SKColor) {
                guard x >= 0 && y >= 0 && x < size && y < size else { return }
                c.setFillColor(color.cgColor)
                c.fill(CGRect(x: x * s, y: y * s, width: s, height: s))
            }
            draw(px)
        }
        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest
        return tex
    }

    private func makeCanvasRect(w: Int, h: Int, draw: (_ px: (Int, Int, SKColor) -> Void) -> Void) -> SKTexture {
        let s = pixelScale
        let imgSize = CGSize(width: w * s, height: h * s)
        let renderer = UIGraphicsImageRenderer(size: imgSize)
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            c.interpolationQuality = .none
            func px(_ x: Int, _ y: Int, _ color: SKColor) {
                guard x >= 0 && y >= 0 && x < w && y < h else { return }
                c.setFillColor(color.cgColor)
                c.fill(CGRect(x: x * s, y: y * s, width: s, height: s))
            }
            draw(px)
        }
        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest
        return tex
    }

    // MARK: - Direction

    enum Direction: CaseIterable {
        case up, down, left, right
    }

    // MARK: - Color Helpers

    private func darker(_ c: SKColor, by amount: CGFloat = 0.3) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: max(0, r - amount), green: max(0, g - amount), blue: max(0, b - amount), alpha: a)
    }

    private func lighter(_ c: SKColor, by amount: CGFloat = 0.25) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: min(1, r + amount), green: min(1, g + amount), blue: min(1, b + amount), alpha: a)
    }

    // MARK: - Player Textures

    func playerTexture(facing: Direction, frame: Int) -> SKTexture {
        let key = "player_\(facing)_\(frame)"
        return cachedTexture(key: key) {
            // Build facing-down, then mirror/rotate for other directions
            let baseTex = self.drawPlayer(frame: frame, facing: facing)
            return baseTex
        }
    }

    // Shop preview: render player with specific skin and hat (not the equipped ones)
    func shopPreviewTexture(skinId: String, hatId: String) -> SKTexture {
        let key = "shop_preview_\(skinId)_\(hatId)"
        return cachedTexture(key: key) {
            let skinItem = CosmeticCatalog.item(byId: skinId)
            let primary = skinItem?.primaryColor ?? ColorPalette.playerPrimary
            let secondary = skinItem?.secondaryColor ?? ColorPalette.playerSecondary
            return self.drawPlayerCore(frame: 0, facing: .down, primary: primary, secondary: secondary, hatId: hatId, skinId: skinId)
        }
    }

    // Trail preview: horizontal fading particles
    func trailPreviewTexture(trailColor: SKColor) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        trailColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "trail_preview_\(Int(r*255))_\(Int(g*255))_\(Int(b*255))"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 32) { px in
                // Player dot on the right
                let playerC = ColorPalette.playerPrimary
                for y in 12...19 {
                    for x in 22...27 { px(x, y, playerC) }
                }
                // Trail particles fading to the left
                let positions: [(Int, Int, CGFloat)] = [
                    (18, 15, 0.8), (17, 14, 0.7), (16, 16, 0.65),
                    (14, 15, 0.55), (13, 14, 0.45), (12, 16, 0.4),
                    (10, 15, 0.3), (9, 14, 0.25), (8, 16, 0.2),
                    (6, 15, 0.15), (5, 14, 0.1), (4, 16, 0.08),
                ]
                for (tx, ty, alpha) in positions {
                    let c = SKColor(red: r, green: g, blue: b, alpha: alpha)
                    px(tx, ty, c)
                    px(tx, ty + 1, c)
                    px(tx + 1, ty, c)
                    px(tx + 1, ty + 1, c)
                }
            }
        }
    }

    private func drawPlayer(frame: Int, facing: Direction) -> SKTexture {
        let skinId = PersistenceManager.shared.profile.equippedSkin
        let skinItem = CosmeticCatalog.item(byId: skinId)
        let primary = skinItem?.primaryColor ?? ColorPalette.playerPrimary
        let secondary = skinItem?.secondaryColor ?? ColorPalette.playerSecondary
        let hatId = PersistenceManager.shared.profile.equippedHat
        return drawPlayerCore(frame: frame, facing: facing, primary: primary, secondary: secondary, hatId: hatId, skinId: skinId)
    }

    private func drawPlayerCore(frame: Int, facing: Direction, primary: SKColor, secondary: SKColor, hatId: String, skinId: String = "default") -> SKTexture {
        let size = 32

        return makeCanvas(size: size) { px in
            let cyan = primary
            let blue = secondary
            let dark = self.darker(secondary, by: 0.2)
            let visor = self.lighter(primary, by: 0.3)
            let white = SKColor.white
            let highlight = self.lighter(primary, by: 0.45)
            let boot = self.darker(secondary, by: 0.15)
            let armor = self.lighter(secondary, by: 0.15)
            let buckle = SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1)

            // -- Helmet --
            for x in 13...18 { px(x, 3, dark) }
            px(15, 2, cyan); px(16, 2, cyan)
            for y in 4...10 {
                let hw = y < 6 ? (y - 3) : 5
                for x in (16 - hw)...(15 + hw) { px(x, y, blue) }
            }
            for y in 4...10 {
                px(16 - (y < 6 ? (y-3) : 5) - 1, y, dark)
                px(15 + (y < 6 ? (y-3) : 5) + 1, y, dark)
            }
            for x in 11...20 { px(x, 10, dark) }
            px(13, 5, highlight); px(14, 5, highlight); px(13, 6, highlight)

            // -- Visor --
            if facing == .up {
                for x in 14...17 { px(x, 7, armor) }
                px(15, 6, cyan); px(16, 6, cyan)
            } else {
                for x in 12...19 { px(x, 7, dark) }
                px(13, 7, visor); px(14, 7, visor)
                px(17, 7, visor); px(18, 7, visor)
                px(13, 8, SKColor(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.4))
                px(18, 8, SKColor(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.4))
                if facing == .left {
                    px(17, 7, dark); px(18, 7, dark); px(18, 8, dark)
                } else if facing == .right {
                    px(13, 7, dark); px(14, 7, dark); px(13, 8, dark)
                }
            }

            // -- Torso --
            for y in 11...18 {
                let hw = y < 14 ? 5 : (y < 17 ? 4 : 3)
                for x in (16 - hw)...(15 + hw) { px(x, y, armor) }
            }
            for y in 11...14 { for x in 13...18 { px(x, y, cyan) } }
            px(15, 12, white); px(16, 12, white)
            px(14, 13, visor); px(15, 13, visor); px(16, 13, visor); px(17, 13, visor)
            px(15, 14, white); px(16, 14, white)
            for y in 11...18 {
                let hw = y < 14 ? 5 : (y < 17 ? 4 : 3)
                px(16 - hw - 1, y, dark); px(15 + hw + 1, y, dark)
            }
            for x in 12...19 { px(x, 17, dark) }
            px(15, 17, buckle); px(16, 17, buckle)

            // -- Shoulder pads --
            for y in 11...13 {
                px(9, y, blue); px(10, y, blue)
                px(21, y, blue); px(22, y, blue)
            }
            px(9, 11, highlight); px(22, 11, highlight)
            px(8, 12, dark); px(23, 12, dark)
            px(9, 14, dark); px(10, 14, dark)
            px(21, 14, dark); px(22, 14, dark)

            // -- Arms (contralateral swing with legs) --
            let leftArmEnd = frame == 0 ? 16 : 18
            let rightArmEnd = frame == 0 ? 18 : 16
            for y in 14...leftArmEnd { px(9, y, armor); px(10, y, armor) }
            px(9, leftArmEnd + 1, cyan); px(10, leftArmEnd + 1, cyan)
            for y in 14...rightArmEnd { px(21, y, armor); px(22, y, armor) }
            px(21, rightArmEnd + 1, cyan); px(22, rightArmEnd + 1, cyan)

            // -- Legs (vertical stride — one extended lower, one shorter) --
            if frame == 0 {
                // Left leg forward (extended lower)
                for y in 19...25 { px(12, y, blue); px(13, y, blue); px(14, y, armor) }
                for x in 11...14 { px(x, 26, boot) }
                px(11, 25, boot); px(14, 25, boot)
                // Right leg back (shorter)
                for y in 19...22 { px(17, y, armor); px(18, y, blue); px(19, y, blue) }
                for x in 17...20 { px(x, 23, boot) }
                px(17, 22, boot); px(20, 22, boot)
            } else {
                // Right leg forward (extended lower)
                for y in 19...25 { px(17, y, armor); px(18, y, blue); px(19, y, blue) }
                for x in 17...20 { px(x, 26, boot) }
                px(17, 25, boot); px(20, 25, boot)
                // Left leg back (shorter)
                for y in 19...22 { px(12, y, blue); px(13, y, blue); px(14, y, armor) }
                for x in 11...14 { px(x, 23, boot) }
                px(11, 22, boot); px(14, 22, boot)
            }

            // -- Skin overlays --
            switch skinId {
            case "skin_skeleton":
                let bone = SKColor(red: 0.92, green: 0.9, blue: 0.82, alpha: 1)
                let boneDark = SKColor(red: 0.6, green: 0.58, blue: 0.5, alpha: 1)
                let eyeSocket = SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
                if facing != .up {
                    px(12, 6, eyeSocket); px(13, 6, eyeSocket); px(14, 6, eyeSocket)
                    px(17, 6, eyeSocket); px(18, 6, eyeSocket); px(19, 6, eyeSocket)
                    px(12, 7, eyeSocket); px(13, 7, bone); px(14, 7, eyeSocket)
                    px(17, 7, eyeSocket); px(18, 7, bone); px(19, 7, eyeSocket)
                    px(12, 8, eyeSocket); px(13, 8, eyeSocket); px(14, 8, eyeSocket)
                    px(17, 8, eyeSocket); px(18, 8, eyeSocket); px(19, 8, eyeSocket)
                    px(15, 9, eyeSocket); px(16, 9, eyeSocket)
                    for x in 13...18 { px(x, 10, boneDark) }
                    px(13, 10, bone); px(15, 10, bone); px(17, 10, bone)
                }
                for y in 12...16 {
                    if y % 2 == 0 {
                        px(13, y, bone); px(14, y, boneDark); px(15, y, boneDark)
                        px(16, y, boneDark); px(17, y, boneDark); px(18, y, bone)
                    }
                }
                for y in 12...16 { px(15, y, bone); px(16, y, bone) }

            case "skin_cyber":
                let neon = primary
                let neonDim = neon.withAlphaComponent(0.6)
                for y in 4...10 {
                    let hw = y < 6 ? (y - 3) : 5
                    px(16 - hw - 1, y, neon); px(15 + hw + 1, y, neon)
                }
                for x in 11...20 { px(x, 10, neon) }
                for y in 11...18 {
                    let hw = y < 14 ? 5 : (y < 17 ? 4 : 3)
                    px(16 - hw - 1, y, neonDim); px(15 + hw + 1, y, neonDim)
                }
                px(14, 12, neon); px(15, 12, neon); px(16, 12, neon); px(17, 12, neon)
                px(14, 13, neon); px(17, 13, neon)
                px(14, 14, neon); px(15, 14, neon); px(16, 14, neon); px(17, 14, neon)
                if facing != .up { for x in 12...19 { px(x, 7, neon) } }
                px(12, 21, neonDim); px(13, 21, neonDim)
                px(18, 21, neonDim); px(19, 21, neonDim)

            case "skin_magma":
                let lava = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1)
                let lavaHot = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
                let lavaDim = SKColor(red: 0.8, green: 0.25, blue: 0.0, alpha: 1)
                px(13, 5, lava); px(14, 6, lavaHot); px(15, 7, lava)
                px(18, 5, lavaDim); px(17, 6, lava)
                px(13, 12, lava); px(14, 13, lavaHot); px(15, 14, lava); px(16, 15, lavaDim)
                px(18, 12, lavaDim); px(17, 13, lava); px(16, 14, lavaHot)
                px(15, 13, lavaHot); px(16, 13, lavaHot)
                px(9, 15, lava); px(10, 16, lavaDim)
                px(22, 15, lava); px(21, 16, lavaDim)
                px(13, 21, lava); px(12, 22, lavaDim)
                px(18, 21, lava); px(19, 22, lavaDim)

            case "skin_ghost":
                let ghostGlow = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.5)
                let ghostWisp = SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.35)
                px(9, 15, ghostWisp); px(8, 16, ghostWisp); px(7, 17, ghostWisp)
                px(22, 15, ghostWisp); px(23, 16, ghostWisp); px(24, 17, ghostWisp)
                if facing != .up {
                    px(13, 7, ghostGlow); px(14, 7, ghostGlow)
                    px(17, 7, ghostGlow); px(18, 7, ghostGlow)
                }
                let mist = SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.2)
                for x in 10...21 { px(x, 26, mist) }
                for x in 12...19 { px(x, 27, mist) }

            default:
                break
            }

            // -- Hat overlay --
            switch hatId {
            case "hat_crown":
                let gold = ColorPalette.gold
                let goldDark = SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1)
                for x in 12...19 { px(x, 2, gold) }
                for x in 12...19 { px(x, 3, goldDark) }
                px(12, 0, gold); px(12, 1, gold)
                px(15, 0, gold); px(15, 1, gold); px(16, 0, gold); px(16, 1, gold)
                px(19, 0, gold); px(19, 1, gold)
                px(14, 2, SKColor.red); px(17, 2, SKColor.blue)
            case "hat_halo":
                let haloColor = SKColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 0.8)
                let haloBright = SKColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.9)
                for x in 11...20 { px(x, 0, haloColor) }
                for x in 12...19 { px(x, 1, haloBright) }
                px(11, 1, haloColor); px(20, 1, haloColor)
            case "hat_horns":
                let hornColor = SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1)
                let hornDark = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1)
                px(11, 3, hornColor); px(10, 2, hornColor); px(9, 1, hornDark); px(9, 0, hornDark)
                px(20, 3, hornColor); px(21, 2, hornColor); px(22, 1, hornDark); px(22, 0, hornDark)
            case "hat_wizard":
                let wizPurple = SKColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1)
                let wizDark = SKColor(red: 0.25, green: 0.1, blue: 0.55, alpha: 1)
                let wizStar = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1)
                for x in 12...19 { px(x, 3, wizPurple) }
                for x in 13...18 { px(x, 2, wizPurple) }
                for x in 14...17 { px(x, 1, wizDark) }
                px(15, 0, wizDark); px(16, 0, wizDark)
                for x in 10...21 { px(x, 4, wizPurple) }
                for x in 10...21 { px(x, 3, wizDark) }
                px(17, 2, wizStar)
            case "hat_headband":
                let bandColor = SKColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 1)
                let bandDark = SKColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1)
                for x in 11...20 { px(x, 4, bandColor) }
                for x in 11...20 { px(x, 5, bandDark) }
                px(21, 4, bandColor); px(22, 5, bandColor); px(23, 6, bandColor)
                px(24, 7, bandDark); px(25, 8, bandDark)
            case "hat_tophat":
                let hatBlack = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
                let hatDark = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
                let hatBand = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1)
                for x in 9...22 { px(x, 3, hatBlack); px(x, 4, hatDark) }
                for y in 0...2 { for x in 12...19 { px(x, y, hatBlack) } }
                for x in 12...19 { px(x, 2, hatBand) }
                for x in 13...18 { px(x, 0, self.lighter(hatBlack, by: 0.1)) }
            case "hat_antenna":
                let stalk = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
                let bulb = SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1)
                let bulbGlow = SKColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 0.5)
                px(15, 2, stalk); px(16, 2, stalk)
                px(15, 1, stalk); px(16, 1, stalk)
                px(15, 0, stalk); px(16, 0, stalk)
                px(14, 0, bulbGlow); px(17, 0, bulbGlow)
                px(15, 0, bulb); px(16, 0, bulb)
            default:
                break
            }
        }
    }

    // MARK: - Ghost Textures

    func ghostPlayerTexture(facing: Direction, frame: Int) -> SKTexture {
        let key = "ghost_\(facing)_\(frame)"
        return cachedTexture(key: key) {
            let size = 32
            return self.makeCanvas(size: size) { px in
                let ghostBody = SKColor(red: 0.35, green: 0.85, blue: 1.0, alpha: 0.45)
                let ghostLight = SKColor(red: 0.6, green: 1.0, blue: 1.0, alpha: 0.65)
                let eyeGlow = SKColor(red: 0.8, green: 1.0, blue: 1.0, alpha: 0.8)

                // Head - ghostly helmet shape
                for y in 4...10 {
                    let hw = y < 6 ? (y - 3) : 5
                    for x in (16 - hw)...(15 + hw) {
                        let distFromCenter = abs(x - 15) + abs(y - 7)
                        px(x, y, distFromCenter < 4 ? ghostLight : ghostBody)
                    }
                }
                // Eyes - bright glowing
                px(13, 7, eyeGlow); px(14, 7, eyeGlow)
                px(17, 7, eyeGlow); px(18, 7, eyeGlow)

                // Body - fading torso
                for y in 11...18 {
                    let hw = max(2, 5 - (y - 11) / 2)
                    let alpha = 0.45 - Double(y - 11) * 0.03
                    let c = SKColor(red: 0.35, green: 0.85, blue: 1.0, alpha: alpha)
                    for x in (16 - hw)...(15 + hw) { px(x, y, c) }
                }

                // Core glow
                for y in 12...15 {
                    for x in 14...17 { px(x, y, ghostLight) }
                }

                // Wispy trails instead of legs
                let offset = frame == 1 ? 1 : 0
                for y in 19...26 {
                    let fadeA = max(0.05, 0.3 - Double(y - 19) * 0.035)
                    let fadeC = SKColor(red: 0.35, green: 0.85, blue: 1.0, alpha: fadeA)
                    // Wispy tendrils
                    let wave = (y + offset) % 3 == 0 ? 1 : 0
                    px(13 - wave, y, fadeC)
                    px(14, y, fadeC)
                    px(17, y, fadeC)
                    px(18 + wave, y, fadeC)
                    if y < 22 {
                        px(15, y, SKColor(red: 0.5, green: 0.95, blue: 1.0, alpha: fadeA * 0.8))
                        px(16, y, SKColor(red: 0.5, green: 0.95, blue: 1.0, alpha: fadeA * 0.8))
                    }
                }
            }
        }
    }

    // MARK: - Enemy Textures

    func enemyTexture(type: EnemyType, frame: Int) -> SKTexture {
        let key = "enemy_\(type.name)_\(frame)"
        return cachedTexture(key: key) {
            switch type.name {
            case "Shambler": return self.drawShambler(frame: frame)
            case "Dasher": return self.drawDasher(frame: frame)
            case "Strafer": return self.drawStrafer(frame: frame)
            case "Bomber": return self.drawBomber(frame: frame)
            case "Necromancer": return self.drawNecromancer(frame: frame)
            case "Juggernaut": return self.drawJuggernaut(frame: frame)
            case "Wraith": return self.drawWraith(frame: frame)
            case "Splitter": return self.drawSplitter(frame: frame)
            case "ShieldBearer": return self.drawShieldBearer(frame: frame)
            default: return self.drawShambler(frame: frame)
            }
        }
    }

    // MARK: - Shambler (red zombie - 32x32)
    private func drawShambler(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let body = ColorPalette.enemyMelee
            let dark = self.darker(body)
            let flesh = SKColor(red: 0.85, green: 0.35, blue: 0.25, alpha: 1)
            let eyes = ColorPalette.enemyEyes
            let outline = ColorPalette.enemyOutline
            let teeth = SKColor.white
            let bone = SKColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1)

            // Lurching torso lean between frames
            let leanX = frame == 0 ? 0 : 1

            // Head (rounded) — shifts with lean
            for y in 4...11 {
                let hw = y < 6 ? (y - 3) : (y > 9 ? (11 - y + 1) : 4)
                for x in (15 - hw + leanX)...(16 + hw + leanX) {
                    px(x, y, body)
                }
                px(15 - hw - 1 + leanX, y, outline)
                px(16 + hw + 1 + leanX, y, outline)
            }
            for x in (12 + leanX)...(19 + leanX) { px(x, 3, outline) }
            for x in (12 + leanX)...(19 + leanX) { px(x, 12, outline) }

            // Sunken eyes
            px(12 + leanX, 6, outline); px(13 + leanX, 6, outline); px(14 + leanX, 6, outline)
            px(17 + leanX, 6, outline); px(18 + leanX, 6, outline); px(19 + leanX, 6, outline)
            px(12 + leanX, 7, outline); px(13 + leanX, 7, eyes); px(14 + leanX, 7, eyes)
            px(17 + leanX, 7, eyes); px(18 + leanX, 7, eyes); px(19 + leanX, 7, outline)
            px(12 + leanX, 8, outline); px(13 + leanX, 8, eyes); px(14 + leanX, 8, outline)
            px(17 + leanX, 8, outline); px(18 + leanX, 8, eyes); px(19 + leanX, 8, outline)

            // Mouth with teeth
            for x in (13 + leanX)...(18 + leanX) { px(x, 10, outline) }
            px(13 + leanX, 10, teeth); px(15 + leanX, 10, teeth); px(17 + leanX, 10, teeth)
            px(14 + leanX, 11, dark); px(15 + leanX, 11, dark); px(16 + leanX, 11, dark)

            // Body - hunched
            for y in 12...21 {
                let hw = y < 15 ? 5 : (y < 19 ? 6 : (6 - (y - 19)))
                for x in max(0, 15 - hw)...min(31, 16 + hw) {
                    px(x, y, flesh)
                }
            }
            // Exposed ribs
            for i in 0..<3 {
                px(11, 14 + i * 2, bone); px(12, 14 + i * 2, bone)
            }
            // Belly wound
            for y in 15...17 {
                for x in 14...17 { px(x, y, dark) }
            }
            px(15, 16, SKColor(red: 0.5, green: 0.1, blue: 0.0, alpha: 1))

            // Arms — contralateral swing with reach/claw motion
            let leftArmEnd = frame == 0 ? 10 : 15     // Left arm reaches up in frame 0
            let rightArmEnd = frame == 0 ? 15 : 10    // Right arm reaches up in frame 1
            // Left arm
            for y in leftArmEnd...(leftArmEnd + 5) {
                px(6, y, flesh); px(7, y, flesh); px(8, y, flesh)
            }
            // Left clawed hand
            px(4, leftArmEnd - 1, dark); px(5, leftArmEnd - 1, dark); px(6, leftArmEnd, dark)
            px(3, leftArmEnd, dark)
            // Right arm
            for y in rightArmEnd...(rightArmEnd + 5) {
                px(23, y, flesh); px(24, y, flesh); px(25, y, flesh)
            }
            // Right clawed hand
            px(26, rightArmEnd - 1, dark); px(27, rightArmEnd - 1, dark); px(25, rightArmEnd, dark)
            px(28, rightArmEnd, dark)

            // Legs — vertical stride (one extended, one shorter)
            if frame == 0 {
                // Left leg forward (extended lower)
                for y in 22...27 { px(11, y, dark); px(12, y, flesh); px(13, y, flesh) }
                px(10, 28, outline); px(11, 28, dark); px(12, 28, dark); px(13, 28, dark)
                // Right leg back (shorter)
                for y in 22...24 { px(18, y, flesh); px(19, y, flesh); px(20, y, dark) }
                px(18, 25, dark); px(19, 25, dark); px(20, 25, dark)
            } else {
                // Right leg forward (extended lower)
                for y in 22...27 { px(18, y, flesh); px(19, y, flesh); px(20, y, dark) }
                px(18, 28, dark); px(19, 28, dark); px(20, 28, dark); px(21, 28, outline)
                // Left leg back (shorter)
                for y in 22...24 { px(11, y, dark); px(12, y, flesh); px(13, y, flesh) }
                px(11, 25, dark); px(12, 25, dark); px(13, 25, dark)
            }
        }
    }

    // MARK: - Dasher (yellow imp - 32x32)
    private func drawDasher(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let body = ColorPalette.enemyFast
            let dark = self.darker(body, by: 0.2)
            let wing = SKColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1)
            let wingDark = SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1)
            let wingHighlight = SKColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1)
            let eyes = SKColor.red
            let outline = SKColor(red: 0.4, green: 0.3, blue: 0.0, alpha: 1)

            // Body bob: dips when wings up, rises when wings down
            let bodyY = frame == 0 ? 2 : -1  // wings up = body dips down

            // Compact body
            for y in (11 + bodyY)...(19 + bodyY) {
                let localY = y - bodyY
                let hw = localY < 14 ? (localY - 10) : (localY > 17 ? (19 - localY) : 4)
                for x in (15 - hw)...(16 + hw) { px(x, y, body) }
            }
            // Head (triangular, pointed)
            for y in (7 + bodyY)...(11 + bodyY) {
                let localY = y - bodyY
                let hw = localY - 7
                for x in (15 - hw)...(16 + hw) { px(x, y, body) }
            }
            // Horns
            px(13, 5 + bodyY, dark); px(12, 4 + bodyY, dark); px(11, 3 + bodyY, outline)
            px(18, 5 + bodyY, dark); px(19, 4 + bodyY, dark); px(20, 3 + bodyY, outline)

            // Angry eyes
            px(13, 10 + bodyY, eyes); px(14, 10 + bodyY, eyes)
            px(17, 10 + bodyY, eyes); px(18, 10 + bodyY, eyes)
            px(13, 11 + bodyY, SKColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1))
            px(18, 11 + bodyY, SKColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1))
            // Fangs
            px(14, 13 + bodyY, SKColor.white); px(17, 13 + bodyY, SKColor.white)

            // Wings (wider 6px range flap, was 4px)
            let wingUp = frame == 0
            let wingBaseY = wingUp ? 6 : 14  // 8px range (was 4)
            let wingSpan = 9  // wider wings (was 7)
            // Left wing
            for y in wingBaseY...(wingBaseY + 8) {
                let span = max(0, wingSpan - abs(y - (wingBaseY + 4)))
                for x in max(0, 10 - span)...10 {
                    px(x, y, wing)
                }
                // Wing highlight on leading edge
                if wingUp && y == wingBaseY + 1 {
                    for x in max(0, 10 - span + 1)...10 { px(x, y, wingHighlight) }
                }
                if 10 - span - 1 >= 0 { px(10 - span - 1, y, wingDark) }
            }
            // Right wing
            for y in wingBaseY...(wingBaseY + 8) {
                let span = max(0, wingSpan - abs(y - (wingBaseY + 4)))
                for x in 21...min(31, 21 + span) {
                    px(x, y, wing)
                }
                if wingUp && y == wingBaseY + 1 {
                    for x in 21...min(31, 21 + span - 1) { px(x, y, wingHighlight) }
                }
                if 21 + span + 1 < 32 { px(21 + span + 1, y, wingDark) }
            }
            // Wing membrane lines
            for i in 0..<5 {
                let y = wingBaseY + 1 + i * 2
                if y < 32 {
                    px(max(0, 10 - i), y, outline)
                    px(min(31, 21 + i), y, outline)
                }
            }

            // Tail (wider wiggle)
            for y in (20 + bodyY)...(25 + bodyY) {
                let localY = y - bodyY
                let shift = (localY - 20) % 2 == 0 ? 0 : (frame == 0 ? 2 : -2)
                if y >= 0 && y < 32 {
                    px(15 + shift, y, dark); px(16 + shift, y, dark)
                }
            }
            if 26 + bodyY < 32 { px(frame == 0 ? 17 : 13, 26 + bodyY, outline) }
         }
    }

    // MARK: - Strafer (orange hooded mage - 32x32)
    private func drawStrafer(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let robe = ColorPalette.enemyRanged
            let dark = self.darker(robe)
            let hood = SKColor(red: 0.55, green: 0.28, blue: 0.0, alpha: 1)
            let eyes = ColorPalette.enemyEyes
            let staff = SKColor(red: 0.55, green: 0.55, blue: 0.65, alpha: 1)
            let orb = ColorPalette.bulletEnemy
            let orbGlow = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1)
            let magic = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.6)

            // Hood (deep, shadowed)
            for y in 3...10 {
                let hw = min(y - 1, 6)
                for x in (15 - hw)...(16 + hw) {
                    px(x, y, y < 6 ? hood : dark)
                }
            }
            // Face visible under hood
            for y in 7...10 {
                for x in 12...19 { px(x, y, robe) }
            }
            // Glowing eyes
            px(13, 8, eyes); px(14, 8, eyes)
            px(17, 8, eyes); px(18, 8, eyes)
            // Eye glow effect
            px(12, 8, SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.3))
            px(19, 8, SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.3))

            // Robe body (flowing)
            for y in 11...26 {
                let hw = min(5 + (y - 11) / 2, 10)
                for x in max(0, 15 - hw)...min(31, 16 + hw) {
                    px(x, y, robe)
                }
            }
            // Robe fold lines
            for y in 14...24 {
                px(13, y, dark); px(18, y, dark)
            }
            // Robe hem — sway between frames
            let hemShift = frame == 0 ? -1 : 1
            for x in (6 + hemShift)...(25 + hemShift) {
                if x >= 0 && x < 32 {
                    px(x, 26, dark)
                    if x % 3 == 0 && x >= 0 && x < 32 { px(x, 27, dark) }
                }
            }
            // Extra tattered hem pieces for sway effect
            if frame == 0 {
                px(5, 27, dark); px(6, 28, dark)
            } else {
                px(26, 27, dark); px(25, 28, dark)
            }

            // Staff in right hand — 2px motion (was 1px)
            let staffShift = frame == 1 ? -2 : 0
            for y in (4 + staffShift)...(24 + staffShift) {
                px(24, y, staff)
            }
            // Staff orb
            for y in (2 + staffShift)...(5 + staffShift) {
                for x in 23...26 {
                    let dx = x - 24, dy = y - (3 + staffShift)
                    if dx * dx + dy * dy <= 4 { px(x, y, orb) }
                }
            }
            px(24, 3 + staffShift, orbGlow) // Center glow
            // Orb sparkle
            px(23, 2 + staffShift, SKColor.white)
            // Orb trail when staff raised
            if frame == 1 {
                px(24, 6, magic); px(25, 5, magic)
            }

            // Left arm — casting gesture (raises/lowers 4px between frames)
            let castArmEnd = frame == 0 ? 17 : 13
            for y in castArmEnd...(castArmEnd + 4) {
                px(7, y, robe); px(8, y, robe)
            }
            // Casting hand with magic
            px(6, castArmEnd, robe); px(5, castArmEnd, dark)
            if frame == 1 {
                // Magic particles from raised hand
                px(5, castArmEnd - 1, magic); px(6, castArmEnd - 1, magic)
                px(4, castArmEnd - 2, orbGlow)
                px(7, castArmEnd - 2, orbGlow)
            }
        }
    }

    // MARK: - Bomber (dark red walking bomb - 32x32)
    private func drawBomber(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let body = ColorPalette.enemyTank
            let hot = SKColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 1)
            let glow = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            let core = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
            let dark = self.darker(body)
            let shell = SKColor(red: 0.35, green: 0.05, blue: 0.05, alpha: 1)
            let eyes = ColorPalette.enemyEyes
            let sparkWhite = SKColor.white

            let pulse = frame == 1 ? 1 : 0
            // Waddle: body shifts 1px horizontally between frames
            let waddle = frame == 0 ? -1 : 1

            // Spherical bomb body
            let cx = 15 + waddle, cy = 14
            let r = 9 + pulse
            for y in (cy - r)...(cy + r) {
                for x in (cx - r)...(cx + r) {
                    let dx = x - cx, dy = y - cy
                    let distSq = dx * dx + dy * dy
                    if distSq <= r * r && x >= 0 && x < 32 && y >= 0 && y < 32 {
                        if distSq > (r - 2) * (r - 2) {
                            px(x, y, dark)
                        } else if distSq > (r - 4) * (r - 4) {
                            px(x, y, body)
                        } else {
                            px(x, y, shell)
                        }
                    }
                }
            }

            // Glowing cracks — more dramatic in frame 1
            let crackColor = frame == 1 ? glow : hot
            let crackLen = frame == 1 ? 7 : 6
            for i in 0..<4 {
                let angle = CGFloat(i) * .pi / 2 + 0.3
                for j in 3...crackLen {
                    let x = cx + Int(cos(angle) * CGFloat(j))
                    let y = cy + Int(sin(angle) * CGFloat(j))
                    if x >= 0 && x < 32 && y >= 0 && y < 32 { px(x, y, crackColor) }
                }
            }

            // Hot inner core
            let ir = 3 + pulse
            for y in (cy - ir)...(cy + ir) {
                for x in (cx - ir)...(cx + ir) {
                    let dx = x - cx, dy = y - cy
                    if dx * dx + dy * dy <= ir * ir && x >= 0 && x < 32 { px(x, y, hot) }
                }
            }
            // Bright center
            px(cx, cy, core); px(min(31, cx + 1), cy, core)
            px(cx, cy + 1, core); px(min(31, cx + 1), cy + 1, core)

            // Eyes (angry, on top) — shift with waddle
            px(12 + waddle, 11, eyes); px(13 + waddle, 11, eyes)
            px(18 + waddle, 11, eyes); px(19 + waddle, 11, eyes)
            // Angry eyebrows
            px(11 + waddle, 10, dark); px(12 + waddle, 10, dark)
            px(19 + waddle, 10, dark); px(20 + waddle, 10, dark)

            // Fuse on top
            let fuseX = cx
            px(fuseX, cy - r - 1, shell); px(min(31, fuseX + 1), cy - r - 1, shell)
            px(fuseX, cy - r - 2, glow); px(min(31, fuseX + 1), cy - r - 2, glow)
            // Dramatic sparks — both frames, more in frame 1
            if cy - r - 3 >= 0 {
                px(fuseX - 1, cy - r - 3, core); px(fuseX + 2, cy - r - 3, core)
                px(fuseX, cy - r - 3, glow)
            }
            if frame == 1 && cy - r - 4 >= 0 {
                px(fuseX, cy - r - 4, sparkWhite)
                px(fuseX - 2, cy - r - 4, glow); px(fuseX + 3, cy - r - 4, glow)
                if cy - r - 5 >= 0 { px(fuseX + 1, cy - r - 5, sparkWhite) }
            }

            // Tiny feet — vertical stride
            if frame == 0 {
                // Left foot forward (lower)
                px(11 + waddle, cy + r + 1, body); px(12 + waddle, cy + r + 1, body)
                px(11 + waddle, cy + r + 2, dark); px(12 + waddle, cy + r + 2, dark)
                // Right foot back (higher)
                px(19 + waddle, cy + r + 1, body); px(20 + waddle, cy + r + 1, body)
            } else {
                // Right foot forward (lower)
                px(19 + waddle, cy + r + 1, body); px(20 + waddle, cy + r + 1, body)
                px(19 + waddle, cy + r + 2, dark); px(20 + waddle, cy + r + 2, dark)
                // Left foot back (higher)
                px(11 + waddle, cy + r + 1, body); px(12 + waddle, cy + r + 1, body)
            }
        }
    }

    // MARK: - Necromancer (purple summoner - 40x40)
    private func drawNecromancer(frame: Int) -> SKTexture {
        return makeCanvas(size: 40) { px in
            let robe = SKColor(red: 0.4, green: 0.0, blue: 0.6, alpha: 1)
            let robeDark = SKColor(red: 0.22, green: 0.0, blue: 0.35, alpha: 1)
            let skull = SKColor.white
            let skullDark = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            let eyes = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
            let eyeGlow = SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.4)
            let magic = ColorPalette.enemyBoss
            let crown = SKColor(red: 0.7, green: 0.0, blue: 0.9, alpha: 1)
            let magicBright = SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.6)

            // Crown/horns
            px(17, 1, crown); px(22, 1, crown)
            px(17, 2, crown); px(18, 2, crown)
            px(21, 2, crown); px(22, 2, crown)

            // Deep hood
            for y in 3...12 {
                let hw = min(y, 8)
                for x in (20 - hw)...(19 + hw) {
                    px(x, y, y < 7 ? robeDark : robe)
                }
            }

            // Skull face
            for y in 6...11 {
                let hw = y < 8 ? (y - 5) : (y > 9 ? max(1, 11 - y) : 4)
                for x in (20 - hw)...(19 + hw) { px(x, y, skull) }
            }
            // Eye sockets (deep, glowing)
            for y in 7...9 {
                px(17, y, SKColor.black); px(18, y, SKColor.black)
                px(21, y, SKColor.black); px(22, y, SKColor.black)
            }
            px(17, 8, eyes); px(18, 8, eyes)
            px(21, 8, eyes); px(22, 8, eyes)
            // Eye glow
            px(16, 8, eyeGlow); px(23, 8, eyeGlow)
            // Nose hole
            px(19, 10, SKColor.black); px(20, 10, SKColor.black)
            // Jaw/teeth
            for x in 17...22 { px(x, 11, skullDark) }
            px(17, 11, skull); px(19, 11, skull); px(21, 11, skull)

            // Flowing robe
            for y in 13...34 {
                let spread = min(y - 10, 13)
                for x in max(0, 20 - spread)...min(39, 19 + spread) {
                    let distFromCenter = abs(x - 19)
                    px(x, y, distFromCenter > spread - 2 ? robeDark : robe)
                }
            }
            // Robe trim with magic symbols
            for x in 7...32 {
                px(x, 34, magic)
                if x % 4 == 0 { px(x, 33, magic); px(x, 35, magic) }
            }
            // Robe hem flow — shifts between frames
            let hemShift = frame == 0 ? -1 : 1
            for x in max(0, 6 + hemShift)...min(39, 33 + hemShift) {
                if x % 3 == 0 { px(x, 36, robeDark) }
            }
            if frame == 0 {
                px(6, 35, robeDark); px(5, 36, robeDark)
            } else {
                px(33, 35, robeDark); px(34, 36, robeDark)
            }
            // Center robe detail
            for y in 16...30 { px(19, y, robeDark); px(20, y, robeDark) }

            // Arms — contralateral (left up when right down, 5px range)
            let leftArmUp = frame == 0 ? 5 : 0
            let rightArmUp = frame == 0 ? 0 : 5
            for y in (10 - leftArmUp)...(20 - leftArmUp) {
                px(5, y, robe); px(6, y, robe); px(7, y, robe)
            }
            for y in (10 - rightArmUp)...(20 - rightArmUp) {
                px(32, y, robe); px(33, y, robe); px(34, y, robe)
            }
            // Skeletal hands with magic
            px(4, 9 - leftArmUp, skull); px(5, 9 - leftArmUp, skull)
            px(34, 9 - rightArmUp, skull); px(35, 9 - rightArmUp, skull)
            // Magic particles from hands
            let leftMagicY = 7 - leftArmUp
            let rightMagicY = 7 - rightArmUp
            if leftMagicY >= 0 {
                px(4, leftMagicY, magic); px(5, leftMagicY, magic)
                if leftArmUp > 0 {
                    px(3, leftMagicY - 1, magicBright); px(6, leftMagicY - 1, magicBright)
                }
            }
            if rightMagicY >= 0 {
                px(34, rightMagicY, magic); px(35, rightMagicY, magic)
                if rightArmUp > 0 {
                    px(33, rightMagicY - 1, magicBright); px(36, rightMagicY - 1, magicBright)
                }
            }

            // Floating mini-skulls — orbit laterally between frames
            let leftSkullX = frame == 0 ? 1 : 4
            let rightSkullX = frame == 0 ? 38 : 35
            let leftSkullY = frame == 0 ? 5 : 3
            let rightSkullY = frame == 0 ? 3 : 5
            // Left mini-skull
            px(leftSkullX, leftSkullY, skull); px(leftSkullX + 1, leftSkullY, skull)
            px(leftSkullX, leftSkullY + 1, skull); px(leftSkullX + 1, leftSkullY + 1, skull)
            px(leftSkullX, leftSkullY + 1, skullDark)
            px(leftSkullX, leftSkullY, eyes)
            // Right mini-skull
            if rightSkullX + 1 < 40 {
                px(rightSkullX, rightSkullY, skull); px(rightSkullX + 1, rightSkullY, skull)
                px(rightSkullX, rightSkullY + 1, skull); px(rightSkullX + 1, rightSkullY + 1, skull)
                px(rightSkullX + 1, rightSkullY + 1, skullDark)
                px(rightSkullX + 1, rightSkullY, eyes)
            }
        }
    }

    // MARK: - Juggernaut (brown brute - 48x48)
    private func drawJuggernaut(frame: Int) -> SKTexture {
        return makeCanvas(size: 48) { px in
            let body = ColorPalette.enemyJuggernaut
            let dark = self.darker(body)
            let armor = SKColor(red: 0.3, green: 0.25, blue: 0.18, alpha: 1)
            let armorLight = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1)
            let eyes = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 1)
            let outline = SKColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1)
            let teeth = SKColor.white
            let bootColor = SKColor(red: 0.2, green: 0.15, blue: 0.08, alpha: 1)
            let bootMetal = SKColor(red: 0.35, green: 0.3, blue: 0.2, alpha: 1)

            // Massive head (small relative to body)
            for y in 4...13 {
                let hw = y < 7 ? (y - 3) : (y > 11 ? max(1, 13 - y) : 5)
                for x in (23 - hw)...(24 + hw) { px(x, y, body) }
            }
            // Brow ridge
            for x in 18...29 { px(x, 5, armor) }
            for x in 19...28 { px(x, 6, armor) }
            // Angry eyes (deep set)
            px(20, 8, outline); px(21, 8, eyes); px(22, 8, eyes)
            px(25, 8, eyes); px(26, 8, eyes); px(27, 8, outline)
            // Snarling mouth
            for x in 20...27 { px(x, 11, outline) }
            px(21, 11, teeth); px(23, 11, teeth); px(25, 11, teeth)
            for x in 20...27 { px(x, 12, dark) }

            // Massive shoulders and torso
            for y in 13...34 {
                let hw: Int
                if y < 17 { hw = 7 + (y - 13) * 2 }
                else if y < 28 { hw = 15 }
                else { hw = 15 - (y - 28) }
                for x in max(0, 23 - hw)...min(47, 24 + hw) {
                    px(x, y, body)
                }
            }

            // Armor plates on chest
            for y in 16...26 {
                let aw = min(y - 14, 10)
                for x in (23 - aw)...(24 + aw) {
                    if (x + y) % 3 == 0 { px(x, y, armor) }
                }
            }
            // Center armor plate
            for y in 17...25 {
                px(22, y, armorLight); px(23, y, armor); px(24, y, armor); px(25, y, armorLight)
            }
            // Shoulder pads
            for y in 13...17 {
                for x in 6...12 { px(x, y, armor) }
                for x in 35...41 { px(x, y, armor) }
            }
            // Spikes on shoulders
            px(8, 11, armorLight); px(9, 12, armorLight)
            px(38, 11, armorLight); px(39, 12, armorLight)

            // Thick arms — contralateral swing with 3px range
            let leftArmShift = frame == 0 ? 0 : 3
            let rightArmShift = frame == 0 ? 3 : 0
            for y in (17 + leftArmShift)...(30 + leftArmShift) {
                for x in 3...10 { px(x, y, body) }
            }
            for y in (17 + rightArmShift)...(30 + rightArmShift) {
                for x in 37...44 { px(x, y, body) }
            }
            // Fists
            for y in (30 + leftArmShift)...min(47, 33 + leftArmShift) {
                for x in 2...10 { px(x, y, dark) }
            }
            for y in (30 + rightArmShift)...min(47, 33 + rightArmShift) {
                for x in 37...45 { px(x, y, dark) }
            }

            // Legs — heavy vertical stomp stride
            if frame == 0 {
                // Left leg forward (extended lower)
                for y in 34...44 {
                    px(14, y, body); px(15, y, body); px(16, y, body); px(17, y, body); px(18, y, body)
                }
                // Left heavy boot
                for x in 12...20 { px(x, 45, bootColor); px(x, 46, bootColor) }
                for x in 13...19 { px(x, 47, bootColor) }
                px(12, 44, bootMetal); px(20, 44, bootMetal) // Boot studs
                // Right leg back (shorter)
                for y in 34...40 {
                    px(29, y, body); px(30, y, body); px(31, y, body); px(32, y, body); px(33, y, body)
                }
                for x in 28...34 { px(x, 41, bootColor); px(x, 42, bootColor) }
            } else {
                // Right leg forward (extended lower)
                for y in 34...44 {
                    px(29, y, body); px(30, y, body); px(31, y, body); px(32, y, body); px(33, y, body)
                }
                // Right heavy boot
                for x in 27...35 { px(x, 45, bootColor); px(x, 46, bootColor) }
                for x in 28...34 { px(x, 47, bootColor) }
                px(27, 44, bootMetal); px(35, 44, bootMetal) // Boot studs
                // Left leg back (shorter)
                for y in 34...40 {
                    px(14, y, body); px(15, y, body); px(16, y, body); px(17, y, body); px(18, y, body)
                }
                for x in 13...19 { px(x, 41, bootColor); px(x, 42, bootColor) }
            }
        }
    }

    // MARK: - Wraith (ghostly blue specter - 32x32)
    private func drawWraith(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let body = ColorPalette.enemyWraith
            let dark = self.darker(body)
            let glow = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1)
            let eyes = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1)
            let eyeGlow = SKColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.4)
            let wisp = SKColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.5)
            let wispBright = SKColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 0.3)

            // Body sway: 1px left/right between frames
            let sway = frame == 0 ? -1 : 1

            // Hood/head (pointed, spectral)
            for y in 2...10 {
                let hw = min(y - 1, 5)
                for x in (15 - hw + sway)...(16 + hw + sway) { px(x, y, dark) }
            }
            // Inner face
            for y in 5...10 {
                let hw = min(y - 4, 4)
                for x in (15 - hw + sway)...(16 + hw + sway) { px(x, y, body) }
            }

            // Glowing eyes
            px(13 + sway, 7, eyeGlow); px(14 + sway, 7, eyes); px(15 + sway, 7, eyes)
            px(16 + sway, 7, eyes); px(17 + sway, 7, eyes); px(18 + sway, 7, eyeGlow)
            // Eye trail effect — longer trail
            let trailY = frame == 0 ? 8 : 9
            px(13 + sway, trailY, eyeGlow); px(18 + sway, trailY, eyeGlow)
            px(13 + sway, trailY + 1, wispBright); px(18 + sway, trailY + 1, wispBright)

            // Spectral body (fading, tattered) — sways with head
            for y in 11...26 {
                let hw = min(6 + (y - 11) / 3, 9)
                for x in max(0, 15 - hw + sway)...min(31, 16 + hw + sway) {
                    let edge = abs(x - (15 + sway)) + abs(x - (16 + sway))
                    if edge > hw - 2 && (x + y) % 2 == 0 {
                        px(x, y, wisp)
                    } else {
                        px(x, y, body)
                    }
                }
            }

            // Spectral arms — lift 3px (was 1px)
            let armY = frame == 0 ? 0 : -3
            for y in (12 + armY)...(18 + armY) {
                px(5, y, wisp); px(6, y, body); px(7, y, body)
                px(24, y, body); px(25, y, body); px(26, y, wisp)
            }
            // Claw-like fingers — more ghostly
            px(4, 12 + armY, glow); px(5, 11 + armY, glow); px(3, 11 + armY, wispBright)
            px(27, 12 + armY, glow); px(26, 11 + armY, glow); px(28, 11 + armY, wispBright)

            // Tattered bottom (wispy tendrils) — more tendrils, 2px swing
            let tendrilShift = frame == 0 ? -2 : 2
            for i in 0..<7 {
                let tx = 8 + i * 3 + (i % 2 == 0 ? tendrilShift : -tendrilShift) + sway
                let tendrilLen = 2 + (i % 3)
                for y in 26...min(31, 26 + tendrilLen) {
                    if tx >= 0 && tx < 32 { px(tx, y, wisp) }
                }
                // Extra wisp at tendril tip
                if tx >= 0 && tx < 32 && 27 + tendrilLen < 32 {
                    px(tx, 27 + tendrilLen, wispBright)
                }
            }

            // Faint glow aura
            px(15 + sway, 1, glow); px(16 + sway, 1, glow)
            px(10, 14, wisp); px(21, 14, wisp)
            // Additional floating wisps
            px(frame == 0 ? 8 : 23, 10, wispBright)
            px(frame == 0 ? 22 : 9, 16, wispBright)
        }
    }

    // MARK: - Splitter (green slime blob - 32x32)
    private func drawSplitter(frame: Int) -> SKTexture {
        return makeCanvas(size: 32) { px in
            let body = ColorPalette.enemySplitter
            let dark = self.darker(body)
            let light = SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1)
            let nucleus = SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1)
            let eyes = ColorPalette.enemyEyes
            let outline = SKColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 1)
            let splashDrop = SKColor(red: 0.3, green: 0.75, blue: 0.3, alpha: 0.7)

            let squish = frame == 1

            // More dramatic squish: taller jump frame, flatter land frame
            let cx = 15, cy = squish ? 18 : 12   // More vertical shift (was 16/14)
            let rx = squish ? 14 : 9              // Wider when squished (was 12/10)
            let ry = squish ? 6 : 13              // Flatter when squished, taller when jumping (was 8/11)

            for y in 0..<32 {
                for x in 0..<32 {
                    let dx = x - cx
                    let dy = y - cy
                    let norm = (Double(dx * dx) / Double(rx * rx)) + (Double(dy * dy) / Double(ry * ry))
                    if norm <= 1.0 {
                        if norm > 0.8 {
                            px(x, y, dark)
                        } else if norm > 0.5 {
                            px(x, y, body)
                        } else {
                            px(x, y, light)
                        }
                    }
                }
            }

            // Nucleus (darker center) — follows squish
            for y in (cy - 2)...(cy + 2) {
                for x in (cx - 2)...(cx + 2) {
                    let dx = x - cx, dy = y - cy
                    if dx * dx + dy * dy <= 5 { px(x, y, nucleus) }
                }
            }

            // Eyes shift with squish — wider apart when squished, closer when tall
            let eyeSpread = squish ? 4 : 3
            let eyeY = squish ? cy - 3 : cy - 5
            // Left eye
            px(cx - eyeSpread - 1, eyeY, SKColor.white); px(cx - eyeSpread, eyeY, SKColor.white)
            px(cx - eyeSpread - 1, eyeY + 1, SKColor.white); px(cx - eyeSpread, eyeY + 1, eyes)
            // Right eye
            px(cx + eyeSpread, eyeY, SKColor.white); px(cx + eyeSpread + 1, eyeY, SKColor.white)
            px(cx + eyeSpread, eyeY + 1, eyes); px(cx + eyeSpread + 1, eyeY + 1, SKColor.white)
            // Squished eyes get flattened (droopy lids)
            if squish {
                px(cx - eyeSpread - 1, eyeY, dark); px(cx + eyeSpread + 1, eyeY, dark)
            }

            // Mouth (wobbly smile) — wider when squished
            let mouthY = squish ? cy - 1 : cy - 2
            if squish {
                px(cx - 3, mouthY, outline); px(cx - 2, mouthY, outline)
                px(cx - 1, mouthY + 1, outline); px(cx, mouthY + 1, outline); px(cx + 1, mouthY + 1, outline)
                px(cx + 2, mouthY, outline); px(cx + 3, mouthY, outline)
            } else {
                px(cx - 2, mouthY, outline); px(cx - 1, mouthY, outline)
                px(cx, mouthY + 1, outline); px(cx + 1, mouthY + 1, outline)
                px(cx + 2, mouthY, outline); px(cx + 3, mouthY, outline)
            }

            // Splash drips on landing (only in squish frame)
            if squish {
                // Multiple splash droplets flying outward
                px(2, cy + ry - 1, splashDrop); px(3, cy + ry, splashDrop)
                px(28, cy + ry - 1, splashDrop); px(27, cy + ry, splashDrop)
                px(5, cy + ry + 1, splashDrop); px(6, cy + ry + 2, dark)
                px(25, cy + ry + 1, splashDrop); px(24, cy + ry + 2, dark)
                // Small puddle drips
                px(9, cy + ry + 1, dark); px(21, cy + ry + 1, dark)
                px(15, cy + ry + 1, dark); px(16, cy + ry + 1, dark)
            } else {
                // Drip/bubbles when in air
                px(10, cy + ry + 1, dark); px(11, cy + ry + 2, dark)
                px(20, cy + ry + 1, dark)
            }

            // Small bubble
            px(cx + 6, cy - ry + 1, light)
            px(cx - 6, cy - ry + 2, light)

            // Division line hint (showing it wants to split)
            for y in (cy - 3)...(cy + 3) {
                px(cx, y, outline)
                px(cx + 1, y, outline)
            }
        }
    }

    // MARK: - Shield Bearer (armored knight with energy shield - 36x36)
    private func drawShieldBearer(frame: Int) -> SKTexture {
        return makeCanvas(size: 36) { px in
            let armor = ColorPalette.enemyShieldBearer
            let armorDark = SKColor(red: 0.4, green: 0.5, blue: 0.65, alpha: 1)
            let armorLight = SKColor(red: 0.75, green: 0.82, blue: 0.92, alpha: 1)
            let outline = SKColor(red: 0.2, green: 0.25, blue: 0.35, alpha: 1)
            let eyes = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1)
            let shieldEdge = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
            let shieldFill = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.7)
            let shieldGlow = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.5)
            let visor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)

            let walk = frame == 1

            // --- Helmet (top) ---
            // Rounded helmet with slit visor
            for x in 14...22 { px(x, 2, outline) }
            for x in 13...23 { px(x, 3, armorDark) }
            for x in 12...24 { px(x, 4, armor) }
            for x in 12...24 { px(x, 5, armor) }
            // Visor slit
            for x in 14...22 { px(x, 6, visor) }
            // Eyes glow through visor
            px(15, 6, eyes); px(16, 6, eyes)
            px(20, 6, eyes); px(21, 6, eyes)
            for x in 12...24 { px(x, 7, armor) }
            // Chin guard
            for x in 13...23 { px(x, 8, armorDark) }
            for x in 14...22 { px(x, 9, outline) }

            // --- Torso / Chest plate ---
            for y in 10...17 {
                for x in 13...23 {
                    px(x, y, armor)
                }
                // Outline edges
                px(12, y, outline)
                px(24, y, outline)
            }
            // Chest plate highlights
            for y in 11...15 {
                px(17, y, armorLight); px(18, y, armorLight); px(19, y, armorLight)
            }
            // Chest plate dark center line
            for y in 11...16 { px(18, y, armorDark) }
            // Shoulder pauldrons
            for x in 9...12 { px(x, 10, armorDark); px(x, 11, armor) }
            for x in 24...27 { px(x, 10, armorDark); px(x, 11, armor) }
            px(9, 10, outline); px(27, 10, outline)

            // --- Arms ---
            let leftArmY = walk ? 13 : 15   // Contralateral arm swing
            let rightArmY = walk ? 15 : 13

            // Left arm (shield arm — holds steady, slightly forward)
            for y in 12...18 {
                px(10, y, armor); px(11, y, armor)
            }
            px(10, 12, outline); px(11, 12, outline)
            // Gauntlet
            px(10, 18, armorDark); px(11, 18, armorDark)
            px(10, 19, armorLight); px(11, 19, armorLight)

            // Right arm (weapon arm swings)
            for dy in 0...5 {
                px(25, rightArmY + dy, armor); px(26, rightArmY + dy, armor)
            }
            px(25, rightArmY, outline); px(26, rightArmY, outline)
            // Right gauntlet
            px(25, rightArmY + 5, armorDark); px(26, rightArmY + 5, armorDark)
            px(25, rightArmY + 6, armorLight); px(26, rightArmY + 6, armorLight)

            // --- Weapon (mace/sword in right hand) ---
            let weaponBaseY = rightArmY + 6
            px(25, weaponBaseY + 1, outline)
            px(25, weaponBaseY + 2, armorLight)
            px(25, weaponBaseY + 3, armorLight)
            px(24, weaponBaseY + 3, outline); px(26, weaponBaseY + 3, outline)

            // --- Belt ---
            for x in 13...23 { px(x, 18, armorDark) }
            // Belt buckle
            px(17, 18, armorLight); px(18, 18, armorLight); px(19, 18, armorLight)

            // --- Legs with stride ---
            let leftLegX = walk ? 14 : 15
            let rightLegX = walk ? 21 : 20
            let leftLegLen = walk ? 9 : 7
            let rightLegLen = walk ? 7 : 9

            // Left leg
            for dy in 0..<leftLegLen {
                px(leftLegX, 19 + dy, armor); px(leftLegX + 1, 19 + dy, armor)
                px(leftLegX + 2, 19 + dy, armorDark)
            }
            // Left boot
            let leftBootY = 19 + leftLegLen
            px(leftLegX - 1, leftBootY, outline); px(leftLegX, leftBootY, armorDark)
            px(leftLegX + 1, leftBootY, armorDark); px(leftLegX + 2, leftBootY, armorDark)
            px(leftLegX + 3, leftBootY, outline)

            // Right leg
            for dy in 0..<rightLegLen {
                px(rightLegX, 19 + dy, armorDark); px(rightLegX + 1, 19 + dy, armor)
                px(rightLegX + 2, 19 + dy, armor)
            }
            // Right boot
            let rightBootY = 19 + rightLegLen
            px(rightLegX - 1, rightBootY, outline); px(rightLegX, rightBootY, armorDark)
            px(rightLegX + 1, rightBootY, armorDark); px(rightLegX + 2, rightBootY, armorDark)
            px(rightLegX + 3, rightBootY, outline)

            // Energy shield is now a dynamic child node (see EnemyNode.setupShieldVisual)
        }
    }

    // MARK: - Snowflake Texture (8x8 pixel art)

    func snowflakeTexture(variant: Int = 0) -> SKTexture {
        let key = "snowflake_\(variant)"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 8) { px in
                let ice = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1)
                let bright = SKColor.white

                if variant == 0 {
                    // Classic 6-point snowflake
                    // Vertical axis
                    px(3, 0, ice); px(4, 0, ice)
                    px(3, 1, bright); px(4, 1, bright)
                    px(3, 6, bright); px(4, 6, bright)
                    px(3, 7, ice); px(4, 7, ice)
                    // Horizontal axis
                    px(0, 3, ice); px(1, 3, bright); px(6, 3, bright); px(7, 3, ice)
                    px(0, 4, ice); px(1, 4, bright); px(6, 4, bright); px(7, 4, ice)
                    // Center
                    px(3, 3, bright); px(4, 3, bright)
                    px(3, 4, bright); px(4, 4, bright)
                    // Diagonal arms
                    px(2, 2, ice); px(5, 2, ice)
                    px(2, 5, ice); px(5, 5, ice)
                    px(1, 1, ice); px(6, 1, ice)
                    px(1, 6, ice); px(6, 6, ice)
                } else if variant == 1 {
                    // Diamond snowflake
                    px(3, 0, ice); px(4, 0, ice)
                    px(2, 1, ice); px(3, 1, bright); px(4, 1, bright); px(5, 1, ice)
                    px(1, 2, ice); px(3, 2, bright); px(4, 2, bright); px(6, 2, ice)
                    px(0, 3, ice); px(1, 3, bright); px(2, 3, bright); px(3, 3, bright); px(4, 3, bright); px(5, 3, bright); px(6, 3, bright); px(7, 3, ice)
                    px(0, 4, ice); px(1, 4, bright); px(2, 4, bright); px(3, 4, bright); px(4, 4, bright); px(5, 4, bright); px(6, 4, bright); px(7, 4, ice)
                    px(1, 5, ice); px(3, 5, bright); px(4, 5, bright); px(6, 5, ice)
                    px(2, 6, ice); px(3, 6, bright); px(4, 6, bright); px(5, 6, ice)
                    px(3, 7, ice); px(4, 7, ice)
                } else {
                    // Simple dot crystal
                    px(3, 1, ice); px(4, 1, ice)
                    px(1, 3, ice); px(3, 3, bright); px(4, 3, bright); px(6, 3, ice)
                    px(1, 4, ice); px(3, 4, bright); px(4, 4, bright); px(6, 4, ice)
                    px(3, 6, ice); px(4, 6, ice)
                    px(2, 2, bright); px(5, 2, bright)
                    px(2, 5, bright); px(5, 5, bright)
                }
            }
        }
    }

    // MARK: - Pickup Textures

    func coinPickupTexture() -> SKTexture {
        let key = "coin_pickup"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 8) { px in
                let gold = ColorPalette.gold
                let bright = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
                let dark = SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1)

                // Circular coin
                let cx = 3, cy = 3
                for y in 0..<8 {
                    for x in 0..<8 {
                        let dx = x - cx, dy = y - cy
                        let dist = dx * dx + dy * dy
                        if dist <= 2 {
                            px(x, y, bright)
                        } else if dist <= 6 {
                            px(x, y, gold)
                        } else if dist <= 10 {
                            px(x, y, dark)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Projectile Textures

    func projectileTexture(isGhost: Bool) -> SKTexture {
        let key = isGhost ? "proj_ghost" : "proj_player"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 8) { px in
                let color = isGhost ? ColorPalette.bulletGhost : ColorPalette.bulletPlayer
                let bright = SKColor.white

                // Glowing orb with gradient
                let center = 3
                for y in 0..<8 {
                    for x in 0..<8 {
                        let dx = x - center, dy = y - center
                        let dist = dx * dx + dy * dy
                        if dist <= 2 {
                            px(x, y, bright)
                        } else if dist <= 6 {
                            px(x, y, color)
                        } else if dist <= 10 {
                            px(x, y, color.withAlphaComponent(0.5))
                        }
                    }
                }
            }
        }
    }

    func enemyProjectileTexture() -> SKTexture {
        let key = "proj_enemy"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 8) { px in
                let color = ColorPalette.bulletEnemy
                let center = 3
                for y in 0..<8 {
                    for x in 0..<8 {
                        let dx = x - center, dy = y - center
                        let dist = dx * dx + dy * dy
                        if dist <= 2 { px(x, y, SKColor.white) }
                        else if dist <= 6 { px(x, y, color) }
                        else if dist <= 10 { px(x, y, color.withAlphaComponent(0.4)) }
                    }
                }
            }
        }
    }

    // MARK: - Arena Tiles

    func floorTileTexture(variant: Int) -> SKTexture {
        let key = "floor_tile_\(variant)"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 64) { px in
                // Dark metal floor — seamless, no grid
                let base1 = SKColor(red: 0.055, green: 0.06, blue: 0.085, alpha: 1)
                let base2 = SKColor(red: 0.065, green: 0.07, blue: 0.095, alpha: 1)
                let base3 = SKColor(red: 0.045, green: 0.05, blue: 0.075, alpha: 1)
                let dark = SKColor(red: 0.035, green: 0.038, blue: 0.06, alpha: 1)
                let scuff = SKColor(red: 0.08, green: 0.085, blue: 0.115, alpha: 1)

                // Noisy fill — 3 tones blended pseudo-randomly
                for y in 0..<64 {
                    for x in 0..<64 {
                        let n = ((x &* 17) &+ (y &* 31) &+ (x &* y &* 3)) & 15
                        if n < 4 { px(x, y, base3) }
                        else if n < 6 { px(x, y, base2) }
                        else { px(x, y, base1) }
                    }
                }

                // Variant-specific surface details
                switch variant {
                case 0:
                    // Clean floor — very subtle wear
                    for i in 0..<8 { px(30 + i, 40, scuff) }

                case 1:
                    // Diagonal scratch marks
                    for i in 0..<14 {
                        px(16 + i, 18 + i, scuff); px(17 + i, 18 + i, scuff)
                    }
                    // Small oil stain
                    for y in 42...48 {
                        let hw = max(0, 3 - abs(y - 45))
                        for x in (14 - hw)...(14 + hw) { px(x, y, dark) }
                    }

                case 2:
                    // Cable channel running horizontally
                    let groove = SKColor(red: 0.03, green: 0.032, blue: 0.05, alpha: 1)
                    let grooveEdge = SKColor(red: 0.085, green: 0.09, blue: 0.12, alpha: 1)
                    for x in 0..<64 {
                        px(x, 30, grooveEdge); px(x, 33, grooveEdge)
                        px(x, 31, groove); px(x, 32, groove)
                    }
                    let cableGlow = SKColor(red: 0.0, green: 0.10, blue: 0.18, alpha: 1)
                    for x in 0..<64 {
                        let wobble = (x &* 3 &+ 7) % 5 == 0 ? 1 : 0
                        px(x, 31 + wobble, cableGlow)
                    }

                case 3:
                    // Vent grate
                    let vent = SKColor(red: 0.018, green: 0.018, blue: 0.032, alpha: 1)
                    let ventEdge = SKColor(red: 0.095, green: 0.095, blue: 0.13, alpha: 1)
                    for x in 20...43 { px(x, 18, ventEdge); px(x, 45, ventEdge) }
                    for y in 18...45 { px(20, y, ventEdge); px(43, y, ventEdge) }
                    for row in 0..<5 {
                        let slotY = 22 + row * 5
                        for x in 22...41 {
                            px(x, slotY, vent); px(x, slotY + 1, vent)
                        }
                    }
                    let ventGlow = SKColor(red: 0.0, green: 0.035, blue: 0.06, alpha: 1)
                    for x in 28...35 { for y in 28...38 { px(x, y, ventGlow) } }

                case 4:
                    // Chevron floor markings
                    let marking = SKColor(red: 0.075, green: 0.075, blue: 0.105, alpha: 1)
                    for i in 0..<6 {
                        px(24 + i, 32 - i, marking); px(24 + i, 32 + i, marking)
                        px(34 + i, 32 - i, marking); px(34 + i, 32 + i, marking)
                    }

                case 5:
                    // Hazard stripe corner
                    let warn = SKColor(red: 0.10, green: 0.08, blue: 0.0, alpha: 1)
                    let warnDark = SKColor(red: 0.04, green: 0.035, blue: 0.035, alpha: 1)
                    for i in 0..<10 {
                        let c = (i / 2) % 2 == 0 ? warn : warnDark
                        for j in 0...max(0, 9 - i) { px(j, i, c); px(i, j, c) }
                    }

                default:
                    break
                }
            }
        }
    }

    func wallTileTexture() -> SKTexture {
        let key = "wall_tile"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 64) { px in
                let wall = ColorPalette.arenaWall
                let dark = self.darker(wall, by: 0.1)
                let light = self.lighter(wall, by: 0.1)
                let mortar = SKColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1)
                let glow = SKColor(red: 0.0, green: 0.25, blue: 0.45, alpha: 0.5)

                // Fill wall base
                for y in 0..<64 {
                    for x in 0..<64 {
                        let noise = ((x * 13 + y * 29) % 5)
                        px(x, y, noise == 0 ? dark : (noise == 4 ? light : wall))
                    }
                }

                // Heavy plate pattern — large horizontal plates
                for row in 0..<4 {
                    let y = row * 16
                    for x in 0..<64 { px(x, y, mortar); px(x, y + 1, light) }
                    for x in 0..<64 { px(x, y + 15, dark) }
                    // Vertical seam (offset each row)
                    let offset = (row % 2 == 0) ? 32 : 0
                    if offset < 64 {
                        for dy in 0..<16 { px(offset, y + dy, mortar) }
                    }
                }

                // Bold energy line
                for x in 0..<64 {
                    px(x, 31, glow); px(x, 32, glow); px(x, 33, glow)
                }
                // Bright pulse points
                let pulse = SKColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.4)
                px(16, 32, pulse); px(48, 32, pulse)
                px(15, 31, pulse); px(17, 33, pulse)
                px(47, 31, pulse); px(49, 33, pulse)

                // Rivets on wall
                let rivet = SKColor(red: 0.14, green: 0.14, blue: 0.20, alpha: 1)
                for row in 0..<4 {
                    let y = row * 16 + 8
                    px(8, y, rivet); px(56, y, rivet)
                }
            }
        }
    }

    func cornerGlowTexture() -> SKTexture {
        let key = "corner_glow"
        return cachedTexture(key: key) {
            let size = 128
            let s = self.pixelScale
            let imgSize = CGSize(width: size * s, height: size * s)
            let renderer = UIGraphicsImageRenderer(size: imgSize)
            let image = renderer.image { ctx in
                let c = ctx.cgContext
                let colors = [
                    ColorPalette.playerPrimary.withAlphaComponent(0.12).cgColor,
                    SKColor.clear.cgColor
                ] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
                let center = CGPoint(x: 0, y: 0)
                c.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: CGFloat(size * s), options: [])
            }
            let tex = SKTexture(image: image)
            tex.filteringMode = .linear
            return tex
        }
    }

    func crackDecalTexture() -> SKTexture {
        let key = "crack_decal"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 32) { px in
                let crack = SKColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 0.7)
                let crackEdge = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.4)
                var x = 16, y = 0
                while y < 32 {
                    px(x, y, crack)
                    if x > 0 { px(x - 1, y, crackEdge) }
                    if x < 31 { px(x + 1, y, crackEdge) }
                    y += 1
                    let r = (x * 7 + y * 13) % 5
                    if r < 2 { x += 1 }
                    else if r < 4 { x -= 1 }
                    x = max(4, min(28, x))
                    if y == 10 || y == 20 {
                        var bx = x
                        for by in y...min(31, y + 5) {
                            bx += (y == 10 ? 1 : -1)
                            bx = max(1, min(30, bx))
                            px(bx, by, crack)
                        }
                    }
                }
            }
        }
    }

    // Ambient light pool decal for arena variety
    func lightPoolTexture() -> SKTexture {
        let key = "light_pool"
        return cachedTexture(key: key) {
            let size = 64
            let s = self.pixelScale
            let imgSize = CGSize(width: size * s, height: size * s)
            let renderer = UIGraphicsImageRenderer(size: imgSize)
            let image = renderer.image { ctx in
                let c = ctx.cgContext
                let colors = [
                    SKColor(red: 0.0, green: 0.15, blue: 0.25, alpha: 0.12).cgColor,
                    SKColor.clear.cgColor
                ] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
                let center = CGPoint(x: CGFloat(size * s) / 2, y: CGFloat(size * s) / 2)
                c.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: CGFloat(size * s) / 2, options: [])
            }
            let tex = SKTexture(image: image)
            tex.filteringMode = .linear
            return tex
        }
    }

    // MARK: - Obstacle Textures

    /// Metal crate — 24x24 pixel art
    func crateTexture(variant: Int) -> SKTexture {
        let key = "crate_\(variant)"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 24) { px in
                let metal = SKColor(red: 0.18, green: 0.17, blue: 0.22, alpha: 1)
                let metalDark = SKColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
                let metalLight = SKColor(red: 0.24, green: 0.23, blue: 0.30, alpha: 1)
                let rivet = SKColor(red: 0.30, green: 0.28, blue: 0.35, alpha: 1)
                let edge = SKColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)

                // Main body
                for y in 1..<23 { for x in 1..<23 { px(x, y, metal) } }
                // Top/left highlight
                for x in 1..<23 { px(x, 1, metalLight) }
                for y in 1..<23 { px(1, y, metalLight) }
                // Bottom/right shadow
                for x in 1..<23 { px(x, 22, metalDark) }
                for y in 1..<23 { px(22, y, metalDark) }
                // Outline
                for x in 0..<24 { px(x, 0, edge); px(x, 23, edge) }
                for y in 0..<24 { px(0, y, edge); px(23, y, edge) }

                // Cross braces
                for i in 4..<20 {
                    px(i, 12, metalDark); px(12, i, metalDark)
                    px(i, 11, metalLight); px(11, i, metalLight)
                }

                // Corner rivets
                for (rx, ry) in [(3,3),(20,3),(3,20),(20,20)] {
                    px(rx, ry, rivet); px(rx+1, ry, rivet)
                    px(rx, ry+1, rivet); px(rx+1, ry+1, metalDark)
                }

                // Variant coloring
                if variant == 1 {
                    // Orange hazard stripe
                    let stripe = SKColor(red: 0.25, green: 0.15, blue: 0.0, alpha: 1)
                    for x in 4..<20 { px(x, 6, stripe); px(x, 7, stripe) }
                } else if variant == 2 {
                    // Green marking
                    let mark = SKColor(red: 0.0, green: 0.18, blue: 0.08, alpha: 1)
                    for x in 8...15 { for y in 5...8 { px(x, y, mark) } }
                }
            }
        }
    }

    /// Pillar — 16x16 circular column (top-down view)
    func pillarTexture() -> SKTexture {
        let key = "pillar"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 16) { px in
                let stone = SKColor(red: 0.20, green: 0.19, blue: 0.24, alpha: 1)
                let stoneLight = SKColor(red: 0.28, green: 0.27, blue: 0.34, alpha: 1)
                let stoneDark = SKColor(red: 0.12, green: 0.11, blue: 0.16, alpha: 1)
                let outline = SKColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1)
                let glow = SKColor(red: 0.0, green: 0.12, blue: 0.22, alpha: 1)

                let cx = 7, cy = 7, r = 6
                for y in 0..<16 {
                    for x in 0..<16 {
                        let dx = x - cx, dy = y - cy
                        let distSq = dx * dx + dy * dy
                        if distSq <= r * r {
                            // Lighting: top-left light, bottom-right dark
                            if dx + dy < -3 { px(x, y, stoneLight) }
                            else if dx + dy > 3 { px(x, y, stoneDark) }
                            else { px(x, y, stone) }
                        } else if distSq <= (r + 1) * (r + 1) {
                            px(x, y, outline)
                        }
                    }
                }
                // Center cyan accent dot
                px(cx, cy, glow); px(cx + 1, cy, glow)
            }
        }
    }

    /// Barrier wall segment — 32x12 horizontal wall
    func barrierTexture() -> SKTexture {
        let key = "barrier"
        return cachedTexture(key: key) {
            return self.makeCanvasRect(w: 32, h: 12) { px in
                let metal = SKColor(red: 0.16, green: 0.15, blue: 0.21, alpha: 1)
                let metalLight = SKColor(red: 0.22, green: 0.21, blue: 0.28, alpha: 1)
                let metalDark = SKColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 1)
                let edge = SKColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1)
                let stripe = SKColor(red: 0.22, green: 0.18, blue: 0.0, alpha: 1)

                // Main body
                for y in 1..<11 { for x in 1..<31 { px(x, y, metal) } }
                // Top highlight
                for x in 1..<31 { px(x, 1, metalLight); px(x, 2, metalLight) }
                // Bottom shadow
                for x in 1..<31 { px(x, 10, metalDark) }
                // Outline
                for x in 0..<32 { px(x, 0, edge); px(x, 11, edge) }
                for y in 0..<12 { px(0, y, edge); px(31, y, edge) }
                // Hazard stripes
                for x in stride(from: 2, to: 30, by: 6) {
                    for dx in 0..<3 {
                        if x + dx < 31 {
                            px(x + dx, 5, stripe); px(x + dx, 6, stripe)
                        }
                    }
                }
                // Bolt heads
                px(4, 5, metalLight); px(27, 5, metalLight)
                px(4, 6, metalDark); px(27, 6, metalDark)
            }
        }
    }

    /// Terminal/console — 20x20 tech station
    func terminalTexture() -> SKTexture {
        let key = "terminal"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 20) { px in
                let body = SKColor(red: 0.12, green: 0.12, blue: 0.17, alpha: 1)
                let bodyLight = SKColor(red: 0.17, green: 0.17, blue: 0.23, alpha: 1)
                let bodyDark = SKColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1)
                let screen = SKColor(red: 0.0, green: 0.12, blue: 0.08, alpha: 1)
                let screenGlow = SKColor(red: 0.0, green: 0.25, blue: 0.15, alpha: 1)
                let edge = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
                let led = SKColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 1)

                // Body
                for y in 2..<18 { for x in 2..<18 { px(x, y, body) } }
                for x in 2..<18 { px(x, 2, bodyLight) }
                for x in 2..<18 { px(x, 17, bodyDark) }
                // Outline
                for x in 1..<19 { px(x, 1, edge); px(x, 18, edge) }
                for y in 1..<19 { px(1, y, edge); px(18, y, edge) }

                // Screen
                for y in 4...10 { for x in 4...15 { px(x, y, screen) } }
                // Screen text lines (simulated)
                for x in 5...13 { px(x, 5, screenGlow) }
                for x in 5...10 { px(x, 7, screenGlow) }
                for x in 5...14 { px(x, 9, screenGlow) }

                // LED indicators
                px(5, 13, led); px(8, 13, SKColor.red)
                px(11, 13, led); px(14, 13, led)

                // Keyboard area
                for y in 14...16 {
                    for x in 4...15 { px(x, y, bodyDark) }
                }
                for x in stride(from: 5, to: 15, by: 2) { px(x, 15, bodyLight) }
            }
        }
    }

    /// Barrel — 14x14 circular drum
    func barrelTexture(variant: Int) -> SKTexture {
        let key = "barrel_\(variant)"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 14) { px in
                let bodyColor = variant == 0
                    ? SKColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1)
                    : SKColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1)
                let bodyLight = self.lighter(bodyColor, by: 0.08)
                let bodyDark = self.darker(bodyColor, by: 0.08)
                let outline = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
                let ring = SKColor(red: 0.13, green: 0.13, blue: 0.18, alpha: 1)

                let cx = 6, cy = 6, r = 5
                for y in 0..<14 {
                    for x in 0..<14 {
                        let dx = x - cx, dy = y - cy
                        let distSq = dx * dx + dy * dy
                        if distSq <= r * r {
                            if dx < -2 { px(x, y, bodyLight) }
                            else if dx > 2 { px(x, y, bodyDark) }
                            else { px(x, y, bodyColor) }
                        } else if distSq <= (r + 1) * (r + 1) {
                            px(x, y, outline)
                        }
                    }
                }
                // Metal ring band
                for y in 0..<14 {
                    for x in 0..<14 {
                        let dx = x - cx, dy = y - cy
                        let distSq = dx * dx + dy * dy
                        if distSq <= r * r && (dy == -2 || dy == 2) {
                            px(x, y, ring)
                        }
                    }
                }
                // Top highlight
                px(cx - 1, cy - 3, bodyLight); px(cx, cy - 3, bodyLight)

                if variant == 1 {
                    // Hazard symbol
                    px(cx, cy, SKColor(red: 0.3, green: 0.25, blue: 0.0, alpha: 1))
                    px(cx - 1, cy + 1, SKColor(red: 0.3, green: 0.25, blue: 0.0, alpha: 1))
                    px(cx + 1, cy + 1, SKColor(red: 0.3, green: 0.25, blue: 0.0, alpha: 1))
                }
            }
        }
    }

    // MARK: - Joystick Textures

    func joystickBaseTexture() -> SKTexture {
        let key = "joystick_base"
        if let cached = textureCache[key] { return cached }
        let size: CGFloat = 120
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let rect = CGRect(x: 4, y: 4, width: size - 8, height: size - 8)
            // Outer ring
            c.setStrokeColor(ColorPalette.playerPrimary.withAlphaComponent(0.3).cgColor)
            c.setLineWidth(2)
            c.strokeEllipse(in: rect)
            // Inner fill
            c.setFillColor(ColorPalette.hudBackground.withAlphaComponent(0.3).cgColor)
            c.fillEllipse(in: rect.insetBy(dx: 2, dy: 2))
            // Cross-hair lines
            c.setStrokeColor(ColorPalette.textSecondary.withAlphaComponent(0.15).cgColor)
            c.setLineWidth(1)
            c.move(to: CGPoint(x: size / 2, y: 10))
            c.addLine(to: CGPoint(x: size / 2, y: size - 10))
            c.move(to: CGPoint(x: 10, y: size / 2))
            c.addLine(to: CGPoint(x: size - 10, y: size / 2))
            c.strokePath()
        }
        let tex = SKTexture(image: image)
        textureCache[key] = tex
        return tex
    }

    func joystickKnobTexture() -> SKTexture {
        let key = "joystick_knob"
        if let cached = textureCache[key] { return cached }
        let size: CGFloat = 50
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let rect = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)
            // Glow
            c.setFillColor(ColorPalette.playerPrimary.withAlphaComponent(0.15).cgColor)
            c.fillEllipse(in: rect.insetBy(dx: -4, dy: -4))
            // Fill
            c.setFillColor(ColorPalette.playerPrimary.withAlphaComponent(0.7).cgColor)
            c.fillEllipse(in: rect)
            // Highlight
            let highlight = CGRect(x: size * 0.3, y: size * 0.2, width: size * 0.25, height: size * 0.15)
            c.setFillColor(SKColor.white.withAlphaComponent(0.4).cgColor)
            c.fillEllipse(in: highlight)
            // Border
            c.setStrokeColor(SKColor.white.withAlphaComponent(0.5).cgColor)
            c.setLineWidth(1.5)
            c.strokeEllipse(in: rect)
        }
        let tex = SKTexture(image: image)
        textureCache[key] = tex
        return tex
    }

    // MARK: - Pause Icon

    func pauseIconTexture() -> SKTexture {
        let key = "pause_icon"
        if let cached = textureCache[key] { return cached }
        let tex = makeCanvas(size: 24) { px in
            let c = ColorPalette.textPrimary
            // Two vertical bars
            for y in 4...19 {
                for x in 7...9 { px(x, y, c) }
                for x in 14...16 { px(x, y, c) }
            }
        }
        textureCache[key] = tex
        return tex
    }

    // MARK: - Power-Up Icons

    func powerUpIconTexture(type: PowerUpType) -> SKTexture {
        let key = "powerup_\(type.rawValue)"
        return cachedTexture(key: key) {
            return self.makeCanvas(size: 24) { px in
                let iconColor = type.iconColor
                let bg = ColorPalette.hudBackground
                let ic = SKColor.white

                // Background rounded rect
                for y in 1...22 {
                    for x in 1...22 {
                        if (x <= 1 || x >= 22) && (y <= 1 || y >= 22) { continue }
                        px(x, y, bg)
                    }
                }
                // Border
                for x in 2...21 { px(x, 0, iconColor); px(x, 23, iconColor) }
                for y in 2...21 { px(0, y, iconColor); px(23, y, iconColor) }
                px(1, 1, iconColor); px(22, 1, iconColor)
                px(1, 22, iconColor); px(22, 22, iconColor)

                switch type {
                case .attackSpeed:
                    // Lightning bolt
                    let bolt: [(Int, Int)] = [(14,4),(13,5),(12,6),(11,7),(10,8),(11,8),(12,8),(13,8),(14,8),(13,9),(12,10),(11,11),(10,12),(9,13),(10,14),(11,14),(12,14),(13,14),(12,15),(11,16),(10,17),(9,18),(8,19)]
                    for (x, y) in bolt { px(x, y, ic) }
                case .damage:
                    for y in 4...18 { px(12, y, ic) }
                    for x in 9...15 { px(x, 13, ic) }
                    px(11, 14, ic); px(13, 14, ic)
                    for x in 10...14 { px(x, 19, ic) }
                case .multishot:
                    for y in 5...8 { px(6,y,ic); px(7,y,ic); px(11,y,ic); px(12,y,ic); px(16,y,ic); px(17,y,ic) }
                    for y in 9...16 { px(6,y,iconColor); px(11,y,iconColor); px(16,y,iconColor) }
                case .piercing:
                    for x in 4...19 { px(x, 12, ic) }
                    px(17,10,ic); px(18,11,ic); px(18,13,ic); px(17,14,ic)
                    for y in 8...16 { px(10,y,iconColor); px(11,y,iconColor) }
                case .moveSpeed:
                    for y in 10...18 { for x in 10...17 { px(x,y,ic) } }
                    for x in 14...20 { px(x, 18, ic) }
                    for x in 3...7 { px(x,11,iconColor) }
                    for x in 4...7 { px(x,14,iconColor) }
                    for x in 5...7 { px(x,17,iconColor) }
                case .maxHP:
                    px(8,8,ic); px(9,7,ic); px(10,7,ic); px(11,8,ic)
                    px(12,7,ic); px(13,7,ic); px(14,7,ic); px(15,8,ic)
                    for y in 8...10 { for x in 8...15 { px(x,y,ic) } }
                    for x in 9...14 { px(x,11,ic) }
                    for x in 10...13 { px(x,12,ic) }
                    for x in 11...12 { px(x,13,ic) }
                case .ghostDamage:
                    for y in 5...12 { for x in 8...15 { px(x,y,iconColor) } }
                    px(9,8,ic); px(10,8,ic); px(13,8,ic); px(14,8,ic)
                    for y in 13...17 { px(8,y,iconColor); px(10,y,iconColor); px(12,y,iconColor); px(14,y,iconColor) }
                case .orbitalShield:
                    let ctr = 12
                    for angle in stride(from: 0.0, through: 2.0 * .pi, by: 0.2) {
                        let ox = ctr + Int(cos(angle) * 6)
                        let oy = ctr + Int(sin(angle) * 6)
                        px(ox, oy, ic)
                    }
                    px(12, 12, iconColor); px(13, 12, iconColor)
                case .magnetRange:
                    for y in 6...16 { px(7,y,ic); px(8,y,ic); px(15,y,ic); px(16,y,ic) }
                    for x in 7...16 { px(x,16,ic); px(x,17,ic) }
                    px(7,6,ColorPalette.bulletEnemy); px(8,6,ColorPalette.bulletEnemy)
                    px(15,6,ColorPalette.bulletPlayer); px(16,6,ColorPalette.bulletPlayer)
                case .chainLightning:
                    // Forked lightning bolt
                    let bolt: [(Int,Int)] = [(14,4),(13,5),(12,6),(11,7),(10,8),(11,8),(12,8),(13,8),(12,9),(11,10),(10,11),(9,12),(10,13),(11,13),(12,13),(11,14),(10,15),(9,16),(8,17)]
                    for (x,y) in bolt { px(x,y,ic) }
                    px(13,10,iconColor); px(14,11,iconColor); px(15,12,iconColor)

                case .lifeSteal:
                    // Heart with drip
                    px(8,8,ic); px(9,7,ic); px(10,7,ic); px(11,8,ic)
                    px(12,7,ic); px(13,7,ic); px(14,7,ic); px(15,8,ic)
                    for y in 8...11 { for x in 8...15 { px(x,y,ic) } }
                    for x in 9...14 { px(x,12,ic) }
                    for x in 10...13 { px(x,13,ic) }
                    for x in 11...12 { px(x,14,ic) }
                    px(11,16,iconColor); px(11,17,iconColor)

                case .explosiveRounds:
                    // Explosion burst
                    let ecx = 12, ecy = 12
                    for a in stride(from: 0.0, through: 2.0 * Double.pi, by: Double.pi/4) {
                        for r in 3...6 {
                            let ox = ecx + Int(cos(a) * Double(r))
                            let oy = ecy + Int(sin(a) * Double(r))
                            if ox >= 0 && ox < 24 && oy >= 0 && oy < 24 {
                                px(ox, oy, r < 5 ? ic : iconColor)
                            }
                        }
                    }
                    px(ecx, ecy, ic); px(ecx+1, ecy, ic)

                case .thorns:
                    // Shield with spikes
                    for y in 7...16 { for x in 9...14 { px(x,y,iconColor) } }
                    px(8,9,ic); px(7,10,ic); px(15,9,ic); px(16,10,ic)
                    px(8,13,ic); px(7,14,ic); px(15,13,ic); px(16,14,ic)

                case .freezeAura:
                    // Snowflake
                    let fcx = 12, fcy = 12
                    for i in -5...5 { px(fcx+i, fcy, ic); px(fcx, fcy+i, ic) }
                    for i in -3...3 { px(fcx+i, fcy+i, iconColor); px(fcx+i, fcy-i, iconColor) }

                case .criticalStrike:
                    // Crosshair with exclamation
                    let ccx = 12, ccy = 12
                    for a in stride(from: 0.0, through: 2.0 * Double.pi, by: 0.2) {
                        let ox = ccx + Int(cos(a) * 6)
                        let oy = ccy + Int(sin(a) * 6)
                        if ox >= 0 && ox < 24 && oy >= 0 && oy < 24 { px(ox, oy, iconColor) }
                    }
                    for y in 8...13 { px(ccx, y, ic) }
                    px(ccx, 15, ic)
                }
            }
        }
    }

    // MARK: - Cache Helper

    private func cachedTexture(key: String, generator: () -> SKTexture) -> SKTexture {
        if let cached = textureCache[key] { return cached }
        let texture = generator()
        texture.filteringMode = .nearest
        textureCache[key] = texture
        return texture
    }
}
