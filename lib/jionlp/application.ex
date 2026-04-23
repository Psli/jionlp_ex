defmodule JioNLP.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    case resolve_dict_path() do
      {:ok, path} ->
        case JioNLP.Native.init_dictionaries(path) do
          :ok -> Logger.info("JioNLP dictionaries initialized from #{path}")
          {:error, reason} -> Logger.error("JioNLP init failed: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.error("JioNLP dictionary resolution failed: #{inspect(reason)}")
    end

    Supervisor.start_link([], strategy: :one_for_one, name: JioNLP.Supervisor)
  end

  # Resolution order:
  #   1. `config :jionlp_ex, :dictionary_path` — explicit override (air-gapped
  #      environments, custom dicts).
  #   2. `priv/data/` inside this package — populated in dev by
  #      `scripts/sync_dictionary.sh` and used by the Hex tarball IF bundled.
  #      The published Hex package does NOT bundle this directory any more
  #      (pull-based strategy), but we keep the fallback for local dev and
  #      for anyone who vendors the data manually.
  #   3. `JioNLP.DataFetcher.ensure/0` — download from
  #      `github.com/Psli/jionlp_rs/releases` into the user cache dir
  #      (`~/.cache/jionlp_ex/data/<VER>/` on Linux, platform-equivalent
  #      elsewhere). This is the normal path for end users.
  defp resolve_dict_path do
    cond do
      override = Application.get_env(:jionlp_ex, :dictionary_path) ->
        {:ok, override}

      File.exists?(priv_data_marker()) ->
        {:ok, Path.dirname(priv_data_marker())}

      Application.get_env(:jionlp_ex, :auto_fetch, true) ->
        JioNLP.DataFetcher.ensure()

      true ->
        {:error, :no_dictionary_available}
    end
  end

  defp priv_data_marker do
    # Pick a file that is always in data/ to detect a populated priv/data/.
    Path.join([:code.priv_dir(:jionlp_ex), "data", "china_location.zip"])
  end
end
