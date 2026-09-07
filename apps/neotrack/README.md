# NEOTrack - Near Earth Object Tracker

Shows the closest upcoming object passing Earth within the next day according to NASA/JPL's documented [Close-Approach Data API](https://ssd-api.jpl.nasa.gov/doc/cad.html) and [Small-Body Database API](https://ssd-api.jpl.nasa.gov/doc/sbdb.html). The legacy API-key setting is retained so existing installations keep their configuration, but it is no longer sent anywhere.

![Screenshot](neotrack.gif)

Shows the following information:

In the lefthand pane:

- The known diameter in kilometres or metres, or absolute magnitude (`H`) when JPL has no measured diameter
- A green border denotes the object is safe, an orange border means it's potentially dangerous[^1]

Righthand pane:

- The official name of the asteroid
- `V`: The relative velocity in Kilometres per Second
- `D`: The closest approach distance in [Lunar Units (LU)](https://en.wikipedia.org/wiki/Lunar_distance_(astronomy))
- `O`: The asteroid's orbiting body

[^1]: A potentially hazardous object (PHO) is a near-Earth object whose orbit brings it within 4.7 million miles (7.5 million km) of Earth’s orbit, and is greater than 500 feet (140 meters) in size.
