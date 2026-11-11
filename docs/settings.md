# Espresso Settings

Espresso keeps settings intentionally small.

## Launch at Login

When enabled, Espresso registers itself with macOS using `SMAppService.mainApp`. macOS may require approval from System Settings; Espresso shows a reminder while approval is pending. The switch stays on for a registered item awaiting approval.

Espresso checks the macOS registration status after each change and when Settings opens. If a change fails, the switch and saved setting reflect the registration that remains in macOS, and Espresso shows an error so you can retry.

## Session Persistence

Active awake sessions are not restored after quitting or relaunching Espresso. This is deliberate: a new power assertion is created only when you choose a duration from the menu.

## Power Behavior

Espresso uses `kIOPMAssertionTypePreventUserIdleDisplaySleep`, which prevents the display from dimming due to idle time. That also prevents idle system sleep while the assertion is active.

Thermal protection is always on. When macOS reports serious or critical thermal pressure, Espresso releases its power assertion and blocks new sessions. Once the Mac cools down, you can choose a duration to start again.
