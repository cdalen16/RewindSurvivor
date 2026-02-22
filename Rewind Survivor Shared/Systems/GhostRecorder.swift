import SpriteKit

struct PlayerSnapshot {
    var position: CGPoint
    var facingDirection: CGVector
    var isFiring: Bool
    var timestamp: TimeInterval
}

struct GhostRecording {
    let snapshots: [PlayerSnapshot]
    var duration: TimeInterval {
        guard let last = snapshots.last, let first = snapshots.first else { return 0 }
        return last.timestamp - first.timestamp
    }
}

class GhostRecorder {
    private var buffer: [PlayerSnapshot]
    private var writeIndex: Int = 0
    private var count: Int = 0
    private var lastRecordTime: TimeInterval = 0
    private let interval: TimeInterval = GameConfig.snapshotInterval
    private var maxSnapshots: Int

    init() {
        maxSnapshots = GameConfig.maxSnapshots
        buffer = Array(repeating: PlayerSnapshot(
            position: .zero,
            facingDirection: CGVector(dx: 0, dy: -1),
            isFiring: false,
            timestamp: 0
        ), count: maxSnapshots)
    }

    func record(player: PlayerNode, gameTime: TimeInterval, isFiring: Bool) {
        guard gameTime - lastRecordTime >= interval else { return }
        lastRecordTime = gameTime

        buffer[writeIndex] = PlayerSnapshot(
            position: player.position,
            facingDirection: player.facingDirection,
            isFiring: isFiring,
            timestamp: gameTime
        )
        writeIndex = (writeIndex + 1) % maxSnapshots
        count = min(count + 1, maxSnapshots)
    }

    func extractRecording() -> GhostRecording {
        guard count > 0 else {
            return GhostRecording(snapshots: [])
        }

        var snapshots: [PlayerSnapshot] = []
        snapshots.reserveCapacity(count)

        let startIndex: Int
        if count < maxSnapshots {
            startIndex = 0
        } else {
            startIndex = writeIndex // oldest entry in ring buffer
        }

        for i in 0..<count {
            let idx = (startIndex + i) % maxSnapshots
            snapshots.append(buffer[idx])
        }

        // Normalize timestamps to start at 0
        if let firstTimestamp = snapshots.first?.timestamp {
            for i in 0..<snapshots.count {
                snapshots[i].timestamp -= firstTimestamp
            }
        }

        return GhostRecording(snapshots: snapshots)
    }

    func reset() {
        writeIndex = 0
        count = 0
        lastRecordTime = 0
    }
}
