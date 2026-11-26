# Gazi Portfolio — Android app

The companion app to the portfolio website. Read-only by design: every byte of
content comes from the site's `/api/v1` endpoints, and the app keeps the last good
copy on the device so it still works with no connection.

Flutter 3.41 · Dart 3.11 · `gazi_portfolio_app` · Android only.

---

## What it does

| Screen | Contents |
|--------|----------|
| **Home** | Hero, availability chip, live stats, summary, recent roles, featured projects, skills |
| **Career** | Every role, full-time and part-time listed separately, as a timeline |
| **Work** | All projects, filterable by technology, with cover art |
| **Case study** | Full write-up, meta block, technology list, gallery with a full-screen viewer |
| **CV** | Both PDF variants, explained honestly, with in-app preview and share |
| **Updates** | Posts the site has published to LinkedIn, newest first, with a link to each live post |
| **Contact** | WhatsApp, Messenger, LinkedIn, email, phone, GitHub, Facebook — all one tap |
| **Settings** | Server address, cache status, content counts |

## Running it

The app needs to know where the website is, and that changes per situation:

| Situation | Address to enter in Settings |
|-----------|------------------------------|
| Fresh install (default) | `https://gazi.ciphercall.dev` |
| Android emulator on this PC | `http://10.0.2.2:8023` |
| Physical phone on the same Wi-Fi | `http://<this PC's LAN IP>:8023` |

The compiled default is the live site, so a sideloaded build works without setup. A saved
address always wins; override it in **Settings → Portfolio server → Save and reload**. For local
work, start the stack first (`portfolio-deploy.ps1 -Action up`).

## Offline behaviour

Three layers, in order:

1. **The last successful snapshot on disk** — shown immediately on launch.
2. **The snapshot bundled in the APK** (`assets/seed.json`) — so a first launch with
   no network still shows real content rather than an empty screen.
3. **The network** — refreshes in the background and never clears what is on screen.

A failed refresh leaves the previous content in place and shows a quiet "showing
saved content" note. There is no error page unless there is genuinely nothing to show.

`assets/seed.json` is regenerated from a running stack:

```powershell
node tool/generate_seed.mjs http://localhost:8023
```

Refreshing is cheap: the app asks `/api/v1/meta` for a content hash first and only
refetches everything when it changed.

## Design

The app carries the **same Midnight Aurora tokens as the website** — the same ink
canvas, the same teal/cyan/violet accent triple, the same radii — so the two clients
read as one product. Tokens live in `lib/theme/aurora.dart`; the web equivalents are
in `gazi-portfolio/src/app/globals.css`.

Fonts are the same variable families the site uses (Sora for display, Inter for body),
bundled as assets so there is no runtime font fetch.

Owner rules honoured throughout: no icon-only buttons anywhere, every control carries
a visible label; colour is never the only signal; required actions are never the last
item in a scrolling region; loading shows skeletons rather than blank space.

### Motion and the living field

`lib/widgets/motion.dart` holds the shared primitives — staggered `Reveal`,
`PressScale`, `CountUp`, `TechMarquee` — and every one of them short-circuits under
`MediaQuery.disableAnimationsOf`. Routes use a 220 ms fade/rise transition.

`AuroraBackground` (`lib/widgets/aurora.dart`) paints the same eight industry
silhouettes as the website — database, document, monitor, phone, cloud, shield,
chip, code — with the shape rings and clocks in
`lib/widgets/background_field.dart`. Six glyphs drift, hold a silhouette for 11 s,
then morph over 3 s. A `Listener` wrapped around the whole shell (translucent, so it
never claims a gesture) feeds every tap into the painter: nearby shapes bulge and
light up, and an expanding ripple fades over 1.2 s. Reduced motion keeps one static
frame and ignores taps.

## Android specifics worth knowing

- **`INTERNET` permission is declared in the main manifest.** Flutter only adds it to
  the debug manifest, so without this line a release build has no network access at all.
- **Cleartext HTTP is permitted** (`res/xml/network_security_config.xml`). The API is
  self-hosted over plain HTTP on the LAN, at an address that differs per network, and
  Android cannot express an IP range in that file. This is a deliberate trade for a
  read-only client that sends no credentials and stores no secrets. If the app is ever
  pointed at a public HTTPS host, tighten that file to that one domain.

## Building

```powershell
$env:Path = "C:\flutter\bin;$env:Path"     # or call C:\flutter\bin\flutter.bat directly
flutter pub get
flutter analyze lib                        # must report no issues
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

The build is currently **debug-signed** (Flutter's default when no keystore is
configured). That is fine for sideloading and for the OTA channel, but it is not a
Play-Store-grade signature — create a `key.properties` and a keystore before
publishing anywhere that requires one.

## Over-the-air updates

The app is published through the workspace's `rocket launcher` pipeline, the same one
the attendance app uses:

```powershell
# in gazi-portfolio-app
flutter build apk --release --split-per-abi

