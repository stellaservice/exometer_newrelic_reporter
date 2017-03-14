defmodule Exometer.NewrelicReporter.ReporterSupervisor do
  require Logger
  use Supervisor

  require IEx

  alias Exometer.NewrelicReporter.{Collector, Reporter}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    case Keyword.fetch(opts, :license_key) do
      {:ok, _} -> supervise_children(opts) 
      _ -> {:stop, :error, opts}
    end
  end

  defp supervise_children(opts) do
    worker_opts = [ restart: :permanent ]

    children = [
      worker(Collector, [opts], worker_opts),
      worker(Reporter, [opts], worker_opts)
    ]

    sup_opts = [
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5,
      name: Collector.Supervisor
    ]

    supervise(children, sup_opts)
  end
end
