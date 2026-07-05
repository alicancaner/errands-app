import Foundation

/// What the engine should do about a geofence entry event.
public enum NotificationDecision: Equatable, Sendable {
    case notifyNow
    case plantInner
    case suppress
}

/// Decides how to react when the phone enters a store's geofence.
///
/// Decision table (DESIGN.md §3, tuned by Gate D/F field notes):
/// completed errand → suppress; within cooldown → suppress (even the inner
/// plant — its later entry would be suppressed anyway); inner ring → notify;
/// outer ring → notify when driving, otherwise plant the inner ring and wait.
public enum NotificationPolicy {

    /// Minimum time between notifications for the same store+errand.
    public static let cooldown: TimeInterval = 2 * 60 * 60

    /// Decides `notifyNow` / `plantInner` / `suppress` for one entry event.
    ///
    /// - Parameters:
    ///   - ring: which ring was entered.
    ///   - isDriving: motion snapshot; callers must map none/unknown to
    ///     `false` (Gate F: safe default is "not driving").
    ///   - errandCompleted: whether the errand is already done.
    ///   - lastNotifiedAt: when this store+errand pair last notified, if ever.
    ///   - remindWhenDriving: per-store user toggle; false silences this
    ///     store while driving.
    ///   - remindWhenWalking: per-store user toggle; false silences this
    ///     store while not driving (also skips pointless inner planting).
    ///   - now: current time (injected for testability).
    public static func decide(
        ring: RingKind,
        isDriving: Bool,
        errandCompleted: Bool,
        lastNotifiedAt: Date?,
        remindWhenDriving: Bool = true,
        remindWhenWalking: Bool = true,
        now: Date
    ) -> NotificationDecision {
        if errandCompleted {
            return .suppress
        }
        if let lastNotifiedAt, now.timeIntervalSince(lastNotifiedAt) < cooldown {
            return .suppress
        }
        if isDriving && !remindWhenDriving {
            return .suppress
        }
        if !isDriving && !remindWhenWalking {
            return .suppress
        }
        switch ring {
        case .inner:
            return .notifyNow
        case .outer:
            return isDriving ? .notifyNow : .plantInner
        }
    }
}
