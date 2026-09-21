<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Json Display
This is my first Tidbyt community app, I wanted to display some simple json business data and I discovered that there doesn't seem to be such a thing as a private app.

So this is my attempt to load some simple json and get it to display.

## Features
* Read in a URL from a server (I think you should be able to do basic http auth here http://user:password@domain.com/)
* Title image and text (10x10px png works well for the icon)
* Up to three lines of values, you can add more but I can't work out the animation functions yet
* Each line will scroll if too long
* Each line can have a different color
* If you want more than three lines, you should be able to add the app a second time and use a different json URL, not idea but ¯\_(ツ)_/¯
* Doesn't use cache, if I am reading the [API doc right](https://tidbyt.dev/docs/reference/modules#pixlet-module-cache) we may all use the same cache which would cause issues! 

## Things I would like to add
* Animation to scroll more than three lines
* Better alignment for the titles and values (perhaps just get values to scroll not the titles)

## Feedback
I'm happy to make improvements if I can. just let me know on Mastodon [https://mas.to/@thickey](https://mas.to/@thickey_)


## Example json file
    {
		"title_image": "https://tidbyt-json-display.s3.eu-west-1.amazonaws.com/heart.png",
		"title_text": "Sales",
		"data": [
			{
				"title": "Sales",
				"value": "$56,854",
				"color": "FF0000"
			},
			{
				"title": "Orders",
				"value": "40",
				"color": "00FF00"
			},
			{
				"title": "Status",
				"value": "I am some long text that will scroll",
				"color": "0000FF"
			}
		]
	}