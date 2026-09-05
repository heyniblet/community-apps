# Now Spinning

## Overview

This app was developed by request for the user `Diesel7688` on the [Tidbyt Forums](https://discuss.tidbyt.com/t/now-spinning/6964).

It displays the album cover, album name and artist name from a specific album chosen by the user.

The app itself is not connected to any music service and does not update automatically. The user needs to manually change the displayed album. This was also by request.

---

## Configuration (Schema)

The app has a text field where the user enters an album name, optionally with the artist to refine the match.

There are also options to change the app colors and one option to hide the app from rotation.

---

## API Details

The app uses the [MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API) to resolve the album and the [Cover Art Archive](https://coverartarchive.org/) for artwork.

### Authentication

No authentication is required. Album matches and cover images are cached for 24 hours.

### Rate Limiting

MusicBrainz asks clients to stay at or below one request per second. The app sends an identifying user agent and its 24-hour cache keeps normal usage well below that rate.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, failure to recover the cover image of an album will be handled and a default image will be shown.

Album lookup failures show an error state on the display.

---

## Future Improvements

This app is already pretty straightforward and there is nothing much else to add. Trying to connect it to a music service is pointless because then it will behave like the official apps like Spotify or Sonos.
