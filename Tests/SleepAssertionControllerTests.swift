import CoreFoundation
@testable import Espresso
import Foundation
import XCTest

@MainActor
final class SleepAssertionControllerTests: XCTestCase {
    func testStartCreatesAssertionAndSession() {
        let client = FakeSleepAssertionClient()
        let uptime: TimeInterval = 1000
        let controller = EspressoController(assertionClient: client, uptime: { uptime }, thermalState: { .nominal })
        defer { controller.stop() }

        controller.start(duration: .fifteenMinutes)

        XCTAssertEqual(client.createdDurations, [.fifteenMinutes])
        XCTAssertEqual(controller.session, AwakeSession(duration: .fifteenMinutes, startUptime: uptime))
        XCTAssertNil(controller.lastError)
    }

    func testStartReleasesExistingAssertionBeforeReplacement() {
        let client = FakeSleepAssertionClient()
        let controller = EspressoController(assertionClient: client, thermalState: { .nominal })
        defer { controller.stop() }

        controller.start(duration: .fifteenMinutes)
        controller.start(duration: .oneHour)

        XCTAssertEqual(client.createdDurations, [.fifteenMinutes, .oneHour])
        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertEqual(controller.session?.duration, .oneHour)
    }

    func testStopReleasesAssertionAndClearsSession() {
        let client = FakeSleepAssertionClient()
        let controller = EspressoController(assertionClient: client, thermalState: { .nominal })

        controller.start(duration: .thirtyMinutes)
        controller.stop()

        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertNil(controller.session)
        XCTAssertNil(controller.lastError)
    }

    func testExpiryReleasesAssertion() {
        let client = FakeSleepAssertionClient()
        let startUptime: TimeInterval = 1000
        let controller = EspressoController(
            assertionClient: client, uptime: { startUptime }, thermalState: { .nominal }
        )

        controller.start(duration: .fifteenMinutes)
        controller.expireIfNeeded(at: startUptime + 900)

        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertNil(controller.session)
    }

    func testCreateFailureLeavesInactiveState() {
        let client = FakeSleepAssertionClient()
        client.nextResult = .failure(SleepAssertionError(code: -1))
        let controller = EspressoController(assertionClient: client, thermalState: { .nominal })

        controller.start(duration: .fifteenMinutes)

        XCTAssertNil(controller.session)
        XCTAssertEqual(controller.lastError, SleepAssertionError(code: -1))
        XCTAssertEqual(controller.menuBarState().statusTitle, "Unable to start")
        XCTAssertTrue(client.releasedAssertions.isEmpty)
    }

    func testClockAdvanceDoesNotEndSessionEarly() {
        let client = FakeSleepAssertionClient()
        var date = Date(timeIntervalSince1970: 1_800_000_000)
        let controller = EspressoController(
            assertionClient: client, now: { date }, uptime: { 1000 }, thermalState: { .nominal }
        )
        defer { controller.stop() }

        controller.start(duration: .fifteenMinutes)
        date = date.addingTimeInterval(3600)
        controller.expireIfNeeded()

        XCTAssertNotNil(controller.session)
        XCTAssertTrue(client.releasedAssertions.isEmpty)
        XCTAssertEqual(controller.menuBarState().statusTitle, "On: 15m remaining")
    }

    func testClockRollbackDoesNotDelayExpiry() {
        let client = FakeSleepAssertionClient()
        var date = Date(timeIntervalSince1970: 1_800_000_000)
        var uptime: TimeInterval = 1000
        let controller = EspressoController(
            assertionClient: client, now: { date }, uptime: { uptime }, thermalState: { .nominal }
        )
        defer { controller.stop() }

        controller.start(duration: .fifteenMinutes)
        date = date.addingTimeInterval(-3600)
        uptime += 900
        controller.expireIfNeeded()

        XCTAssertNil(controller.session)
        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertEqual(controller.menuBarState().statusTitle, "Espresso is off")
    }

    func testExpiryTimerReleasesAssertionDuringMenuTracking() {
        let client = FakeSleepAssertionClient()
        // Start at 1000, then schedule the deadline as if only 0.1 seconds remain.
        var uptimes = [1000.0, 1899.9].makeIterator()
        let controller = EspressoController(
            assertionClient: client, uptime: { uptimes.next() ?? 1900 }, thermalState: { .nominal }
        )
        defer { controller.stop() }

        // A common mode models the nested run loop used while an NSMenu is open.
        let trackingMode = RunLoop.Mode("EspressoTests.menuTracking")
        var commonMode: CFRunLoopMode?
        let captureMode = Timer(fire: Date(), interval: 0, repeats: false) { _ in
            MainActor.assumeIsolated {
                commonMode = CFRunLoopCopyCurrentMode(CFRunLoopGetMain())
            }
        }
        RunLoop.main.add(captureMode, forMode: trackingMode)
        _ = RunLoop.main.run(mode: trackingMode, before: Date().addingTimeInterval(1))
        guard let commonMode else {
            XCTFail("Unable to capture the tracking run-loop mode")
            return
        }
        CFRunLoopAddCommonMode(CFRunLoopGetMain(), commonMode)
        let deadline = Date().addingTimeInterval(2)
        let keepAlive = Timer(fire: deadline, interval: 0, repeats: false) { _ in }
        RunLoop.main.add(keepAlive, forMode: trackingMode)
        defer { keepAlive.invalidate() }

        controller.start(duration: .fifteenMinutes)
        while controller.session != nil, Date() < deadline {
            _ = RunLoop.main.run(mode: trackingMode, before: deadline)
        }

        XCTAssertNil(controller.session)
        XCTAssertEqual(client.releasedAssertions, [1])
    }

