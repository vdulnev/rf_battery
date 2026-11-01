# RFBattery

A tiny macOS menu-bar app that shows the battery level of a Keychron wireless
mouse connected through a **Keychron Link** 2.4 GHz dongle.

Tested with a Keychron M6 (`3434:d03f`) on a Keychron Link receiver (`3434:d030`).

## Install

Download `RFBattery.zip` from the
[latest release](https://github.com/vdulnev/rf_battery/releases/latest),
unzip it and move `RFBattery.app` to `/Applications`. It is a universal binary
(Apple Silicon and Intel).

The app is ad-hoc signed, not notarized, so macOS blocks the first launch.
Either right-click the app → **Open** → **Open**, or run:

```bash
xattr -dr com.apple.quarantine /Applications/RFBattery.app
```

## Releasing

Push a version tag; GitHub Actions builds the app and attaches the zip to a
release:

```bash
git tag v0.1.0 && git push origin v0.1.0
```

The workflow can also be run manually from the Actions tab; the zip is then
available as a build artifact.

## Build & run

Requires macOS 13+ and the Swift toolchain (Xcode or Command Line Tools).

```bash
./build_app.sh
open build/RFBattery.app
```

To start it automatically, add `build/RFBattery.app` under
**System Settings → General → Login Items**.

## How it works

The dongle exposes a vendor HID interface (usage page `0x8C`). Keychron's web
launcher queries the mouse by sending feature report `0x51` and reading it back,
but on macOS the dongle stalls every feature-report read (`0xe0005000`), even for
the launcher itself in Chrome.

The mouse does, however, push an unsolicited status report on input report
`0x54` whenever its state changes (DPI button, wake, etc.):

```
54 e2 01 01 00 5a 02 00 ...
   │  │  │  │  │  │  └ polling-rate level
   │  │  │  │  │  └─── DPI level
   │  │  │  │  └────── battery % (0x5a = 90)
   │  │  │  └───────── charge state (0 = discharging)
   │  │  └──────────── connected
   │  └─────────────── work mode (1 = via dongle)
   └────────────────── status tag
```

RFBattery listens for these reports and remembers the last value between
launches.

## Limitations

- The value only updates when the mouse sends a status report. If it looks
  stale, press the DPI button once.
- Only the Keychron Link dongle with this report layout is supported; other
  Keychron receivers (e.g. the 8K Ultra-Link) use different protocols.

## License

[MIT](LICENSE)
