import HeadroomCore
import SwiftUI

extension EnvironmentValues {
    /// The current calendar day. RootView refreshes it at midnight and on return to the app,
    /// so a balance confirmed yesterday shows as stale without a relaunch.
    @Entry var today: LocalDate = .today()
}

extension Binding where Value == Bool {
    /// A toggle bound to whether `id` is in `set`.
    static func member<ID: Hashable & Sendable>(_ set: Binding<Set<ID>>, _ id: ID) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(id) },
            set: { isOn in
                if isOn { set.wrappedValue.insert(id) } else { set.wrappedValue.remove(id) }
            }
        )
    }
}
