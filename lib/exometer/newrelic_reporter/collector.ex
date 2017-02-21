defmodule Exometer.NewrelicReporter.Collector do
  @moduledoc """
  A collector for our NewRelic metrics.  Allows for storage, aggregation, and retrieval
  of our metric data
  """

  use GenServer

  require Logger

  alias __MODULE__, as: Collector

  def start_link(opts \\ %{}),
    do: GenServer.start_link(Collector, opts, name: Collector)

  @doc """
  Initialize our Collector with empty storage
  """
  def init(opts) do
    Logger.info("Starting NewRelic Collector")

    {:ok, storage: opts}
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
  Dispense all of our stored metrics
  """
  def dispense, do: GenServer.call(Collector, :dispense)

  @doc """
  Peek at the stored metrics without flushing them (useful in debugging)
  """
  def peek, do: GenServer.call(Collector, :peek)

  @doc """
  Retrieve the current stored values and reset storage
  """
  def handle_call(:dispense, _from, opts) do
    {values, opts} = Keyword.get_and_update(opts, :storage, &({&1, %{}}))

    {:reply, values, opts}
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
    entry =
      storage
      |> Map.get(type, %{})
      |> Map.get(name, %{})
      |> Map.update(data_point, [{now, values}], &(&1 ++ [{now, values}]))
    
    updated = Map.put(%{}, type, Map.put(%{}, name, entry))
    Map.merge(storage, updated)
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
