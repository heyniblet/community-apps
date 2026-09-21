<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->


#Github Contributions

Instructions to get a Personal Access Token:
1. Go to github.com → Profile Picture  → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token
2. Name: "Tronbyt Contributions" | Expiration: 90 days | Select Repositories | Permissions: Add 
3. Copy the token (ghp_xxx...) - you won't see it again!

Fine Grained:

Repositories: Metadata: Read Only
Account: Email Address: Read Only
Account: Profile: Read Only

YOUR_TOKEN = github_pat_XXXXXXXXxxxxxxxXXXXXXxx

To test, you can replace YOUR_USERNAME and YOUR_TOKEN in the following curl call:

curl -H "Authorization: bearer YOUR_TOKEN" \
-H "Content-Type: application/json" \
https://api.github.com/graphql \
-d '{
  "query": "query($u:String!, $from:DateTime!, $to:DateTime!) { user(login:$u) { contributionsCollection(from:$from, to:$to) { contributionCalendar { totalContributions weeks { firstDay contributionDays { date contributionCount } } } } } }",
  "variables": {
    "u": "YOUR_USERNAME",
    "from": "2025-10-18T00:00:00Z",
    "to": "2026-01-09T23:59:59Z"
  }
}'

![GitHub Contributions for Tronbyt](githubcontributions.webp)