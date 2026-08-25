defmodule Commonplace.Value.DependencyHygieneTest do
  use ExUnit.Case, async: true

  test "the application declares no runtime dependency outside the standard library" do
    runtime_dependencies =
      for dependency <- Mix.Project.config()[:deps],
          {name, options} = dependency_name_and_options(dependency),
          dependency_enabled?(options, Mix.env()),
          Keyword.get(options, :runtime, true),
          do: name

    assert runtime_dependencies == []
  end

  test "no module under lib references a higher Commonplace layer" do
    files = "lib/**/*.ex" |> Path.wildcard() |> Enum.sort()
    assert files != [], "dependency scan searched zero lib files"

    references =
      for file <- files,
          Regex.match?(~r/Commonplace\.(?!Value(?:\.|\b))/, File.read!(file)),
          do: file

    assert references == [],
           "found higher Commonplace references after scanning #{length(files)} lib files: #{inspect(references)}"
  end

  defp dependency_enabled?(options, environment) do
    case Keyword.get(options, :only) do
      nil -> true
      environments when is_list(environments) -> environment in environments
      enabled_environment -> environment == enabled_environment
    end
  end

  defp dependency_name_and_options({name, _requirement, options}), do: {name, options}
  defp dependency_name_and_options({name, options}) when is_list(options), do: {name, options}
  defp dependency_name_and_options({name, _requirement}), do: {name, []}
end
