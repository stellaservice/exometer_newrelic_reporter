defmodule Exometer.NewrelicReporter.Transformer do
  @moduledoc """
  Transform data into a format that can be sent to New Relic
  """

  require Logger

  def transform(data) when is_map(data) do
    Logger.debug "Preparing to send to New Relic: #{inspect(data)}"
    data
    |> Enum.flat_map(&transform/1)
  end

  def transform({:timed, metrics}) do
    metrics |> Enum.flat_map(&transform_metric/1)
  end
  
  # %{timed: %{"proxyHandler-handle" => %{50 => [{1487680368, 1234}]}}}

  defp transform_metric({name, values}) do
    values |> Enum.map(fn {data_point, val} -> transform_one(name, data_point, val) end)
  end

  defp transform_one(name, data_point, val) when length(val) == 0 do
    [ %{name: newrelic_name(name, data_point), scope: ""}, [ 0,0,0,0,0,0 ] ]
  end

  defp transform_one(name, data_point, val) do
    # New Relic metrics are:
    # [{ name: name, scope: "" }, [ count, total, exclusive_time, min, max, sum_of_squares ]]
    transformed_val =
      val
      |> Enum.map(fn {_t, v} -> v end)

    [ %{name: newrelic_name(name, data_point), scope: ""}, transformed_val ++ [ 0,0,0,0,0 ] ]
  end

  @doc """
  Take a map of metrics to synthesize metrics and process them. Only supports
  timers currently.
  """
  def synthesize(data, synth_list) when is_map(data) do
    synth_list
    |> Enum.flat_map(fn {metric_name, output_name} -> 
         data 
         |> Enum.map(fn {type, value} -> synthesize_metric({type, value}, metric_name, output_name) end)
       end)
  end

  @doc """
  Take a timer histogram and synthesize the fields we would put in a normal
  New Relic metric. Uses the mean*count to fudge total_time and exclusive_time.
  """
  def synthesize_metric({:timed, metrics}, metric_name, output_name) do
    Logger.debug "Preparing to send synthesized to New Relic: #{inspect(metrics)} as #{output_name}"
    synthesize_one(output_name, Map.get(metrics, metric_name))
  end

  def synthesize_one(output_name, values) when length(values) == 0 do
    [ %{name: output_name, scope: ""}, [ 0,0,0,0,0,0 ] ]
  end

  def synthesize_one(output_name, values) do
    %{min: [{_, min}], max: [{_, max}], mean: [{_, mean}], n: [{_, count}]} = values
    [ %{name: output_name, scope: ""}, [ count, count * mean / 1000, count * mean / 1000, min / 1000, max / 1000, 0 ] ]
  end

  # Transform dashes into slashes for New Relic namespacing
  defp newrelic_name(name, data_point) do
    String.split(name, "-") ++ [data_point]
    |> Enum.join("/")
  end
end
