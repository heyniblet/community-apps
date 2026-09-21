<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

**Configuration or behavior difference:** Direct credential settings were replaced by `endpoint_url` and `relay_token`. Old settings can produce no output. This version requires a compatible relay and new configuration.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# FitbitWeight for Tidbyt

Displays your weight, and optionally, your body fat percentage or BMI from Fitbit. You can enter your data manually into Fitbit, or you can get a supported scale like the Aria to automatically update your fitbit whenever you weight yourself.

Motivate yourself by displaying your progress!

Instructions:

Step 1: Register Your Fitbit App
Go to https://dev.fitbit.com/apps and sign in with your Fitbit account

Click Register an App

Fill out the form:

Application Name: Tidbyt Weight Tracker (or anything)

Description: Displays Fitbit weight data on Tidbyt

Application Website: https://tidbyt.com (or any URL)

Organization: Your name

Organization Website: Any URL

OAuth 2.0 Application Type: Personal (not Client)

Redirect URL: http://localhost/ ← EXACTLY this with trailing slash

Terms of Service URL: https://example.com

Privacy Policy URL: https://example.com

Click Create

Step 2: Copy Your Credentials

After creation, you'll see:


OAuth 2.0 Client ID: 99XXXX         ← Copy this
Client Secret:    3faf91e18b4799... ← Copy this  

Step 3: 

Open this URL (replace YOUR_CLIENT_ID):

https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost/&scope=weight

When you log in and approve, you'll be redirected to a URL like this:

http://localhost/?code=1747cff2357579c7d594fce4738445f87abb28cd#_=_

Copy the "Code" without the #_=_ garbage at the end of the line. In this case the code you need is:
1747cff2357579c7d594fce4738445f87abb28cd

Step 4:

Enter the Fitbit Client ID and Fitbit Client Secret as the first two config items. Then paste the above "Fitbit Auth Code".

Select the period, measurement and secondary measurement you want to display.

![FitbitWeight for Tidbyt](fitbitweight.gif)
