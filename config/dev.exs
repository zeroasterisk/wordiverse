use Mix.Config

# monitor metrics for tests
config :elixometer, reporter: :exometer_report_influxdb,
  update_frequency: 500,
  env: "test",
  metric_prefix: "wordza"

config :exometer_core, report: [
  reporters: [
    {:exometer_report_tty, []},
    exometer_report_influxdb: [
      protocol: :http,
      host: "localhost",
      port: 8086,
      db: "dev"
    ]
  ]
]
