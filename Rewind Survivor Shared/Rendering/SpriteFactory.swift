import SpriteKit

class SpriteFactory {
    static let shared = SpriteFactory()
    private var textureCache: [String: SKTexture] = [:]
    private let pixelScale: Int = 3 // 3x for crisp retina pixel art

    func invalidatePlayerTextures() {
        // Clear cached player/ghost textures so they regenerate with new cosmetic colors
        for dir in Direction.allCases {
            for f in 0...1 {
                textureCache.removeValue(forKey: "player_\(dir)_\(f)")
                textureCache.removeValue(forKey: "ghost_\(dir)_\(f)")
            }
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
            return self.drawPlayerCore(frame: 0, facing: .down, primary: primary, secondary: secondary, hatId: hatId)
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
        return drawPlayerCore(frame: frame, facing: facing, primary: primary, secondary: secondary, hatId: hatId)
    }

    private func drawPlayerCore(frame: Int, facing: Direction, primary: SKColor, secondary: SKColor, hatId: String) -> SKTexture {
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

            // -- Helmet --
            // Top crest
            for x in 13...18 { px(x, 3, dark) }
            px(15, 2, cyan); px(16, 2, cyan)
            // Helmet shell
            for y in 4...10 {
                let hw = y < 6 ? (y - 3) : 5
                for x in (16 - hw)...(15 + hw) { px(x, y, blue) }
            }
            // Helmet outline
            for y in 4...10 { px(16 - (y < 6 ? (y-3) : 5) - 1, y, dark); px(15 + (y < 6 ? (y-3) : 5) + 1, y, dark) }
            for x in 11...20 { px(x, 10, dark) }
            // Highlight on helmet top
            px(13, 5, highlight); px(14, 5, highlight); px(13, 6, highlight)

            // -- Visor --
            if facing == .down || facing == .left || facing == .right {
                let visorRow = 7
                // Visor slit
                for x in 12...19 { px(x, visorRow, dark) }
                // Glowing visor
                px(13, visorRow, visor); px(14, visorRow, visor)
                px(17, visorRow, visor); px(18, visorRow, visor)
                // Visor glow (brighter center)
                px(13, 8, SKColor(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.4))
                px(18, 8, SKColor(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.4))
                if facing == .left {
                    px(17, visorRow, dark); px(18, visorRow, dark)
                } else if facing == .right {
                    px(13, visorRow, dark); px(14, visorRow, dark)
                }
            } else {
                // Back of helmet - antenna/stripe
                for x in 14...17 { px(x, 7, armor) }
                px(15, 6, cyan); px(16, 6, cyan)
            }

            // -- Torso/Armor --
            for y in 11...18 {
                let hw = y < 14 ? 5 : (y < 17 ? 4 : 3)
                for x in (16 - hw)...(15 + hw) {
                    px(x, y, armor)
                }
            }
            // Chest plate center
            for y in 11...14 {
                for x in 13...18 { px(x, y, cyan) }
            }
            // Chest emblem - diamond
            px(15, 12, white); px(16, 12, white)
            px(14, 13, visor); px(15, 13, visor); px(16, 13, visor); px(17, 13, visor)
            px(15, 14, white); px(16, 14, white)
            // Armor outline
            for y in 11...18 {
                let hw = y < 14 ? 5 : (y < 17 ? 4 : 3)
                px(16 - hw - 1, y, dark)
                px(15 + hw + 1, y, dark)
            }
            // Belt
            for x in 12...19 { px(x, 17, dark) }
            px(15, 17, SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1)) // Belt buckle
            px(16, 17, SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1))

            // -- Shoulder pads --
            for y in 11...13 {
                px(9, y, blue); px(10, y, blue)
                px(21, y, blue); px(22, y, blue)
            }
            px(9, 11, highlight); px(22, 11, highlight)
            px(8, 12, dark); px(23, 12, dark)
            px(9, 14, dark); px(10, 14, dark)
            px(21, 14, dark); px(22, 14, dark)