# in "rocket launcher"
# copy app-arm64-v8a-release.apk and app-armeabi-v7a-release.apk into inbox\gazi-portfolio\
.\scripts\publish-update.ps1 -ConfigFile .\config\gazi-portfolio.env `
  -InboxDir .\inbox\gazi-portfolio -Channel prod -ReleaseNotes "<end-user-facing text>"
```

Bump `version:` in `pubspec.yaml` before publishing. The rule that matters is
`versionCode`: the gate only updates when `remote > installed` (strict integer
compare), so a build whose code equals a sideloaded test APK never prompts. The
universal `app-release.apk` is for manual installs; the publisher consumes the
two split APKs.

## Recent changes

**Real SVG icons and a content-first field (`0.3.6+109`)**
- The settled background shapes now draw the real vendored Lucide SVGs
  (`assets/icons/field`, ISC) instead of hand-drawn artwork; the morph itself is unchanged.
- The field is outline-only — no fill colour anywhere — and a dimming veil sits between it and
  the content.
- Every `GlassPanel` is a real frosted surface (backdrop blur + stronger panel/line tokens), and
  the muted/faint text colours were raised so content always wins over the animation.
- The bottom bar no longer clips the last row: the shell reserves the bar height plus the gesture
  inset below every screen.
- `flutter_svg` was added to render the bundled icons; all 11 tests pass.

**Recognisable icons in the living field (`0.3.5+108`)**

- Each settled background silhouette now resolves into that element's coloured
  icon — database bands, page text, a screen, a shield tick, a chip core, code
  chevrons — with a gradient fill, a bright outline and white detail strokes.
  The icon holds while the shape rests, fades over the first 18 % of the next
  morph and returns over the last 28 %; reduced motion rests on the icons.
- `test/background_field_test.dart` covers ring invariants, the 1→0→1 alpha
  cycle and detail bounds.

**OTA gate fix (`0.3.4+107`)**

- The forced-update prompt is now wrapped in its own `MaterialApp`. Builds 105 and 106
  returned it straight from the gate, so `Scaffold` had no `MediaQuery`/`Directionality`
  and a forced update painted an empty grey window instead of the prompt. Those installs
  must be moved to 107 with a manual APK install once; from 107 onward OTA works again.
- `test/update_gate_test.dart` pumps the gate's update path and asserts the prompt renders
  inside a `MaterialApp`.

**Portrait, living field, compact layout (`0.3.3+106`)**

- Home's hero is a two-column identity block: the portrait from `profile.avatarPath`
  beside the name, falling back to the shared monogram art when there is no photo.
- The background is now the shared “field of practice”: eight morphing industry
  silhouettes, tap-reactive bulges and ripples, static under reduced motion.
- Global compaction through the `Aurora.display`/`body` scales, a 56 px app bar with
  an animated selection pill, animated route transitions, staggered reveals,
  `PressScale`, animated counters and a technology marquee.
- Projects filter changes animate through `AnimatedSwitcher`; cards are two-up and
  share `Hero` covers with the case study; the gallery viewer supports pinch/drag
  zoom at natural aspect ratio.
- Version code 106 is the first build above the 105 sideload, so the forced OTA
  channel can actually deliver it.

**LinkedIn publishing parity (`0.2.0+102`)**

- New **Updates** screen fed by `GET /api/v1/social`: the posts the website has published to
  LinkedIn, newest first, each opening the live post.
- Case-study screens show **Posted on LinkedIn** when the project has a published post
  (`linkedinUrl` on `/api/v1/projects`).
- `fetchSnapshot()` tolerates a backend without `/api/v1/social`, and the snapshot keeps the feed
  as an optional field so older cached snapshots still parse.
- `assets/seed.json` now includes the feed; `tool/generate_seed.mjs` fetches it too.

Added offline-first **OTA binary updates** through the rocket launcher pipeline:
- Cold-start `UpdateGate` checks `ota/gazi-portfolio/manifest.json`.
- Android installer support, FileProvider, and `PackageReplacedReceiver` relaunch.
- Version baseline raised to `0.1.0+100`; publish only `--split-per-abi --release` builds.
- Manual update reports and Settings checks.

Also:

- Settings is now reachable from the Home screen, with inline URL validation before saving.
- Offline refreshes show a thin progress bar at the top of the screen.
- The in-app markdown renderer now supports `##` headings in addition to `###`.
- CV/image downloads use tighter cache dimensions, and text scaling stays clamped between
  0.9× and 1.3×.
- Project thumbnails and galleries are now populated from the server (303 screenshots across
  32 projects); the offline bundle (`assets/seed.json`) was refreshed to match.

## Known gaps

- **OS-level app links are not configured.** Tapping an `https://…/projects/swop` link
  outside the app will not open it. Android App Links require a public HTTPS host with
  a verified `/.well-known/assetlinks.json`, and this stack is local-only. In-app
  navigation works normally.
- No push notifications — that was explicitly out of scope for this pass.
- No admin editing from the phone; the panel is web-only.
