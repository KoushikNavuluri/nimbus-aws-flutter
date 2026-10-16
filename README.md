# Nimbus · fall for the cloud ☁️

A cute, interactive AWS learning playground built in Flutter. Every AWS service is a collectible **Cloudling** you unlock from daily Sky Packs, study in Pocket Books, master in quizzes and flashcards, and snap together in the Build Lab before throwing outages at it. Puff, a little cloud, explains the hard bits.

## Run it

Needs Flutter 3.27 or newer.

```bash
dart run tool/setup.dart   # creates android/ios/web folders, app icon, fetches packages
flutter run
```

## What's inside

- **Today**: sky that changes with the time of day, streak, daily goal ring, today's Sky Pack, up next, review, Cloud Cinema, Lab of the day, Puff's note
- **Sky Pack opening**: swipe to tear, the card rises, flips and reveals with rays and confetti
- **Holographic cards**: tilt with your finger, rainbow foil that grows with mastery
- **Skyway**: 10 islands from dawn to midnight, 30 lessons
- **Pocket Books**: flip pages, reveal cards, sort games, quick checks, a pocket terminal, and S3 widgets (bucket drop, eleven nines, storage classes, public access)
- **Quizzes and a mock exam**, spaced-repetition **Review**, **Cloud Cinema**
- **Build Lab**: 3 real scenarios, a slot builder, live traffic, cost in rupees, chaos testing and a scorecard
- **Ask Puff**: a local, rule-based tutor that explains, compares, estimates costs, quizzes you and remembers things
- **Cloudex**, **Me** (stats, readiness, stamps, settings, exports, reset)

## Structure

`lib/data` content · `lib/store.dart` state + persistence · `lib/ai.dart` Puff · `lib/art` hand-built SVG creatures · `lib/ui` kit, holo cards, packs · `lib/screens` every screen · `lib/nav.dart` navigation.

## Automatic APK builds (optional)

Move `ci/build-nimbus.yml` to `.github/workflows/build-nimbus.yml` and push. GitHub will build and attach an APK.

## Honest notes

- This code was written without a Flutter compiler at hand, so the first `flutter run` may surface a few small errors. They are usually one-line fixes.
- Fonts (DynaPuff, Figtree, JetBrains Mono, Kalam) download once via google_fonts, then cache.
- Puff is rule-based and runs on-device. No AI model, no network.
- Prices are approximate public list prices for learning, converted at ₹88 per US dollar.
- Not affiliated with Amazon Web Services.
