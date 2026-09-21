<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, previews, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Chi L Track

### Chicago CTA L Tracker - Station arrival board

An arrival board for your favorite 'L' station.

### Features
* Two "slots" (top/bottom) on your Tidbyt's screen
	* Each slot can show one L route's arrivals at a specific station
	* Slots can be configured to be different stations
	* Each slot is color coded with your line color and train's direction name (or rather acronym)
* Shows multiple upcoming arrivals 
	* First upcoming arrival is in larger, orange font
	* Subsequent arrivals are in small font
	* Trains that are marked as delayed are shown in red
	* On some lines, you might see a suffix after each arrival that denotes an alternate destination
		* e.g. Blue line trains to UIC/Halstead will have "U" after the number
	* A "!" suffix means the train is showing a non-standard destination (e.g. during construction)
* Option to filter out "scheduled" trains
	* CTA's train schedule is notoriously inaccurate, so by default only live-tracked trains are shown. This may however not work too well near train terminus as trains aren't live tracked until they leave the first station.
	* For this case, it might be good to turn on "show scheduled trains" option.
	* Scheduled trains are shown in a grey font
* Animated train separating the slots
	* This can be turned off in app configuration


![Chi L Track for Tidbyt](chi_l_track.gif)