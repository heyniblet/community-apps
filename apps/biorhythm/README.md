<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

## Biorhythm

---

This app renders the physical (<b>P</b>), emotional (<b>E</b>), and intellectual (<b>I</b>) biorhythm curves based on your birthdate.
 
The idea of biorhythm theory was developed by Wilhelm Fliess in the late 19th century.  It is based on the *pseudoscientific* idea that our lives are significantly affected by rythmic cycles. They consist of a 23-day physical cycle, a 28-day emotional cycle, and a 33-day intellectual cycle. Biorhythms were popular in the United States during the late 1970s.

This idea has been independently tested and <span style="color:red">invalidated</span>.  It is a fun theory that can be used for your amusement.  It's been said that it is very useful for giving an excuse for locking your keys in the car or blowing off your workout.

In each of the displayed curves, the darker first point is for today.

<img width="800" alt="image" src="./biorhythm.png">

<p>

The schema data is your birthday.  If no date is entered, then today is used as the default birthday.
</p>

<img width="500" alt="image" src="./biorhythm_schema.png">

