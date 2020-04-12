use Mix.Config

config :logger, level: :debug

if Mix.env() == :dev do
  config :k8s,
    clusters: %{
      dev: %{
        conn: "~/.kube/config"
      }
    }

  config :bonny,
    cluster_name: :dev
end

config :bonny,
  controllers: [
    HenriqueOperator.Controller.V1.SimpleApp
  ]

