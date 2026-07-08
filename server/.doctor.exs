%Doctor.Config{
  # The MeshumWeb/MeshumGateway meta modules are Phoenix-generated `use`
  # targets, not APIs of their own.
  ignore_modules: [MeshumWeb, MeshumGateway],
  ignore_paths: [~r(^test/)],
  min_module_doc_coverage: 100,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 100,
  min_overall_moduledoc_coverage: 100,
  min_overall_spec_coverage: 0,
  exception_moduledoc_required: true,
  struct_type_spec_required: true,
  raise: false,
  reporter: Doctor.Reporters.Full,
  # Without this, `mix doctor` from the umbrella root silently checks almost
  # nothing and passes.
  umbrella: true,
  failed: false
}
