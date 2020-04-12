defmodule HenriqueOperator.Controller.V1.SimpleApp do

  require Logger
  use Bonny.Controller
  @rule {"apps", ["deployments"], ["*"]}
  @rule {"", ["services"], ["*"]}
  @rule {"", ["ingress"], ["*"]}


  @scope :namespaced
  @names %{
    plural: "simpleapps",
    singular: "simpleapp",
    kind: "SimpleApp"
  }

  @doc """
  Permitindo reconciliação
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(payload) do
    track_event(:reconcile, payload)
    :ok
  end

  @doc """
  Definindo como será a construção do app
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(payload) do
    track_event(:add, payload)
    resources = parse(payload)

    with {:ok, _} <- K8s.Client.create(resources.deployment) |> run,
         {:ok, _} <- K8s.Client.create(resources.ingress) |> run,
         {:ok, _} <- K8s.Client.create(resources.service) |> run do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Alterando o app
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(payload) do
    resources = parse(payload)

    with {:ok, _} <- K8s.Client.patch(resources.deployment) |> run,
         {:ok, _} <- K8s.Client.create(resources.ingress) |> run,
         {:ok, _} <- K8s.Client.patch(resources.service) |> run do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  deletando o app
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(payload) do
    track_event(:delete, payload)
    resources = parse(payload)

    with {:ok, _} <- K8s.Client.delete(resources.deployment) |> run,
         {:ok, _} <- K8s.Client.delete(resources.ingress) |> run,
         {:ok, _} <- K8s.Client.delete(resources.service) |> run do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  defp parse(%{
         "metadata" => %{"name" => name, "namespace" => ns},
         "spec" => %{"simpleapp" => simpleapp, "image" => dockerimage, "host" => ingresshost, "port" => serviceport}
       }) do
    deployment = gen_deployment(ns, name, simpleapp, dockerimage, serviceport)
    ingress = gen_ingress(ns, name, simpleapp, ingresshost, serviceport)
    service = gen_service(ns, name, simpleapp, serviceport)

    %{
      deployment: deployment,
      ingress: ingress,
      service: service
    }
  end

  defp gen_service(ns, name, _simpleapp, serviceport) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => %{"app" => name}
      },
      "spec" => %{
        "ports" => [%{"port" => serviceport, "protocol" => "TCP"}],
        "selector" => %{"app" => name},
        "type" => "NodePort"
      }
    }
  end

  defp gen_ingress(ns, name, _simpleapp, ingresshost, serviceport) do
    %{
      "apiVersion" => "networking.k8s.io/v1beta1",
      "kind" => "Ingress",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "nginx.ingress.kubernetes.io/rewrite-target" => "/",
        "labels" => %{"app" => name}
      },
      "spec" => %{
        "rules" => %{
          "host" => ingresshost,
          "http" => %{
            "paths" => %{
              "path" => "/",
              "backend" => %{
                "serviceName" => name,
                "servicePort" => serviceport
              }
            }
          } 
        }
      
      }
    }
  end

  defp gen_deployment(ns, name, simpleapp, dockerimage, serviceport) do
    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => %{"app" => name}
      },
      "spec" => %{
        "replicas" => 2,
        "selector" => %{
          "matchLabels" => %{"app" => name}
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{"app" => name}
          },
          "spec" => %{
            "containers" => [
              %{
                "name" => name,
                "image" => dockerimage,
                "env" => [%{"name" => "TesteNginx", "value" => simpleapp}],
                "ports" => [%{"containerPort" => serviceport}]
              }
            ]
          }
        }
      }
    }
  end

  defp run(%K8s.Operation{} = op),
    do: K8s.Client.run(op, Bonny.Config.cluster_name())

  defp track_event(type, resource),
    do: Logger.info("#{type}: #{inspect(resource)}")
end
