import Testing
@testable import Headroom

/// The license on the Acknowledgments page reflows to the screen instead of keeping the
/// file's hard line breaks, which would wrap raggedly on a phone.
@Suite("Acknowledgments")
struct AcknowledgmentsTests {
    @Test("hard-wrapped lines join into paragraphs")
    func joinsParagraphs() {
        #expect(AcknowledgmentsView.reflow("The goals are\nto share.") == "The goals are to share.")
        #expect(AcknowledgmentsView.reflow("embedded, \nredistributed") == "embedded, redistributed")
    }

    @Test("blank lines, headings, and rules keep their own lines")
    func keepsStructure() {
        let text = "Intro one\nintro two\n\n\n---\nTITLE Version 1.1\n---\n\nPREAMBLE\nThe goals are\nto share.\n\n1) First\nitem.\n"
        #expect(AcknowledgmentsView.reflow(text)
            == "Intro one intro two\n\n\n---\nTITLE Version 1.1\n---\n\nPREAMBLE\nThe goals are to share.\n\n1) First item.\n")
    }
}
