import Foundation
import IOKit.pwr_mgt

final class IOKitSleepAssertionClient: SleepAssertionClient {
    func createAssertion(duration: AwakeDuration) -> Result<SleepAssertionIdentifier, SleepAssertionError> {
        var assertionID: IOPMAssertionID = 0
        let timeout = duration.seconds ?? 0
        let name = "Espresso keeps your Mac awake" as CFString
        let details = "Espresso is active for \(duration.menuTitle)." as CFString
        let result = IOPMAssertionCreateWithDescription(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            name,
            details,
            name,
            nil as CFString?,
            timeout,
            nil as CFString?,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            AppLog.power.error("Power assertion create failed: \(result, privacy: .public)")
            return .failure(SleepAssertionError(code: result))
        }

        AppLog.power.info("Power assertion created: \(assertionID, privacy: .public)")
        return .success(assertionID)
    }

    func releaseAssertion(_ assertion: SleepAssertionIdentifier) -> Bool {
        let result = IOPMAssertionRelease(assertion)
        switch result {
        case kIOReturnSuccess:
            AppLog.power.info("Power assertion released: \(assertion, privacy: .public)")
            return true
        case kIOReturnNotFound, kIOReturnBadArgument, kIOReturnNotPermitted:
            // The ID no longer exists or belongs to another process.
            return true
        default:
            AppLog.power.error("Power assertion release failed: \(result, privacy: .public)")
            return false
        }
    }
}
