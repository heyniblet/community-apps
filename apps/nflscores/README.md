# NFL Scores for Tidbyt

Displays NFL scores and gambling odds for upcoming games. No API key required.

Plays every game returned by ESPN in feed order, matching the original Lunchbox app. Team selection filters that same feed. Each card lasts 3–15 seconds (default 5); full-animation playback finishes the sequence before rotating to another app.

Scoreboard responses are cached for 60 seconds. The hosting scheduler controls refresh frequency independently of card speed and total playback duration. Content expiry allows enough time to finish the sequence.

![NFL Scores for Tidbyt](screenshot.png)