            // -- Arms --
            for y in 14...17 {
                px(9, y, armor); px(10, y, armor)
                px(21, y, armor); px(22, y, armor)
            }
            // Hands
            px(9, 18, cyan); px(10, 18, cyan)
            px(21, 18, cyan); px(22, 18, cyan)

            // -- Legs with walk animation --
            let legShift = frame == 1 ? 1 : 0
            // Left leg
            for y in 19...24 {
                px(12 - legShift, y, blue)
                px(13 - legShift, y, blue)
                px(14 - legShift, y, armor)
            }
            // Right leg
            for y in 19...24 {
                px(17 + legShift, y, armor)
                px(18 + legShift, y, blue)
                px(19 + legShift, y, blue)
            }
            // Boots
            for x in (11 - legShift)...(14 - legShift) { px(x, 25, boot); px(x, 24, boot) }
            for x in (17 + legShift)...(20 + legShift) { px(x, 25, boot); px(x, 24, boot) }
            // Boot highlight
            px(11 - legShift, 24, armor)
            px(17 + legShift, 24, armor)

            // -- White outline for readability --
            // (Done by adding 1px white where transparent meets opaque - simplified version)

            // -- Hat overlay --
            switch hatId {
            case "hat_crown":
                let gold = ColorPalette.gold
                let goldDark = SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1)
                // Crown base
                for x in 12...19 { px(x, 2, gold) }
                for x in 12...19 { px(x, 3, goldDark) }
                // Crown points
                px(12, 0, gold); px(12, 1, gold)
                px(15, 0, gold); px(15, 1, gold); px(16, 0, gold); px(16, 1, gold)
                px(19, 0, gold); px(19, 1, gold)
                // Jewels
                px(14, 2, SKColor.red); px(17, 2, SKColor.blue)
            case "hat_halo":
                let haloColor = SKColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 0.8)
                let haloBright = SKColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.9)
                // Floating halo above head
                for x in 11...20 { px(x, 0, haloColor) }
                for x in 12...19 { px(x, 1, haloBright) }
                px(11, 1, haloColor); px(20, 1, haloColor)
            case "hat_horns":
                let hornColor = SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1)
                let hornDark = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1)
                // Left horn
                px(11, 3, hornColor); px(10, 2, hornColor); px(9, 1, hornDark); px(9, 0, hornDark)
                // Right horn
                px(20, 3, hornColor); px(21, 2, hornColor); px(22, 1, hornDark); px(22, 0, hornDark)
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

            // Head (rounded)
            for y in 4...11 {
                let hw = y < 6 ? (y - 3) : (y > 9 ? (11 - y + 1) : 4)
                for x in (15 - hw)...(16 + hw) {
                    px(x, y, body)
                }
                px(15 - hw - 1, y, outline)
                px(16 + hw + 1, y, outline)
            }
            for x in 12...19 { px(x, 3, outline) }
            for x in 12...19 { px(x, 12, outline) }

            // Sunken eyes
            px(12, 6, outline); px(13, 6, outline); px(14, 6, outline)
            px(17, 6, outline); px(18, 6, outline); px(19, 6, outline)
            px(12, 7, outline); px(13, 7, eyes); px(14, 7, eyes)
            px(17, 7, eyes); px(18, 7, eyes); px(19, 7, outline)
            px(12, 8, outline); px(13, 8, eyes); px(14, 8, outline)
            px(17, 8, outline); px(18, 8, eyes); px(19, 8, outline)

            // Mouth with teeth
            for x in 13...18 { px(x, 10, outline) }
            px(13, 10, teeth); px(15, 10, teeth); px(17, 10, teeth)
            px(14, 11, dark); px(15, 11, dark); px(16, 11, dark)

            // Body - hunched
            for y in 12...21 {
                let hw = y < 15 ? 5 : (y < 19 ? 6 : (6 - (y - 19)))
                for x in max(0, 15 - hw)...min(31, 16 + hw) {
                    px(x, y, flesh)
                }
            }
            // Belly wound
            for y in 15...17 {
                for x in 14...17 { px(x, y, dark) }
            }
            px(15, 16, SKColor(red: 0.5, green: 0.1, blue: 0.0, alpha: 1))

            // Arms reaching (animated)
            let armY = frame == 0 ? 0 : -2
            for y in (11 + armY)...(16 + armY) {
                px(6, y, flesh); px(7, y, flesh); px(8, y, flesh)
                px(23, y, flesh); px(24, y, flesh); px(25, y, flesh)
            }
            // Clawed hands
            px(5, 10 + armY, dark); px(6, 10 + armY, dark)
            px(25, 10 + armY, dark); px(26, 10 + armY, dark)
            px(4, 11 + armY, dark)
            px(27, 11 + armY, dark)

            // Legs (stumpy)
            let legS = frame == 1 ? 1 : 0
            for y in 22...25 {
                px(11 - legS, y, dark); px(12 - legS, y, flesh); px(13 - legS, y, flesh)
                px(18 + legS, y, flesh); px(19 + legS, y, flesh); px(20 + legS, y, dark)
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
            let eyes = SKColor.red
            let outline = SKColor(red: 0.4, green: 0.3, blue: 0.0, alpha: 1)

            // Compact body
            for y in 11...19 {
                let hw = y < 14 ? (y - 10) : (y > 17 ? (19 - y) : 4)
                for x in (15 - hw)...(16 + hw) { px(x, y, body) }
            }
            // Head (triangular, pointed)
            for y in 7...11 {
                let hw = y - 7
                for x in (15 - hw)...(16 + hw) { px(x, y, body) }
            }
            // Horns
            px(13, 5, dark); px(12, 4, dark); px(11, 3, outline)
            px(18, 5, dark); px(19, 4, dark); px(20, 3, outline)

            // Angry eyes
            px(13, 10, eyes); px(14, 10, eyes)
            px(17, 10, eyes); px(18, 10, eyes)
            px(13, 11, SKColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1))
            px(18, 11, SKColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1))
            // Fangs
            px(14, 13, SKColor.white); px(17, 13, SKColor.white)

            // Wings (large, animated)
            let wingUp = frame == 0
            let wingBaseY = wingUp ? 8 : 12
            // Left wing
            for y in wingBaseY...(wingBaseY + 7) {
                let span = max(0, 7 - abs(y - (wingBaseY + 3)))
                for x in (10 - span)...10 {
                    if x >= 0 { px(x, y, wing) }
                }
                if 10 - span - 1 >= 0 { px(10 - span - 1, y, wingDark) }
            }
            // Right wing
            for y in wingBaseY...(wingBaseY + 7) {
                let span = max(0, 7 - abs(y - (wingBaseY + 3)))
                for x in 21...(21 + span) {
                    if x < 32 { px(x, y, wing) }
                }
                if 21 + span + 1 < 32 { px(21 + span + 1, y, wingDark) }
            }
            // Wing membrane lines
            for i in 0..<4 {
                let y = wingBaseY + 1 + i * 2
                px(10 - i, y, outline)
                px(21 + i, y, outline)
            }

            // Tail
            for y in 20...24 {
                let shift = (y - 20) % 2 == 0 ? 0 : (frame == 0 ? 1 : -1)
                px(15 + shift, y, dark); px(16 + shift, y, dark)
            }
            px(15, 25, outline)
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
            // Robe hem
            for x in 6...25 {
                px(x, 26, dark)
                if x % 3 == 0 { px(x, 27, dark) }
            }

            // Staff in right hand
            let staffShift = frame == 1 ? -1 : 0
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

            // Left arm (under robe)
            for y in 13...17 {
                px(7, y, robe); px(8, y, robe)
            }
            px(6, 17, robe); px(7, 18, dark) // Reaching hand
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

            let pulse = frame == 1 ? 1 : 0

            // Spherical bomb body
            let cx = 15, cy = 14
            let r = 9 + pulse
            for y in (cy - r)...(cy + r) {
                for x in (cx - r)...(cx + r) {
                    let dx = x - cx, dy = y - cy
                    let distSq = dx * dx + dy * dy
                    if distSq <= r * r && x >= 0 && x < 32 && y >= 0 && y < 32 {
                        // Gradient: darker at edges
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

            // Glowing cracks
            let crackColor = frame == 1 ? glow : hot
            for i in 0..<4 {
                let angle = CGFloat(i) * .pi / 2 + 0.3
                for j in 3...6 {
                    let x = cx + Int(cos(angle) * CGFloat(j))
                    let y = cy + Int(sin(angle) * CGFloat(j))
                    px(x, y, crackColor)
                }
            }

            // Hot inner core
            let ir = 3 + pulse
            for y in (cy - ir)...(cy + ir) {
                for x in (cx - ir)...(cx + ir) {
                    let dx = x - cx, dy = y - cy
                    if dx * dx + dy * dy <= ir * ir {
                        px(x, y, hot)
                    }
                }
            }
            // Bright center
            px(cx, cy, core); px(cx + 1, cy, core)
            px(cx, cy + 1, core); px(cx + 1, cy + 1, core)

            // Eyes (angry, on top)
            px(12, 11, eyes); px(13, 11, eyes)
            px(18, 11, eyes); px(19, 11, eyes)
            // Angry eyebrows
            px(11, 10, dark); px(12, 10, dark)
            px(19, 10, dark); px(20, 10, dark)

            // Fuse on top
            px(15, cy - r - 1, shell); px(16, cy - r - 1, shell)
            px(15, cy - r - 2, glow); px(16, cy - r - 2, glow)
            // Sparks
            if frame == 1 {
                px(14, cy - r - 3, core); px(17, cy - r - 3, core)
                px(15, cy - r - 4, SKColor.white)
            }

            // Tiny feet
            let legS = frame == 1 ? 1 : 0
            px(11 - legS, cy + r + 1, body); px(12 - legS, cy + r + 1, body)
            px(19 + legS, cy + r + 1, body); px(20 + legS, cy + r + 1, body)
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
            // Center robe detail
            for y in 16...30 { px(19, y, robeDark); px(20, y, robeDark) }

            // Raised arms (animated)
            let armUp = frame == 1 ? 3 : 0
            for y in (10 - armUp)...(20 - armUp) {
                px(5, y, robe); px(6, y, robe); px(7, y, robe)
                px(32, y, robe); px(33, y, robe); px(34, y, robe)
            }
            // Skeletal hands with magic
            px(4, 9 - armUp, skull); px(5, 9 - armUp, skull)
            px(34, 9 - armUp, skull); px(35, 9 - armUp, skull)
            // Magic particles from hands
            let magicY = 7 - armUp
            if magicY >= 0 {
                px(4, magicY, magic); px(5, magicY, magic)
                px(35, magicY, magic); px(34, magicY, magic)
                if frame == 1 {
                    px(3, magicY - 1, SKColor(red: 1, green: 0, blue: 1, alpha: 0.5))
                    px(36, magicY - 1, SKColor(red: 1, green: 0, blue: 1, alpha: 0.5))
                }
            }

            // Floating mini-skulls
            let skullY = frame == 0 ? 4 : 7
            for offset in [2, 37] {
                px(offset, skullY, skull); px(offset + 1, skullY, skull)
                px(offset, skullY + 1, skull); px(offset + 1, skullY + 1, skull)
                px(offset, skullY + 1, skullDark) // Shading
                // Mini eye
                px(offset, skullY, eyes)
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
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
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
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
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
                case .rewindExtension:
                    let ctr = 12
                    for angle in stride(from: 0.0, through: 2.0 * .pi, by: 0.15) {
                        let ox = ctr + Int(cos(angle) * 7)
                        let oy = ctr + Int(sin(angle) * 7)
                        px(ox, oy, ic)
                    }
                    for y in 8...12 { px(12, y, ic) }
                    for x in 12...15 { px(x, 12, ic) }
                    px(7,4,iconColor); px(8,5,iconColor); px(9,6,iconColor)

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
