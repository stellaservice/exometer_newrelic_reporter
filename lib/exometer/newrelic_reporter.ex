defmodule Exometer.NewrelicReporter do
  require Logger
  use Application

  alias Exometer.NewrelicReporter.{Collector, ReporterSupervisor, Supervisor}

  def start(_type, _opts) do
    Supervisor.start_link()
  end

  @doc """
  Entrypoint to our reporter, invoked by Exometer with configuration options.
  """
  def exometer_init(opts) do 
    Logger.info "New Relic plugin starting with opts: #{inspect(opts)}"
    # This is the first place we have access to the configuration
    # so we start the supervisor here
    ReporterSupervisor.start_link(opts)
    {:ok, opts}
  end

  @doc """
  Invoked by Exometer when there is new data to report.
  """
  def exometer_report(metric, data_point, _extra, values, settings) do
    Logger.info "Got #{inspect(metric)}, #{data_point}, #{inspect(values)}"
    Collector.collect(metric, data_point, values, settings)
    {:ok, settings}
  end

  def exometer_call(_, _, opts),            do: {:ok, opts}
  def exometer_cast(_, opts),               do: {:ok, opts}
  def exometer_info(_, opts),               do: {:ok, opts}
  def exometer_newentry(_, opts),           do: {:ok, opts}
  def exometer_setopts(_, _, _, opts),      do: {:ok, opts}
  def exometer_subscribe(_, _, _, _, opts), do: {:ok, opts}
  def exometer_terminate(_, _),             do: nil
  def exometer_unsubscribe(_, _, _, opts),  do: {:ok, opts}
end
