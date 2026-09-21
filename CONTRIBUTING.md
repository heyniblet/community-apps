> Updated for this community fork. Original upstream authorship and applicable notices are preserved.

# Contributing to Niblet Community Apps

App authors and other contributors are welcome. Original authorship and downstream maintenance are separate: updating an app does not make you the author of its original code.

## Existing apps

1. Read the app's source, manifest, README, licenses, and [compatibility notes](docs/COMPATIBILITY.md). Compare any relevant changes in Tronbyt upstream.
2. Create a branch from `main` and make a focused change. Link upstream fixes and preserve their authorship when importing commits.
3. Preserve the app ID, settings keys, saved values, provider behavior, and author credits. Explain and test migration if any must change. Prefer an explicit optional mode or separate variant for substantially different behavior.
4. Update the app README with setup, changed behavior, limitations, and evidence. Add or update a prominent modification notice in changed source files without deleting original notices.
5. Run the relevant formatter, lint, check, and rendering commands for the Pixlet version you use. Test existing saved configurations as well as new ones. Include versions and results in the pull request; clearly list untested behavior.
6. Submit a pull request against `main`. Original authors should follow [Updating your app](docs/UPDATING_YOUR_APP.md) for ownership and contact updates.

Never commit credentials, private calendar URLs, personal configuration, or private account data. Use synthetic fixtures and mark sensitive schema fields `secret = True`. An empty render or sample output must not be reported as successful live integration.

## New apps and portability

Scaffold with `pixlet create apps/<appname>` and supply a manifest, README, and representative preview. Document required services, credentials, external data terms, settings, and tested resolutions. Advertise 2x support only after testing it. Keep Niblet-specific deployment policy outside portable app logic.

Current CI uses one pinned Niblet CLI runtime, not a complete cross-platform compatibility matrix. Passing CI alone does not prove compatibility with every Tronbyt or Niblet version. State what you actually tested. See [COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Rights and attribution

Submit only material you are entitled to contribute, including any required employer permission. Your original contributions are submitted under this repository's Apache 2.0 license unless an applicable app-specific license is clearly identified. Preserve existing app-specific licenses; do not silently relicense third-party code, icons, images, fonts, or datasets. Identify third-party sources and their terms.

Contributors retain ownership of their contributions. Applicable licenses determine permission to modify, distribute, and use the code, including hosted or commercial use. Maintenance status does not transfer ownership, authorize use of unrelated trademarks, or override external API and data terms. Retain applicable notices and mark changed files as required by their licenses. See the [Apache 2.0 terms](https://www.apache.org/licenses/LICENSE-2.0).

The [historical Tidbyt CLA](docs/CLA.md) names Tidbyt and is not the agreement for new submissions here. This fork does not require signing that historical agreement. Uploading a private app to a service is not, by itself, a contribution to this public repository.

AI-assisted work is welcome when a human contributor reviews the behavior, tests, security, provenance, and licenses. Do not invent test results, owner approval, copyright claims, or contributor signoffs. Do not replace original authors with the person or tool performing maintenance.

## Review and release

Repository maintainers review changes. Original authors' input is welcome, but lack of a response does not transfer their rights. Another contributor may propose maintenance consistent with the applicable license. Substantial redesigns should be discussed before implementation.

Source review and catalog rollout are separate. Upstream submission follows Tronbyt's own rules and requires a separate pull request. Report sensitive issues through [SECURITY.md](docs/SECURITY.md); observe the [code of conduct](docs/CODE_OF_CONDUCT.md).
