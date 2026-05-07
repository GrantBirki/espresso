# AGENTS.md

This is a Swift-based macOS menu bar app that keeps the display awake, which also prevents idle system sleep, for a user-selected duration.

## Goals

- Keep the app simple: menu bar controls, fixed durations, launch at login, and no cloud service.
- Use native IOKit power assertions instead of shelling out to `caffeinate`.
- Provide a polished macOS 26 experience with restrained Liquid Glass in settings and about surfaces.
- Follow the same open-source project discipline as OneShot and Shit: SwiftPM, XcodeGen, scripts to rule them all, GitHub Actions, zipped app releases, and Homebrew cask installation.

## Development Flow

- Bootstrap: `script/bootstrap`
- Update generated Xcode project: `script/update`
- Build: `script/build`
- Test: `script/test`
- Lint: `script/lint`
- Package: `script/package`
- Run locally: `script/server`

All common work should go through the scripts under `script/`.

## Code Standards

1. Follow Swift best practices and idiomatic macOS patterns.
2. Keep power-management behavior testable behind protocols.
3. Prefer simple native AppKit/SwiftUI components over custom infrastructure.
4. Use Liquid Glass intentionally for functional hierarchy, not decoration.
5. Add or update unit tests for behavior changes.
6. Update `docs/settings.md` when settings or setting-linked behavior changes.
7. Do not copy Caffeine source, assets, localizations, or strings.
