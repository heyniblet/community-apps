# Goodreads yearly reading challenge progress 

Displays the progress of your reading challenge along with different icons to illustrate how many books you've read thus far.

![Demo](reading_challenge.png)

## Goodreads.com

Goodreads closed its public API in 2020. A public challenge page at
`https://www.goodreads.com/user_challenges/{challenge_id}` still exposes reading
progress. Enter the challenge ID from that URL in the app settings. The app
parses the page's `progressText` element, so changes to Goodreads HTML may require
an app update.

Parsing HTML is more fragile than making a real API call.
