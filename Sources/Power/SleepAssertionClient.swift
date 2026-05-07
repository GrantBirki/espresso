import Foundation

typealias SleepAssertionIdentifier = UInt32

struct SleepAssertionError: Error, Equatable {
    let code: Int32

    var userMessage: String {
        "Unable to start"
    }
}

protocol SleepAssertionClient {
    func createAssertion(duration: AwakeDuration) -> Result<SleepAssertionIdentifier, SleepAssertionError>
    func releaseAssertion(_ assertion: SleepAssertionIdentifier)
}
