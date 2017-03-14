# Exometer NewRelic Reporter

![travis status](https://api.travis-ci.org/Nitro/exometer_newrelic_reporter.svg)

This uses [exometer](https://github.com/Feuerlabs/exometer) for metrics
gathering and is installed with Pinterest's
[elixometer](https://github.com/pinterest/elixometer) wrapper which makes
tracking timings and generating Exometer stats really simple and easy.

Metrics are, of course, reported to [New Relic](https://newrelic.com/). The
code pretends to be a New Relic python agent and so you may notice that it
shows up as Python in New Relic because New Relic does not yet support Erlang
or Elixir.

## Installation

 1. Add `exometer_newrelic_reporter` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [ {:exometer_newrelic_reporter, github: "nitro/exometer_newrelic_reporter"} ]
   end
   ```

 2. Ensure `exometer_newrelic_reporter` is started **before your application**
    and **before elixometer**:

    ```elixir
    def application do
      [applications: [:exometer_newrelic_reporter, :elixometer]]
    end
    ```

## Configuration

The following assumes you're using Elixometer though configuration should be similar for Exometer:

```elixir
# If we have a NEW_RELIC_LICENSE_KEY, we'll use a New Relic reporter
if System.get_env("NEW_RELIC_LICENSE_KEY") != "" do
  config :exometer_core, report: [
    reporters: ["Elixir.Exometer.NewrelicReporter":
      [
        application_name: "Spacesuit #{Mix.env}",
        license_key: System.get_env("NEW_RELIC_LICENSE_KEY"),
        synthesize_metrics: %{
          "proxyHandler-handle" => "HttpDispatcher"
        }
      ]
    ]
  ]

  config :elixometer, reporter: :"Elixir.Exometer.NewrelicReporter",
    update_frequency: 60_000
end
```

Note the `"Elixir."` prefix when setting our module, this is required by
exometer and Erlang in order to lookup the module.

**Note** you **must** set the `update_frequency` to 60,000 which is the
expected timeframe (60 seconds) for a New Relic agent. Anything else will lead
to unhappiness.

### Synthesized Metrics vs Raw Metrics

By default anything captured by an Elixometer `@timed` annotation will be
sent as histogram metrics suitable for display on a custom dashboard at
New Relic. Fields will all be sent as "Call count" values. These we're
calling Raw Metrics.

But New Relic metrics actually contain a few fields that allow them to be
used in the normal ways you expect. They actually contain:
```elixir
[call_count, total, exclusive, min, max, sum_of_squares]
```

This reporter supports generating metrics that look like this from histograms
used by Exometer's timed traces. You'll probably want to simulate an
`HttpDispatcher` metric, for example, to capture the normal response time and
throughput for your application. In the example configuration above, you see a
section labeled `synthesize_metrics`. This is taking a metrics we've called
`proxyHandler-handle` internally and turning it into a `HttpDispatcher` metric
so that we can see the two main charts on the New Relic application page.

The annotation we used in our application to grab that `proxyHandler-handle`
metric looks like this:

```elixir
  @timed(key: "timed.proxyHandler-handle", units: :millisecond)
  def handle(...) do
	# The thing you want to time
  end
```

**Note:** The `units` entry is important here. Elixometer will by default
capture in microseconds, which is not what New Relic is expecting. If you don't
pass this value, you'll see weird numbers in the New Relic console.
