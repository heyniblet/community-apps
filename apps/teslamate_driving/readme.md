<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

Requires Home Assistant and Teslamate (or compatible API)

Add the following helpers in `configuration.yaml` to get trip progress

```yaml
# Store the total distance for each car
input_number:
  tesla_1_trip_total:
    name: "MyTesla"
    min: 0
    max: 5000
    unit_of_measurement: mi
    icon: mdi:map-marker-distance

template:
  - sensor:
      - name: "MyTesla Progress"
        unique_id: teslamate_1_trip_progress
        unit_of_measurement: "%"
        icon: mdi:progress-clock
        state: >
          {% set current = states('sensor.tesla_active_route_distance_to_arrival') | float(0) %}
          {% set total = states('input_number.tesla_1_trip_total') | float(0) %}
          {% if total > 0 and current <= total %}
            {{ ((1 - (current / total)) * 100) | round(0) }}
          {% else %}
            0
          {% endif %}
```

Add to `automations.yaml`

```yaml
- alias: "Tesla Trip: Set Total Distance"
  trigger:
    - platform: state
      entity_id: sensor.tesla_active_route_destination
  condition:
    # Trigger only when a destination is set (state is not empty/unknown)
    - condition: template
      value_template: "{{ trigger.to_state.state not in ['unknown', 'unavailable', none] and trigger.to_state.state | string | length > 0 }}"
    # Ensure there's a valid distance to set
    - condition: numeric_state
      entity_id: sensor.tesla_active_route_distance_to_arrival
      above: 0
  action:
    - service: input_number.set_value
      target:
        entity_id: input_number.tesla_1_trip_total
      data:
        value: "{{ states('sensor.tesla_active_route_distance_to_arrival') }}"
  mode: single
```
