defmodule ExometerNewrelicReporterCollectorTest do
  use ExUnit.Case
  doctest Exometer.NewrelicReporter.Collector

  alias Exometer.NewrelicReporter.Collector

  setup_all do
    Collector.start_link()
    :ok
  end

  test "Updating storage works" do
    expected = %{50 => [{1489428062, 63742}],
                  75 => [{1489428062, 91211}], 90 => [{1489428062, 180538}],
                  95 => [{1489428062, 185563}], 99 => [{1489428062, 196066}],
                  999 => [{1489428062, 196066}], :max => [{1489428062, 196066}],
                  :mean => [{1489428062, 84964}],
                  :median => [{1489428062, 63742}],
                  :min => [{1489428062, 48818}], :n => [{1489428062, 56}]}

    for {key, values} <- [ {50, 63742}, {75, 91211}, {90, 180538}, {95, 185563},
          {99, 196066}, {999, 196066}, {:max, 196066}, {:mean, 84964}, {:median, 63742},
          {:min, 48818}, {:n, 56} ] do
      Collector.collect([:elixometer, :timers, :timed, "proxyHandler-handle"], key, values, %{})
    end

    assert %{timed: %{"proxyHandler-handle" => timings}} = Collector.peek()
    assert Map.keys(timings) == Map.keys(expected)
    Enum.each(timings, fn {key, values} ->
      assert [{time, value}] = values
      assert is_integer(time)
      assert is_integer(value)
      [{_, expected_value}] = expected[key]
      assert expected_value == value
    end)

  end

  test "Can support multiple metrics in the same storage" do
    for {key, values} <- [ {50, 63742}, {75, 91211}, {90, 180538} ] do
      Collector.collect([:elixometer, :timers, :timed, "proxyHandler-handle"], key, values, %{})
      Collector.collect([:elixometer, :timers, :timed, "anotherMetric"], key, values, %{})
    end

    assert %{timed: %{"proxyHandler-handle" => _}} = Collector.peek()
    assert %{timed: %{"anotherMetric" => _}} = Collector.peek()
  end
end
