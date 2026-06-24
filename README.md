# FidgetBall

A tiny open-source macOS menu-bar app: a physics ball hangs on a rope from your
menu bar and floats over your desktop. Drag it, fling it, watch it swing and
bounce, slash the rope to cut it loose — then bump the freed ball like a
volleyball. It lives quietly in the background until you want to play.

Somewhere low-stakes to put restless hands while the rest of your attention
stays on the work in front of you.

## Features

- **Rope physics** — gravity, swing, drag, throw, and cut-the-rope, on a custom
  Verlet simulation.
- **Slash to cut** — drag the cursor through the rope to sever it.
- **Volleyball mode** — tap a cut ball to knock it upward (hit it off-centre to
  angle it); miss it and it falls off the bottom of the screen.
- **Stays out of your way** — a transparent, click-through overlay that never
  steals focus and only intercepts clicks when you're actually touching the ball.
- **Six skins** — smiley, basketball, tennis, marble, football, disco, all drawn
  procedurally (no image assets).
- **Settings** — live, persisted sliders for gravity, bounciness, air resistance,
  throw power, spin, ball size, rope length, stiffness, wall friction, and bump
  power, plus a haptics toggle.
- **Global hot key** — ⌥F to show/hide instantly. Optional haptic feedback on impact.

## Controls

| Action | Gesture |
|--------|---------|
| Throw the ball | Drag it and let go |
| Cut the rope | Drag the cursor across the rope (cursor turns to a crosshair) |
| Bump a cut ball | Tap it (off-centre hits angle it) |
| New ball | Left-click the menu-bar icon |
| Show / hide | ⌥F |
| Skins · cut · settings · quit | Right-click the menu-bar icon |

## Requirements

macOS 14 (Sonoma) or later. Runs as a menu-bar accessory — no Dock icon.

## Build & run

Open `FidgetBall.xcodeproj` in Xcode and run (⌘R), or from the command line:

```sh
xcodebuild -scheme FidgetBall -derivedDataPath build build
open build/Build/Products/Debug/FidgetBall.app
```

## Tests

```sh
xcodebuild test -scheme FidgetBall -destination 'platform=macOS'
```

## App icon

The icon is generated procedurally. To regenerate it:

```sh
swift Tools/MakeAppIcon.swift FidgetBall/Assets.xcassets/AppIcon.appiconset
```

## License

[MIT](LICENSE)
