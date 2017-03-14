defmodule ExometerNewrelicReporterTest do
  use ExUnit.Case
  doctest Exometer.NewrelicReporter

  alias Exometer.NewrelicReporter

  test "it starts the supervisor if a New Relic license key is present" do
    NewrelicReporter.exometer_init(
      [license_key: "empty", application_name: "beowulf"]
    )

    pid = Process.whereis(NewrelicReporter.ReporterSupervisor)
    assert pid != nil
  end

  test "it does not start the supervisor if not configured" do
    NewrelicReporter.exometer_init([license_key: "empty"])

    assert Process.whereis(NewrelicReporter.ReporterSupervisor) == nil
  end
end
