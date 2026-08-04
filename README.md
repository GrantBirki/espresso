# Espresso

[![build](https://github.com/GrantBirki/espresso/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/espresso/actions/workflows/build.yml)
[![test](https://github.com/GrantBirki/espresso/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/espresso/actions/workflows/test.yml)
[![lint](https://github.com/GrantBirki/espresso/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/espresso/actions/workflows/lint.yml)
[![release](https://github.com/GrantBirki/espresso/actions/workflows/release.yml/badge.svg)](https://github.com/GrantBirki/espresso/actions/workflows/release.yml)

Espresso is a native macOS menu bar app that keeps your Mac awake for a chosen amount of time.

It is intentionally small: choose 15 minutes, 30 minutes, 1 hour, 2 hours, 3 hours, 4 hours, 5 hours, 8 hours, 12 hours, or indefinitely from the menu bar. Espresso keeps the display awake, which also prevents idle system sleep, until the timer ends or you stop it.

Espresso is local-only. It has no cloud service, no telemetry, no updater, and no external credentials.

Requires macOS Tahoe 26 or later.

## Installation

Homebrew (recommended):

```bash
brew install --cask grantbirki/tap/espresso
```

## Features

- Menu bar controls for fixed awake durations.
- Indefinite awake mode.
- Native macOS power assertions through IOKit.
- Launch at login setting.
- Liquid Glass settings and about windows for macOS 26.

## Usage

- End-user guide: [docs/usage.md](docs/usage.md)
- Settings reference: [docs/settings.md](docs/settings.md)

## Verify Releases

Release artifacts are published with SLSA provenance. After downloading `Espresso.zip`:

```bash
gh attestation verify Espresso.zip \
  --repo grantbirki/espresso \
  --signer-workflow grantbirki/espresso/.github/workflows/release.yml \
  --source-ref refs/heads/main \
  --deny-self-hosted-runners
```

Minimal verification by owner:

```bash
gh attestation verify Espresso.zip --owner grantbirki
```

You can also verify the checksum:

```bash
shasum -a 256 Espresso.zip
```

## Current v0.1.x Release

Espresso v0.1.x releases are unsigned. macOS Gatekeeper may block the first launch. The planned v0.2.0 release will be signed and notarized with an Apple Developer ID certificate.

To open it:

1. Right-click `Espresso.app` and choose Open.
2. Or go to System Settings -> Privacy & Security and click Open Anyway.

Do not clear the app's quarantine attribute; use macOS's explicit approval flow instead.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
