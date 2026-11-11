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

Espresso starts a macOS power assertion when thermal conditions allow. While the assertion is active, macOS should not dim the display due to idle time, and the Mac should not enter idle system sleep.

The countdown measures elapsed system uptime, matching the power assertion's timeout. Changing the clock does not change the remaining duration, and time spent asleep does not count toward it.

## Replace a Session

Choose another duration from the menu. Espresso stops the old assertion and starts a new one.

## Stop a Session

Click the Espresso menu bar icon and choose `Stop Espresso`.

## Limits

Espresso prevents idle sleep. It does not override lid close, explicit Sleep from the Apple menu, low battery, or thermal emergency sleep.

If macOS reports serious or critical thermal pressure, Espresso ends the session and the menu shows `Off until your Mac cools down`. This also applies to indefinite sessions. Once macOS reports fair or nominal thermal pressure, choose a duration to start a new session.

## Check thermal stops

To see when Espresso stopped a session because of heat, run this in Terminal.

```sh
/usr/bin/log show --last 7d --style compact --predicate 'subsystem == "io.birki.espresso" AND category == "thermal"'
```

Each entry includes the time and the thermal pressure macOS reported. A stop is confirmed when the entry says Espresso no longer holds its keep-awake assertion. If release is unconfirmed, Espresso records that once and logs confirmation when a retry succeeds.

The query shows entries macOS still retains from the past seven days. Older entries can expire sooner. For a development build, use `io.birki.espresso.dev` as the subsystem.
