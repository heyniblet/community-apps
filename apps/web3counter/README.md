<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Web 3 Counter

## [Web 3 Is Going Great](https://web3isgoinggreat.com/)

Polls W3IGG for the current amount of money lost and displays it. It could probably use some polishing, but it seemed like a good starter project.

W3IGG (web3isgoinggreat.com) is a satire site that tracks and reports crypto scams, ponzi schemes, rug pulls, and other travesties.

![W3IGG](web_3_counter.png)

## External APIs used

Just a simple endpoint that [Molly](https://github.com/molly/) [added](https://github.com/molly/web3-is-going-great/issues/486) to [W3IGG](https://web3isgoinggreat.com/api/griftTotal) which returns the total amount, in dollars, that has been lost or stolen by various cryptocurrency scams, rug pulls, and crashes.

Example query:

```bash
$ curl 'https://web3isgoinggreat.com/api/griftTotal'
{"ip":"65.25.96.157"}%
````

## Options

None

## Note

When the total hits 1 trillion, the text is going to overflow. Hopefully it will be a few months, but who knows at this point?
