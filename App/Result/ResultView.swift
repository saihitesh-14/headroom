import HeadroomCore
import SwiftUI

/// Placeholder until Task 10.
struct ResultView: View {
    let initialPurchase: Purchase

    var body: some View {
        Text(initialPurchase.price.formatted)
            .navigationTitle("Result")
    }
}