    func testRepeatedStopReleasesAssertionOnce() {
        let client = FakeSleepAssertionClient()
        let controller = EspressoController(assertionClient: client, thermalState: { .nominal })

        controller.start(duration: .indefinitely)
        controller.stop()
        controller.stop()

        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertNil(controller.session)
    }

    func testIndefiniteSessionDoesNotPublishPeriodicUpdates() {
        let controller = EspressoController(assertionClient: FakeSleepAssertionClient(), thermalState: { .nominal })
        defer { controller.stop() }
        var changes = 0
        controller.onStateChange = { changes += 1 }

        controller.start(duration: .indefinitely)
        RunLoop.main.run(until: Date().addingTimeInterval(1.2))

        XCTAssertEqual(changes, 1)
    }

    func testExpiryCheckDoesNotStopReplacementSession() {
        let client = FakeSleepAssertionClient()
        var uptime: TimeInterval = 1000
        let controller = EspressoController(assertionClient: client, uptime: { uptime }, thermalState: { .nominal })
        defer { controller.stop() }

        controller.start(duration: .fifteenMinutes)
        uptime += 899
        controller.start(duration: .oneHour)
        uptime += 1
        controller.expireIfNeeded()

        XCTAssertEqual(controller.session?.duration, .oneHour)
        XCTAssertEqual(client.releasedAssertions, [1])
    }

    func testNewAndReplacementSessionsCheckCurrentThermalState() {
        let client = FakeSleepAssertionClient()
        var pressure = ProcessInfo.ThermalState.critical
        let controller = EspressoController(
            assertionClient: client, thermalState: { pressure }, notificationCenter: NotificationCenter()
        )

        controller.start(duration: .oneHour)
        XCTAssertTrue(client.createdDurations.isEmpty)
        XCTAssertEqual(controller.menuBarState().statusTitle, "Off until your Mac cools down")

        pressure = .fair
        controller.start(duration: .oneHour)
        XCTAssertEqual(controller.session?.duration, .oneHour)

        pressure = .serious
        controller.start(duration: .indefinitely)
        XCTAssertNil(controller.session)
        XCTAssertEqual(client.createdDurations, [.oneHour])
        XCTAssertEqual(client.releasedAssertions, [1])
    }

    func testThermalNotificationsStopSessionsAndCoolingDoesNotRestartThem() {
        let scenarios: [(AwakeDuration, ProcessInfo.ThermalState)] = [(.oneHour, .serious), (.indefinitely, .critical)]
        for (duration, hotState) in scenarios {
            let client = FakeSleepAssertionClient()
            let center = NotificationCenter()
            var pressure = ProcessInfo.ThermalState.nominal
            let controller = EspressoController(
                assertionClient: client, thermalState: { pressure }, notificationCenter: center
            )
            controller.start(duration: duration)

            let stopped = expectation(description: "Session stops on thermal notification")
            controller.onStateChange = { stopped.fulfill() }
            pressure = hotState
            center.post(name: ProcessInfo.thermalStateDidChangeNotification, object: ProcessInfo.processInfo)
            wait(for: [stopped], timeout: 2)
            XCTAssertNil(controller.session)
            XCTAssertEqual(client.releasedAssertions, [1])
            XCTAssertEqual(controller.menuBarState().statusTitle, "Off until your Mac cools down")

            let cooled = expectation(description: "Thermal restriction clears")
            controller.onStateChange = { cooled.fulfill() }
            pressure = .fair
            center.post(name: ProcessInfo.thermalStateDidChangeNotification, object: ProcessInfo.processInfo)
            wait(for: [cooled], timeout: 2)
            XCTAssertEqual(controller.menuBarState().statusTitle, "Espresso is off")
            XCTAssertEqual(client.createdDurations, [duration])
        }
    }
}

private final class FakeSleepAssertionClient: SleepAssertionClient {
    var nextResult: Result<SleepAssertionIdentifier, SleepAssertionError>?
    private var nextAssertion: SleepAssertionIdentifier = 1
    private(set) var createdDurations: [AwakeDuration] = []
    private(set) var releasedAssertions: [SleepAssertionIdentifier] = []

    func createAssertion(duration: AwakeDuration) -> Result<SleepAssertionIdentifier, SleepAssertionError> {
        createdDurations.append(duration)
        if let nextResult {
            self.nextResult = nil
            return nextResult
        }

        defer { nextAssertion += 1 }
        return .success(nextAssertion)
    }

    func releaseAssertion(_ assertion: SleepAssertionIdentifier) {
        releasedAssertions.append(assertion)
    }
}
