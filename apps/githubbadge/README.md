<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# GitHub Badge

Displays the latest status for a given repository in the design of GitHub's Status Badges. This App uses the [list workflow runs](https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow) API from GitHub.

The Personal Access token should be scoped with `repo:read` for whichever repository you want to listen to.

![GitHub Badge for Tidbyt - Success Example](screenshot_success.webp)
![GitHub Badge for Tidbyt - Failing Example](screenshot_failing.webp)
![GitHub Badge for Tidbyt - Loading Example](screenshot_processing.webp)
![GitHub Badge for Tidbyt - Neutral Example](screenshot_cancelled.webp)
![GitHub Badge for Tidbyt - Faulted Example](screenshot_fault.webp)
