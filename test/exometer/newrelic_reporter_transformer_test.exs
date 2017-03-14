defmodule ExometerNewrelicReporterTransformerTest do
  use ExUnit.Case
  doctest Exometer.NewrelicReporter.Transformer

  alias Exometer.NewrelicReporter.Transformer

  setup_all do
    %{data: %{timed: %{"proxyHandler-handle" => %{50 => [{1487685123, 63742}],
        75 => [{1487685123, 91211}], 90 => [{1487685123, 180538}],
        95 => [{1487685123, 185563}], 99 => [{1487685123, 196066}],
        999 => [{1487685123, 196066}], :max => [{1487685123, 196066}],
        :mean => [{1487685123, 84964}], :median => [{1487685123, 63742}],
        :min => [{1487685123, 48818}], :n => [{1487685123, 56}]}}},
      min: 48818,
      max: 196066,
      mean: 84964,
      count: 56
    }
  end

  test "Transformation works properly", context do
    expected = [[%{name: "proxyHandler/handle/50", scope: ""}, [63742, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/75", scope: ""}, [91211, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/90", scope: ""}, [180538, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/95", scope: ""}, [185563, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/99", scope: ""}, [196066, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/999", scope: ""}, [196066, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/max", scope: ""}, [196066, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/mean", scope: ""}, [84964, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/median", scope: ""}, [63742, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/min", scope: ""}, [48818, 0, 0, 0, 0, 0]],
      [%{name: "proxyHandler/handle/n", scope: ""}, [56, 0, 0, 0, 0, 0]]]

    assert expected == Transformer.transform(context[:data])
  end

  test "Synthesizing New Relic metrics", context do
    %{min: min, max: max, mean: mean, count: count} = context

    expected = [
      [%{name: "HttpDispatcher", scope: ""},
      [count, count * mean / 1000, count * mean / 1000, min / 1000, max / 1000, 0]]
    ]

    synthesize_metrics = %{
      "proxyHandler-handle" => "HttpDispatcher"
    }

    assert expected == Transformer.synthesize(context[:data], synthesize_metrics)
  end
end
