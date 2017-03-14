defmodule Exometer.NewrelicReporter.Collector do
  @moduledoc """
  A collector for our NewRelic metrics.  Allows for storage, aggregation, and retrieval
  of our metric data
  """

  use GenServer

  require Logger

  alias __MODULE__, as: Collector

  def start_link(opts \\ %{}) do
    GenServer.start_link(Collector, opts, name: Collector)
  end

  @doc """
  Initialize our Collector with empty storage
  """
  def init(opts) do
    Logger.info("Starting NewRelic Collector")
    {:ok, settings: opts, storage: %{}}
  end

  @doc """
  Record the metric data at the given key on the GenServer
  """
  def collect(metric, data_point, values, settings) do
    GenServer.cast(Collector, {metric, data_point, values, settings})
  end

  @doc """
  Asynchronsously store our metric data by the type and name derived from the stat key
  """
  def handle_cast({metric, data_point, values, settings}, opts) do
    storage = 
      storage_key(metric, data_point)
      |> store(values, opts)

    opts = [storage: storage, settings: settings]

    {:noreply, opts}
  end

  @doc """
  Empty all of our stored metrics
  """
  def empty, do: GenServer.call(Collector, :empty)

  @doc """
  Peek at the stored metrics without flushing them. Used when synthesizing
  metrics into New Relic combined metrics.
  """
  def peek, do: GenServer.call(Collector, :peek, 100000)

  @doc """
  Retrieve the current stored values and reset storage
  """
  def handle_call(:empty, _from, opts) do
    {:reply, :ok, Keyword.put(opts, :storage, %{})}
  end

  @doc """
  Retrieve the current stored values without resetting
  """
  def handle_call(:peek, _from, opts) do
    values = Keyword.fetch!(opts, :storage)

    {:reply, values, opts}
  end

  defp store(key, values, opts) do
    now = :os.system_time(:seconds)
    storage = Keyword.fetch!(opts, :storage)

    {type, name, data_point} = key
    entry = storage
      |> Map.get(type, %{})
      |> Map.get(name, %{})
      |> Map.update(data_point, [{now, values}], &(&1 ++ [{now, values}]))

    updated = %{
      type => %{
        name => entry
      }
    }
    
    MapUtils.deep_merge(storage, updated)
  end

  defp storage_key(metric, data_point) do
    [_app, _env, type] = Enum.slice(metric, 0..2)
    name =
      metric
      |> Enum.slice(3..-1)
      |> Enum.join("/")

    {type, name, data_point}
  end
end
