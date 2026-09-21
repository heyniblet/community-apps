<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

**Configuration or behavior difference:** The downstream app uses manual status instead of the previous account/calendar integration. Earlier automatic-status setup instructions do not describe the current behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# office-status

Display your availability to coworkers. Connect calendar and messaging apps to your Tidbyt to show whether you are Away, Remote, Free, or Busy.

The initial version of this app supports Outlook calendar and Webex Teams. Additional connections can be added upon request.

Huge shout out to Matt Fisch for is Outlook Calendar App for examples on oAuth2.0 to Graph.

## Screenshot

![Office Status Applet for Tidbyt](screenshot.png)