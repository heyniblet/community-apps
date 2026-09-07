MobyGames
==================

This app uses the [MobyGames API](https://www.mobygames.com/info/api/) to select a random game from the [MobyGames](https://www.mobygames.com/) database. It displays the cover thumbnail, title, description, MobyScore, first platform, release date, and required MobyGames credit.

Here are a few screenshots showing the app in action:

![Example screenshot gif showing the display for Road Rash II](road_rash_ii.gif)

![Example screenshot gif showing the display for Ultima V: Warriors of Destiny](ultima_v.gif)

## Development

Feel free to make changes to this app. You need a MobyGames API key whose plan permits your intended use. MobyGames currently offers paid commercial plans and separately approved free non-commercial research access.

The following commands will be useful to you when developing locally (e.g. when running `pixlet render`):

1. `api_key` (required): the API key to use when making requests to the MobyGames API when running locally
2. `debug` (optional): set this to `true` to print debug statements to the console

Here's an example of rendering the app locally:

```
pixlet render moby_games.star api_key=my_api_key debug=true
```

You can also render the app using `pixlet serve` (the above parameters simply need to be passed to the url)

The app makes one request to the [games/random](https://www.mobygames.com/info/api/#gamesrandom) endpoint and loads up to 100 games. Each render selects one of those games. The hosting platform controls the refresh cadence and must keep each user's API key and rendered result tenant-isolated.

## Future Possible Improvements

These are things I may do, or any other developer is welcome to do so as well:

* Explore the MobyGames API in further detail to see if there's more useful data to ingest - e.g. developer, publisher (I see this information on the MobyGames site, but not in sample requests to their API, so this may require reaching out to MobyGames to see if they're interested in exposing these details)
* Add in more data to what's displayed, such as genres, or additional platforms and release dates beyond just the first
* Introduce configuration for filters supported by a documented MobyGames endpoint.
