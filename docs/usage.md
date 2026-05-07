# Espresso Usage

Espresso lives in the macOS menu bar.

## Start a Session

1. Click the Espresso menu bar icon.
2. Choose a duration:
   - 15 minutes
   - 30 minutes
   - 1 hour
   - 2 hours
   - 3 hours
   - 4 hours
   - 5 hours
   - 8 hours
   - 12 hours
   - Indefinitely

Espresso immediately starts a macOS power assertion. While the assertion is active, macOS should not dim the display due to idle time, and the Mac should not enter idle system sleep.

## Replace a Session

Choose another duration from the menu. Espresso stops the old assertion and starts a new one.

## Stop a Session

Click the Espresso menu bar icon and choose `Stop Espresso`.

## Limits

Espresso prevents idle sleep. It does not override lid close, explicit Sleep from the Apple menu, low battery, or thermal emergency sleep.
