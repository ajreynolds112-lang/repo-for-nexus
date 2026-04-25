# AudienceAmp 🎵

> **Smart Music Marketing — Artist Audience Intelligence**
> Universal Xcode app for iOS 17+ & macOS 14+ (Mac Catalyst)

AudienceAmp helps independent and emerging music artists identify the right audiences to advertise to by:

1. **Artist & Genre Matching** — Find benchmark artists in your genre via Spotify & Apple Music APIs
2. **Fan Intelligence** — Aggregate demographics, psychographics, and geographic fan data
3. **Ad Parameter Generation** — Export ready-to-paste targeting parameters for Meta Ads, TikTok Ads, Google Ads, and Spotify Ad Studio

---

## Features

- 🔍 **Artist Discovery** — Search artists by name, genre, and sub-genre with real-time autocomplete and related artist suggestions
- 👥 **Fan Demographics** — Age, gender, geographic, and psychographic breakdown of benchmark artist fanbases
- 📍 **Location Targeting** — High-density fan cities and neighborhoods ranked by listener share
- 🎯 **Interest Targeting** — Curated interest lists ready for ad manager input fields
- 📈 **Streaming Likelihood Score** — 0–100 metric estimating new-listener conversion probability per market
- 📋 **One-Tap Export** — Copy or export all parameters as CSV or formatted text

---

## Project Structure

```
AudienceAmp/
├── App/
│   ├── AudienceAmpApp.swift          # @main entry point
│   └── ContentView.swift             # Root navigation shell
├── Config/
│   ├── Secrets.xcconfig              # API keys (gitignored)
│   └── AppConstants.swift            # Base URLs, timeouts, limits
├── Models/
│   ├── Artist.swift                  # Core artist model + SelectionState
│   ├── FanProfile.swift              # Demographics + psychographics
│   ├── AdParameters.swift            # Generated ad targeting output
│   └── GenreTag.swift                # Genre/sub-genre taxonomy
├── Repositories/
│   ├── ArtistRepository.swift        # Artist search + related artists
│   └── FanIntelligenceRepository.swift # Fan data aggregation
├── Services/
│   ├── SpotifyService.swift          # Spotify Web API + OAuth PKCE
│   ├── AppleMusicService.swift       # MusicKit + Apple Music API
│   └── ChartmetricService.swift      # Third-party audience intelligence
├── ViewModels/
│   ├── ArtistDiscoveryViewModel.swift
│   ├── FanIntelligenceViewModel.swift
│   └── AdParameterViewModel.swift
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── ArtistDiscovery/
│   │   ├── ArtistDiscoveryView.swift
│   │   └── ArtistRowView.swift
│   ├── FanIntelligence/
│   │   └── FanIntelligenceView.swift
│   └── AdParameters/
│       └── AdParameterView.swift
├── Components/
│   ├── FilterChip.swift
│   ├── SimilarityBadge.swift
│   └── SelectionButton.swift
└── Utilities/
    ├── SimilarityEngine.swift
    └── AdParameterEngine.swift
```

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 15.0+ |
| iOS Deployment Target | 17.0+ |
| macOS Deployment Target | 14.0+ (Mac Catalyst) |
| Swift | 5.9+ |

---

## API Keys Required

Create a `AudienceAmp/Config/Secrets.xcconfig` file (gitignored) with:

```
SPOTIFY_CLIENT_ID = your_spotify_client_id
SPOTIFY_CLIENT_SECRET = your_spotify_client_secret
CHARTMETRIC_API_KEY = your_chartmetric_api_key
APPLE_MUSIC_KEY_ID = your_apple_music_key_id
APPLE_MUSIC_TEAM_ID = your_apple_music_team_id
```

Register your app at:
- [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
- [Apple Music API](https://developer.apple.com/documentation/applemusicapi)
- [Chartmetric API](https://api.chartmetric.com)

---

## Getting Started

```bash
git clone https://github.com/ajreynolds112-lang/repo-for-nexus.git
cd repo-for-nexus
open AudienceAmp.xcodeproj
```

1. Add your API keys to `AudienceAmp/Config/Secrets.xcconfig`
2. Select your target — **AudienceAmp (iOS)** or **AudienceAmp (macOS)**
3. Build & Run (`Cmd + R`)

---

## Roadmap

- [ ] Spotify for Artists OAuth PKCE integration
- [ ] Apple Music for Artists OAuth integration
- [ ] Chartmetric fan demographic aggregation
- [ ] Meta Ads parameter formatter
- [ ] TikTok Ads parameter formatter
- [ ] Google Ads custom intent audience export
- [ ] Spotify Ad Studio genre targeting export
- [ ] WidgetKit streaming likelihood widget
- [ ] iCloud sync for saved campaigns

---

## License

MIT License — see [LICENSE](LICENSE) for details.
