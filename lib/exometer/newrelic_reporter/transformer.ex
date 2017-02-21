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
    metrics |> Enum.flat_map(&transform_metric/1)
  end
  
  # %{timed: %{"proxyHandler-handle" => %{50 => [{1487680368, 1234}]}}}

  def transform_metric({name, values}) do
    values |> Enum.map(fn {data_point, val} -> transform_one(name, data_point, val) end)
  end

  def transform_one(name, data_point, val) when length(val) == 0 do
    [ %{name: newrelic_name(name, data_point), scope: ""}, [ 0,0,0,0,0,0 ] ]
  end

  def transform_one(name, data_point, val) do
    # New Relic metrics are:
    # [{ name: name, scope: "" }, [ count, total, exclusive_time, min, max, sum_of_squares ]]
    transformed_val =
      val
      |> Enum.map(fn {_t, v} -> v end)

    [ %{name: newrelic_name(name, data_point), scope: ""}, transformed_val ++ [ 0,0,0,0,0 ] ]
  end

  # Transform dashes into slashes for New Relic namespacing
  defp newrelic_name(name, data_point) do
    String.split(name, "-") ++ [data_point]
    |> Enum.join("/")
  end
end
