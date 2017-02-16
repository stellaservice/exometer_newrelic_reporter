defmodule Exometer.NewrelicReporter.Transformer do
  @moduledoc """
  Transform data into a format that can be sent to New Relic
  """

  require Logger

  def transform(data) when is_map(data) do
    Logger.debug "Preparing to send to New Relic: #{inspect(data)}"
    data
    |> Enum.flat_map(fn {type, values} -> transform({type, values}) end)
  end

  def transform({:timed, metrics}) do
    metrics |> Enum.map(&transform_one/1)
  end

  def transform_one({name, values}) when length(values) == 0 do
    [ %{name: newrelic_name(name), scope: ""}, [ 0,0,0,0,0,0 ] ]
  end

  def transform_one({name, values}) do
    # New Relic metrics are: [{ name: name, scope: "" }, [ count, total, exclusive_time, min, max, sum_of_squares ]]
    transformed_values = values |> Enum.map(fn {_t, v} -> v end)
    [ %{name: newrelic_name(name), scope: ""}, transformed_values ++ [ 0,0,0,0,0 ] ]
  end

  # Transform dashes into slashes for New Relic namespacing
  defp newrelic_name(name) do
    name
    |> String.split("-")
    |> Enum.join("/")
  end
end
