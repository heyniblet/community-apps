<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Spotify Now Playing - Ultimate Edition for Tronbyt/Tidbyt

A feature-rich Spotify display app that shows your currently playing music with album art, progress bar, and playback information on your Tronbyt or locally-run Tidbyt display.

## Features

### Display
- **5 Display Modes**: Full, Compact, Art Focus, Text Only, Minimal
- **Album Art**: High-quality artwork scaled for the display
- **Progress Bar**: Visual track progress with time remaining
- **Smart Scrolling**: Text only scrolls when too long to fit
- **Playback Indicators**: Play/pause state shown clearly
- **Customizable Colors**: Track, artist, and progress bar colors

### Content Support
- **Music Tracks**: Song name, artist(s), album art
- **Podcasts**: Episode name, show name, artwork
- **Recently Played**: Option to show last track when nothing playing
- **Pause State**: Shows paused tracks (not just actively playing)

### Robustness
- **Exponential Backoff**: Graceful handling of API rate limits
- **Pre-emptive Token Refresh**: Refreshes before expiration
- **Multi-layer Caching**: Tokens (45min), album art (24hr)
- **Graceful Degradation**: Falls back if art fails, still shows text
- **Detailed Error Messages**: Actionable error states

## Screenshots

```
┌────────────────────────────────────────────────────────────────┐
│ FULL MODE                                                      │
│ ┌──────────────┐                                               │
│ │              │  Bohemian Rhapsody                            │
│ │  Album Art   │  Queen                                        │
│ │   32x32      │  > ████████░░░░░░                             │
│ │              │              -2:45                            │
│ └──────────────┘                                               │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ COMPACT MODE                                                   │
│ ┌────────────┐                                                 │
│ │            │  Bohemian Rhapsody                              │
│ │ Album Art  │                                                 │
│ │   30x30    │  Queen                                          │
│ └────────────┘                                                 │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ ART FOCUS MODE                                                 │
│               ┌────────────────────┐                           │
│               │                    │                           │
│               │    Large Album     │                           │
│               │        Art         │                           │
│               │                    │                           │
│               │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│                           │
│               │ Bohemian Rhapsod.. │                           │
│               └────────────────────┘                           │
└────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Create Spotify Developer App

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
2. Click **Create App**
3. Fill in the form:
   - **App name**: Tronbyt Now Playing (or whatever you like)
   - **App description**: Display currently playing on Tronbyt
   - **Website**: (leave blank or enter any URL)
   - **Redirect URI**: `http://127.0.0.1:8888/callback` (click "Add" after entering)
   - **Which API/SDKs are you planning to use?**: Check **Web API** only
4. Accept the Terms of Service and click **Save**
5. Click **Settings** on your new app
6. Copy your **Client ID** and **Client Secret** (click "View client secret")

### 2. Get Your Refresh Token

```bash
python3 get_refresh_token.py
```

Follow the prompts to:
- Enter your Client ID and Secret
- Authorize in your browser
- Receive your refresh token

### 3. Configure in Tronbyt

Add the app in your Tronbyt web UI and configure:

| Field | Value |
|-------|-------|
| Client ID | Your Spotify app Client ID |
| Client Secret | Your Spotify app Client Secret |
| Refresh Token | Token from step 2 |

### 4. Play Music!

Start playing something on Spotify and watch it appear on your display.

## Configuration Options

### Credentials (Required)

| Option | Description |
|--------|-------------|
| `client_id` | Your Spotify Developer app Client ID |
| `client_secret` | Your Spotify Developer app Client Secret |
| `refresh_token` | Long-lived token from setup script |

### Display Mode

| Mode | Description |
|------|-------------|
| `full` | Album art + track + artist + progress bar + time (default) |
| `compact` | Album art + track + artist, no progress |
| `art_focus` | Large album art with text overlay at bottom |
| `text` | No album art, full width for text + progress |
| `minimal` | Just track and artist, centered |

### Appearance

| Option | Description | Default |
|--------|-------------|---------|
| `track_color` | Color for track/episode name | `#FFFFFF` (white) |
| `artist_color` | Color for artist/show name | `#1DB954` (Spotify green) |
| `progress_color` | Color for progress bar | `#1DB954` |
| `scroll_speed` | Text scroll speed (slow/normal/fast) | `normal` |

### Behavior

| Option | Description | Default |
|--------|-------------|---------|
| `show_time` | Show time remaining (full mode) | `true` |
| `show_recently_played` | Show last track when nothing playing | `false` |
| `show_when_idle` | Show branding when nothing playing | `true` |
| `idle_message` | Message when nothing playing | `Spotify` |

## Setup Script Options

