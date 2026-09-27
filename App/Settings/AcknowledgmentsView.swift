import SwiftUI

/// Settings > Acknowledgments (docs/REDESIGN-SPEC.md 5.5): the typeface credit, then the
/// bundled license file.
struct AcknowledgmentsView: View {
    private var credit: Typography.Credit { Typography.credit }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(credit.typeface)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(credit.license)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                if let license = credit.licenseText {
                    Text(Self.reflow(license))
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .scenePadding(.horizontal)
            .padding(.top, Theme.Space.s)
            .padding(.bottom, Theme.Space.xxl)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Joins the license file's hard-wrapped lines so paragraphs wrap to the screen. Blank
    /// lines stay, and a line with no lowercase letters (a heading or a rule) keeps its own line.
    /// Only line breaks change; the words are exactly as shipped.
    nonisolated static func reflow(_ text: String) -> String {
        var lines: [String] = []
        for raw in text.components(separatedBy: "\n") {
            var line = raw
            while line.last?.isWhitespace == true { line.removeLast() }
            if let last = lines.last, !last.isEmpty, !line.isEmpty,
               last.contains(where: \.isLowercase), line.contains(where: \.isLowercase) {
                lines[lines.count - 1] = last + " " + line
            } else {
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n")
    }
}
