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
| **Contact** | WhatsApp, Messenger, LinkedIn, email, phone, GitHub, Facebook — all one tap |
| **Settings** | Server address, cache status, content counts |

## Running it

The app needs to know where the website is, and that changes per situation:

| Situation | Address to enter in Settings |
|-----------|------------------------------|
| Android emulator on this PC | `http://10.0.2.2:8023` (the default) |
| Physical phone on the same Wi-Fi | `http://<this PC's LAN IP>:8023` |
| Through a Cloudflare Tunnel | the public HTTPS hostname |

Start the stack first (`portfolio-deploy.ps1 -Action up`), then set the address in
**Settings → Portfolio server → Save and reload**.

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
cd "rocket launcher"
.\build-production-apk.ps1 -Publish -ReleaseNotes "<end-user-facing text>"
```

Bump `version:` in `pubspec.yaml` before publishing — the launcher reads
`versionName`/`versionCode` from the built APK, and it publishes whatever APK is
staged, so check the artifact's timestamp and version before shipping.

## Recent changes

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
