[
  tools: [
    # The doctor dep lives at the umbrella root, so ex_check's default per-app
    # package detection skips it in every child app. Run it once from the root
    # instead; `.doctor.exs` sets `umbrella: true` to aggregate all apps.
    {:doctor, "mix doctor", detect: [], umbrella: [recursive: false]}
  ]
]
