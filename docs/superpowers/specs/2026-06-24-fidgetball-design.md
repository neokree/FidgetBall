# FidgetBall — Design Spec

**Date:** 2026-06-24
**Status:** Shipped

FidgetBall is an open-source macOS menu-bar app: a physics ball hangs on a rope from
your menu bar and floats over everything on your desktop. You drag it, fling it, watch
it swing and bounce, slash the rope to cut it loose, and bump the freed ball like a
volleyball. It lives quietly in the background until you want to play.

## Concept

A small, low-stakes desktop toy for restless hands — somewhere to fidget while your
attention stays on the work in front of you. Design goals:

- A ball on a rope, anchored at a menu-bar icon, with believable physics
  (gravity, swing, bounce, throw).
- Floats over your desktop and other windows but never steals focus or blocks clicks
  except when you're actually touching the ball.
- Two play modes: roped (drag / fling / swing) and cut (slash the rope, then keep the
  free ball up like a volleyball — miss it and it falls off-screen).
- Personalisable: several ball skins and a full set of physics sliders, all persisted.
- Summon / hide instantly with a global shortcut; optional haptic feedback.
- Targets macOS 14+ (built and run on macOS 15).

## Features

- Ball-on-rope Verlet physics: gravity, swing, drag, throw, cut-the-rope.
- Slash-to-cut: drag the cursor through the rope to sever it.
- Volleyball bump: tap a cut ball to knock it upward (off-centre hits angle it);
  a cut ball that falls past the bottom edge is removed.
- Transparent, click-through overlay anchored to the menu-bar icon.
- Six procedurally-drawn skins: smiley, basketball, tennis, marble, football, disco.
- Settings window with live, persisted physics sliders + haptics toggle.
- Global show/hide hot key (⌥F by default); haptic feedback on impact.

## Architecture

Native macOS app (Xcode project, deployment target macOS 15.7, App Sandbox on, Swift 5
language mode, file-system-synchronized groups so new `.swift` files auto-join the target).

| Unit | Responsibility | Depends on |
|------|----------------|-----------|
| `Vector2` | 2D vector math (pure) | — |
| `Geometry` | Segment intersection + point-to-segment distance (slash detection) | Vector2 |
| `PhysicsConfig` | Tunable parameters (gravity, drag, restitution, rope length/segments, ball radius, throw/spin/bump…) | — |
| `PhysicsWorld` | Verlet rope chain anchored at a moving anchor + ball particle; `step`, `grab`/`drag`/`release`, `cut`, `bump`, `ropeIsCrossed`, `reset`; wall collisions, fall-off. **Pure & unit-tested.** | Vector2, Geometry, PhysicsConfig |
| `BallSkin` | Core Graphics procedural drawing per skin, with rotation for spin | AppKit/CoreGraphics |
| `OverlayWindow` | Borderless, clear, full-screen, non-activating `.floating` panel | AppKit |
| `OverlayView` | Flipped NSView: draws rope+ball each frame; routes mouse into grab/throw or slash gestures | PhysicsWorld, BallSkin |
| `OverlayController` | Owns window/view/CADisplayLink; tracks the anchor; toggles `ignoresMouseEvents` by ball/rope proximity; haptics; tap-vs-throw; show/hide; live config | the above |
| `HotKey` | Carbon `RegisterEventHotKey` for ⌥F (no Accessibility permission) | Carbon |
| `StatusBarController` | NSStatusItem: left-click drops a new ball, right-click opens the menu (skins, cut rope, show/hide, settings, quit) | OverlayController |
| `BallSettings` / `SettingsStore` / `SettingsView` / `SettingsWindowController` | Persisted settings model + SwiftUI settings UI applied live | — |
| `AppDelegate` | `.accessory` activation, wires everything | all |

### Physics model (Verlet)

- Scene coordinates: origin top-left, +x right, **+y down** (gravity is +y). The render
  view is `isFlipped = true` so view coords match scene coords 1:1; the screen↔scene
  mapping flips y once at the boundary.
- Rope = chain of Verlet points `[anchor, p1…pN, ball]`. `anchor` is pinned to the
  menu-bar icon's screen position each frame. Segment rest length = `ropeLength / segments`.
- Integration: `next = pos + (pos - prev)*(1-drag) + gravity*dt²`, then K relaxation
  iterations of distance constraints (anchor stays pinned), plus a hard cap so the ball
  can never exceed the fully-extended rope. The rope snapping taut registers an impact.
- Ceiling and side walls bounce (restitution + friction); the **floor is open** — a cut
  ball that isn't kept up falls past the bottom and is marked gone.
- **Grab:** pin ball to cursor; velocity tracks recent motion. **Release:** fling with
  `velocity * throwMultiplier`. **Cut:** drop rope constraints; ball becomes a free
  particle. **Bump:** tap a cut ball to kick it upward. **Reset / new ball:** rebuild
  the rope at the anchor.

### Window & input

- Full-screen borderless clear non-activating panel, `level = .floating`,
  `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`.
- Per-frame: read `NSEvent.mouseLocation` (no permission needed); when the cursor is near
  the ball **or** near the rope **or** a gesture is in progress, set
  `ignoresMouseEvents = false` so the window grabs the click; otherwise `true` so clicks
  pass through to whatever is underneath.
- `OverlayView` turns input into two gestures: grab on the ball (drag = throw, a tap on a
  cut ball = bump) or slash near the rope (drag across it = cut). Open/closed-hand and
  crosshair cursors signal which is available.
- CADisplayLink (`NSView.displayLink(target:selector:)`, macOS 14+) drives a fixed-step
  physics update + redraw on the main thread.

### Settings

`BallSettings` (Codable, persisted to UserDefaults as JSON) maps onto `PhysicsConfig`
plus app options (skin, haptics). `SettingsStore` publishes changes; the app applies them
to the live world immediately. `SettingsView` (SwiftUI) hosts the skin picker, haptics
toggle, and sliders for gravity, bounciness, air resistance, throw power, spin, ball size,
rope length, stiffness, wall friction, and bump power, plus reset-to-defaults.

## Testing

The pure model is covered by TDD (Swift Testing): vector math; rope keeps the ball within
reach; the ball settles below the anchor; a throw flings it in the drag direction; cutting
frees the ball and it falls off the bottom; a bump launches a cut ball upward; side walls
bounce a cut ball; slash geometry (segment intersection / distance); rope-taut impact for
haptics; and the settings → physics mapping with a persistence round-trip. The AppKit
layers are verified by building and running.

## Risks / mitigations

- *Click-through correctness* — proximity toggle keeps the desktop clickable everywhere
  except on the ball/rope; an in-progress gesture overrides proximity so fast drags and
  slashes aren't dropped.
- *Anchor under the menu bar* — `.floating` (level 3) sits below the menu bar (level 24),
  so the rope reads as hanging from the menu-bar icon.
- *Menu-bar anchor frame* — the status item reports an off-screen frame until the menu bar
  lays out; the controller ignores anchors that aren't in the top strip of the screen.
- *Sandbox* — overlay window, status item, Carbon hotkey, mouse location, haptics, and
  UserDefaults all work under App Sandbox; no extra entitlements required.
