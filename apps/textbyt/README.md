<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Textbyt Applet for Tidbyt

Display text messages on your Tidbyt. Great for parties or letting your loved ones know you're thinking about them when you can't be there in person. 

![Textbyt Applet for Tidbyt](screenshot.gif)

## Getting Started

To get started, text 'new' to 610-TEXTBYT (610-839-8298). The service will reply with a unique feed id. Enter this feed id into your Textbyt app. Anyone you share this feed id with can text messages to your Tidbyt.

To send your first message, start your text with `<name>@<feed id>`. The service will associate the name and feed id with your number so future texts will go to the same Tidbyt.
	
![Sending messages](messages.png)

## Privacy

The API and SMS service that powers Textbyt is not affiliated with Tidbyt, Inc. Use at your own risk.

The code for the API is [open source](https://github.com/joshareed/textbyt) so you can inspect what it does. The service stores a small amount of data for each feed: 

```json
{
	"id": "HelloWorld",
	"author": "Textbyt",
	"message": "Welcome to Textbyt, text 'new' to 610-839-8298 to get started!",
	"updated_at": "2022-09-03T23:00:00.489Z"
}
```

And it stores a small amount of data about phone numbers that text it to remember author and feed info:

```json
{
	"id": "+16105551234",
	"author": "Textbyt",
	"feed_id": "HelloWorld",
	"updated_at": "2022-09-03T23:00:00.489Z"
}
```


