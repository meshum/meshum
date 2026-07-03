# Warnings dialyzer should ignore; picked up automatically by dialyxir.
#
# Note: use regexes here, not {file, warning} tuples. Tuple filters are
# compared against the raw (absolute) source path dialyzer reports, so they
# never match dep paths portably; regexes are matched against the formatted
# "path:line:warning_type message" short description instead.
[
  # False positive from code Phoenix.Router macros generate inside our router
  # modules; dialyzer attributes it to the dep file. The generated route-match
  # clause pattern-matches a tuple that dialyzer proves can only be :error.
  ~r"deps/phoenix/lib/phoenix/router\.ex:\d+:pattern_match "
]
