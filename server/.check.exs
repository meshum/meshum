[
  tools: [
    # The doctor dep lives at the umbrella root, so ex_check's default per-app
    # package detection skips it in every child app. Run it once from the root
    # instead; `.doctor.exs` sets `umbrella: true` to aggregate all apps.
    {:doctor, "mix doctor", detect: [], umbrella: [recursive: false]},
    # `--skip` honors per-finding `.sobelow-skips` fingerprints (generated via
    # `mix sobelow --mark-skip-all`), so individual known-safe findings can be
    # accepted without disabling a whole check type app-wide via
    # `.sobelow-conf`'s `ignore:`.
    {:sobelow, "mix sobelow --exit --skip", umbrella: [recursive: true]}
  ]
]
