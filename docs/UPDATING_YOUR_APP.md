> Niblet documentation changes maintained by [edwin-page](https://github.com/edwin-page). Original upstream authorship and applicable notices are preserved.

# Updating your app

Find your app under `apps/`. Read its current source and maintenance notes before applying an older upstream version: this fork may contain fixes or changes to configuration and providers.

## Submit an update

1. Fork this repository and branch from `main`.
2. Update your app and preserve the existing manifest ID, author credit, license, and notices. Keep old settings working or document and test their migration.
3. Update the app README with setup, affected settings, service requirements, and known limitations. Include screenshots or renders with synthetic data where practical.
4. Open a focused pull request describing the previous and new behavior, Pixlet versions tested, and related upstream changes. Follow [CONTRIBUTING.md](../CONTRIBUTING.md).

If you are the original author, say so and link your original pull request, contribution, or established profile. If you changed accounts, link evidence connecting the accounts. Maintainers can review requests to update contact details or add a maintenance contact. Do not post identity documents or private account information. For private contact, use support@heyniblet.com.

## Authorship and maintenance

Original author credits remain in manifests and source. A maintenance contact identifies who handles the downstream version; it does not replace original authorship or automatically confer repository write access. Do not overwrite the manifest author field simply to claim maintenance credit.

An inactive app can receive licensed maintenance from others. Inactivity does not give anyone ownership of the original contribution, the developer's account, or their upstream repository. Disputed attribution and asset provenance should be raised with specific files and evidence.

## Compatibility and distribution

Consult [known differences](COMPATIBILITY.md). For changes such as OAuth becoming a relay, a provider replacement, or automatic status becoming manual input, explain the migration and avoid silently changing the meaning of existing settings. Consider an optional mode or separately identified variant.

A source merge is not an automatic Niblet catalog rollout. To share a portable fix with Tronbyt, submit it through their contribution process with original credits intact. Keep your own repository updated separately if you distribute the app there too.
