defmodule Mix.Tasks.Jionlp.FetchData do
  @moduledoc """
  Pre-fetch the JioNLP dictionary bundle so it's available before the first
  application start. Useful for CI, container builds, or air-gapped deploys
  where you'd rather see a download fail fast than during `Application.start/2`.

  ## Usage

      mix jionlp.fetch_data               # use configured version
      mix jionlp.fetch_data --version 2026.04.1
      mix jionlp.fetch_data --force       # re-download even if cache exists

  The data is stored under `:filename.basedir(:user_cache, "jionlp_ex")` so
  subsequent runs (across projects) reuse the cache.
  """

  use Mix.Task

  @shortdoc "Pre-fetch the JioNLP dictionary bundle"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [version: :string, force: :boolean],
        aliases: [v: :version, f: :force]
      )

    Application.ensure_all_started(:jionlp_ex)
    |> case do
      {:ok, _} -> :ok
      # Already-started or partial-start is fine; we just need the env.
      _ -> :ok
    end

    version = opts[:version] || JioNLP.DataFetcher.data_version()
    target = JioNLP.DataFetcher.cache_dir(version)

    if opts[:force] do
      Mix.shell().info("Removing cached #{target}")
      File.rm_rf!(target)
    end

    # Temporarily pin version for this invocation.
    Application.put_env(:jionlp_ex, :data_version, version)

    case JioNLP.DataFetcher.ensure() do
      {:ok, path} ->
        Mix.shell().info("JioNLP data v#{version} ready at #{path}")

      {:error, reason} ->
        Mix.raise("JioNLP data fetch failed: #{inspect(reason)}")
    end
  end
end