```bash
# Interactive setup (default)
python3 get_refresh_token.py

# Save credentials to file
python3 get_refresh_token.py --output credentials.env

# Test existing credentials
python3 get_refresh_token.py --test-only

# Test credentials from file
python3 get_refresh_token.py --test-only --credentials credentials.env
```

### Environment Variables

The script supports environment variables for automation:

```bash
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"
python3 get_refresh_token.py
```

## How It Works

### The OAuth Challenge

Tronbyt doesn't have Tidbyt's cloud OAuth infrastructure. This app works around that:

```
┌─────────────────────────────────────────────────────────────┐
│                    ONE-TIME SETUP                           │
│                                                             │
│   You                   Browser              Spotify        │
│    │                       │                    │           │
│    │  Run script           │                    │           │
│    │──────────────────────>│  Authorize         │           │
│    │                       │───────────────────>│           │
│    │                       │<───────────────────│           │
│    │<──────────────────────│  Auth code         │           │
│    │                                            │           │
│    │  Exchange code for tokens                  │           │
│    │───────────────────────────────────────────>│           │
│    │<───────────────────────────────────────────│           │
│    │  Refresh token (permanent)                 │           │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   EVERY RENDER                              │
│                                                             │
│   Tronbyt               spotify.star           Spotify API  │
│      │                      │                      │        │
│      │  Render app          │                      │        │
│      │─────────────────────>│                      │        │
│      │                      │  Refresh token       │        │
│      │                      │─────────────────────>│        │
│      │                      │<─────────────────────│        │
│      │                      │  Access token        │        │
│      │                      │  (cached 45min)      │        │
│      │                      │                      │        │
│      │                      │  Get now playing     │        │
│      │                      │─────────────────────>│        │
│      │                      │<─────────────────────│        │
│      │<─────────────────────│                      │        │
│      │  Display image       │                      │        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Caching Strategy

| Data | TTL | Reason |
|------|-----|--------|
| Access Token | 45 min | Tokens expire at 60 min, refresh early |
| Album Art | 24 hours | Art URLs are stable, saves bandwidth |
| Now Playing | 5 sec | Need near real-time updates |

### Rate Limiting

The app respects Spotify's rate limits:
- Token refresh: ~1/hour
- Now playing: ~2-4/min (based on Tronbyt refresh rate)
- Exponential backoff on 429 errors

## Troubleshooting

### "Setup needed" / "No Client ID"

Your credentials aren't configured. Add them in Tronbyt's app settings.

### "Auth Error: Token revoked"

Your refresh token is invalid. This happens if:
- You revoked access in Spotify account settings
- You deleted your Spotify Developer app
- The token was replaced (running setup multiple times)

**Fix**: Run `get_refresh_token.py` again.

### "Auth Error: Bad credentials"

Your Client ID or Secret is wrong. Double-check them in your Spotify Developer dashboard.

### "Rate Limited"

Too many API requests. The app will automatically back off and retry. If persistent:
- Check if other apps are using your Spotify API credentials
- Reduce your Tronbyt refresh rate

### Nothing displays (blank/black)

1. Check that a track is active (playing or paused) on one of your devices
2. Some private sessions don't report to API
3. Check Tronbyt logs for errors

### Album art not showing

1. Try toggling display mode
2. Local files don't have artwork URLs
3. Very new releases might have art delays
4. Check internet connectivity

### Progress bar stuck

The app shows point-in-time progress. If your Tronbyt refresh rate is slow, progress appears to jump. This is normal.

## Files

```
spotify/
├── spotify.star          # Main Tronbyt/Tidbyt Starlark app
├── get_refresh_token.py  # Setup script for OAuth token
├── manifest.yaml         # App metadata for Tronbyt
└── README.md             # This documentation
```

## Technical Details

### API Scopes

The app requests these Spotify permissions:
- `user-read-currently-playing` - Get currently playing track
- `user-read-playback-state` - Get device, shuffle, repeat info
- `user-read-recently-played` - Get recently played (optional feature)

### Starlark Limitations

Pixlet/Starlark has constraints that influenced the design:
- No classes or advanced OOP
- Limited standard library
- No persistent state between renders
- Shared cache across app instances

### Display Specifications

- Resolution: 64x32 pixels
- Color depth: RGB (16.7M colors)
- Animation: Frame-based WebP

## Contributing

Issues and improvements welcome! The code is designed to be readable and well-documented.

## License

MIT License - Use freely for any purpose.

## Credits

- Built for [Tronbyt](https://github.com/tronbyt/server) and [Tidbyt](https://tidbyt.com)
- Uses [Pixlet](https://github.com/tidbyt/pixlet) runtime
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- Created by gshepperd

---

**Enjoy your music! 🎵**
