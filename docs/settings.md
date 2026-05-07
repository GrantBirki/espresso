# Espresso Settings

Espresso keeps settings intentionally small.

## Launch at Login

When enabled, Espresso registers itself with macOS using `SMAppService.mainApp`. macOS may require approval from System Settings.

## Session Persistence

Active awake sessions are not restored after quitting or relaunching Espresso. This is deliberate: a new power assertion is created only when you choose a duration from the menu.

## Power Behavior

Espresso uses `kIOPMAssertionTypePreventUserIdleDisplaySleep`, which prevents the display from dimming due to idle time. That also prevents idle system sleep while the assertion is active.
