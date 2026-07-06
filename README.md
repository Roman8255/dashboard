# Dashboard

Natívna SwiftUI iOS aplikácia — personalizovateľný dashboard s widgetmi.

## Požiadavky

- Xcode 16+
- iOS 17+
- Apple Developer účet (Sign in with Apple)

## Spustenie

1. Otvor `ios/Dashboard.xcodeproj` v Xcode
2. Nastav Development Team v Signing & Capabilities
3. Build na simulátor alebo fyzický iPhone

## Funkcie

- Sign in with Apple + cloud sync dashboardov
- Fullscreen dashboard s 4-stĺpcovým gridom (štvorcové bunky, bez scrollu)
- Long-press kdekoľvek na obrazovke → Nastavenia
- Galéria widgetov:
  - **Základné:** hodiny, počasie, Spotify, fotky, albumy, server
  - **Podnikateľské:** plán dňa (kalendár), úlohy (pripomienky), svetové hodiny, kurzy mien, kontakty, pomodoro, sieť (speed test každú hodinu)

## Widgety — povolenia

| Widget | Povolenie |
|--------|-----------|
| Plán dňa | Kalendár |
| Úlohy | Pripomienky |
| Kontakty | Kontakty (výber v Nastaveniach → Widgety) |
| Svetové hodiny | Výber miest v Nastaveniach → Widgety |
| Kurzy mien / Sieť | Sieť (bez extra povolenia) |

## Spotify setup

1. Vytvor app na [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Redirect URI: `dashboard://spotify-callback`
3. Vlož Client ID do `ios/Dashboard/Config/SpotifyConfig.swift`
4. V apke: Nastavenia → Pripojiť Spotify
5. Spusti Spotify na iPhone a začni prehrávanie (ovladanie cez Web API vyžaduje aktívne zariadenie)

## Štruktúra

```
ios/Dashboard/
├── DashboardApp.swift
├── ContentView.swift
├── AppState.swift
├── Models/
├── Services/
├── Views/
└── Widgets/
```

## Bundle ID

`sk.romanbednarik.dashboard`
