import SwiftUI

public extension DX {
    /// Text roles from before v4, still named by `v4Text` and `onbText`, which map each role onto one of the
    /// seven v4 steps (`DX.TypeStep`). Their old Inter sizes are gone (Phase 8).
    enum TextStyle: CaseIterable, Sendable {
        case hero, heroDenominator, title, cardHeading, body, subtitle, micro, button
    }
}
