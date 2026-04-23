defmodule JioNLP.DataFetcher do
  @moduledoc """
  Downloads and caches the JioNLP dictionary bundle from
  [`jionlp_rs` GitHub Releases](https://github.com/Psli/jionlp_rs/releases).

  Follows the `tzdata` pattern: data is fetched once, cached in the user's
  cache directory, and reused across application restarts. The data version
  is a date-based tag (`YYYY.MM.N`) that is decoupled from the library's own
  version — you can pull a newer dictionary without upgrading `jionlp_ex`.

  ## Configuration

  ```elixir
  # Pin which data version to fetch (defaults to the value baked into this
  # library at compile time — see `@default_data_version`).
  config :jionlp_ex, :data_version, "2026.04.1"

  # Override the base URL (e.g. for an internal mirror).
  config :jionlp_ex, :data_base_url,
    "https://github.com/Psli/jionlp_rs/releases/download"

  # Skip fetching entirely and use a local directory (e.g. for CI or air-gapped
  # setups). If set, nothing is downloaded.
  config :jionlp_ex, :dictionary_path, "/opt/jionlp/data"
  ```
  """

  require Logger

  # When you cut a new `jionlp-data-v*` release, bump this and ship it as a
  # code change. End users still get the new data automatically on next
  # deploy; they don't have to do anything.
  @default_data_version "2026.04.1"

  @default_base_url "https://github.com/Psli/jionlp_rs/releases/download"

  @doc """
  Return the directory that holds the dictionary for the configured version,
  downloading it first if the cache is empty. Idempotent.

  Returns `{:ok, path}` on success, `{:error, reason}` on failure.
  """
  @spec ensure!() :: String.t()
  def ensure! do
    case ensure() do
      {:ok, path} -> path
      {:error, reason} -> raise "JioNLP.DataFetcher: #{inspect(reason)}"
    end
  end

  @spec ensure() :: {:ok, String.t()} | {:error, term}
  def ensure do
    version = data_version()
    target = cache_dir(version)

    if data_complete?(target) do
      {:ok, target}
    else
      Logger.info("JioNLP: fetching dictionary v#{version} → #{target}")
      download_and_extract(version, target)
    end
  end

  @doc "Absolute path to the cache directory for a given data version."
  @spec cache_dir(String.t()) :: String.t()
  def cache_dir(version) do
    :filename.basedir(:user_cache, ~c"jionlp_ex")
    |> to_string()
    |> Path.join(version)
  end

  @doc "Currently configured data version. Falls back to the baked-in default."
  @spec data_version() :: String.t()
  def data_version do
    Application.get_env(:jionlp_ex, :data_version, @default_data_version)
  end

  @doc false
  def default_data_version, do: @default_data_version

  # ── internal ────────────────────────────────────────────────────────────

  defp data_complete?(dir) do
    # Rough sanity check — the bundle always contains china_location.zip.
    # Avoids half-extracted directories being treated as complete.
    File.exists?(Path.join(dir, "china_location.zip"))
  end

  defp download_and_extract(version, target) do
    with {:ok, archive_bytes} <- fetch_body(archive_url(version)),
         {:ok, expected_sha} <- fetch_checksum(version),
         :ok <- verify_sha256(archive_bytes, expected_sha),
         :ok <- extract_tar_gz(archive_bytes, target) do
      {:ok, target}
    end
  end

  defp archive_url(version) do
    base = Application.get_env(:jionlp_ex, :data_base_url, @default_base_url)
    "#{base}/jionlp-data-v#{version}/jionlp-data-v#{version}.tar.gz"
  end

  defp checksum_url(version) do
    archive_url(version) <> ".sha256"
  end

  defp fetch_checksum(version) do
    case fetch_body(checksum_url(version)) do
      {:ok, bytes} ->
        bytes |> String.trim() |> parse_sha256()

      {:error, _} = err ->
        err
    end
  end

  defp parse_sha256(text) do
    # Accept "<hex>" or "<hex>  filename"
    text
    |> String.split()
    |> List.first()
    |> case do
      nil -> {:error, :empty_checksum}
      hex when byte_size(hex) == 64 -> {:ok, String.downcase(hex)}
      _ -> {:error, :malformed_checksum}
    end
  end

  defp verify_sha256(bytes, expected) do
    actual = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

    if actual == expected do
      :ok
    else
      {:error, {:sha256_mismatch, expected: expected, actual: actual}}
    end
  end

  defp fetch_body(url) do
    :inets.start()
    :ssl.start()

    headers = [{~c"user-agent", ~c"jionlp_ex-data-fetcher"}]

    http_opts = [
      timeout: 60_000,
      connect_timeout: 15_000,
      autoredirect: true,
      ssl: ssl_opts()
    ]

    request_opts = [body_format: :binary]

    case :httpc.request(:get, {String.to_charlist(url), headers}, http_opts, request_opts) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, body}

      {:ok, {{_, status, _}, _headers, _body}} ->
        {:error, {:http_status, status, url}}

      {:error, reason} ->
        {:error, {:http_error, reason, url}}
    end
  end

  # `:httpc` defaults to weak SSL opts. Use the OS CA bundle (via :public_key's
  # `cacerts_get/0`, available in OTP 25+) so we get proper cert validation.
  defp ssl_opts do
    cacerts =
      if function_exported?(:public_key, :cacerts_get, 0) do
        :public_key.cacerts_get()
      else
        []
      end

    [
      verify: :verify_peer,
      cacerts: cacerts,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ],
      depth: 3
    ]
  end

  defp extract_tar_gz(bytes, target_parent) do
    # Archive layout: `data/<files...>`. We extract into `target_parent/..`
    # so the resulting tree is `target_parent/data/<files>`. But we want the
    # files directly under `target_parent`, so extract to a scratch dir and
    # rename.
    File.mkdir_p!(target_parent)
    scratch = target_parent <> ".tmp"
    File.rm_rf!(scratch)
    File.mkdir_p!(scratch)

    case :erl_tar.extract({:binary, bytes}, [:compressed, {:cwd, String.to_charlist(scratch)}]) do
      :ok ->
        inner = Path.join(scratch, "data")

        cond do
          File.dir?(inner) ->
            # Move every entry of `scratch/data/` into `target_parent/`.
            File.rm_rf!(target_parent)
            File.rename!(inner, target_parent)
            File.rm_rf!(scratch)
            :ok

          true ->
            File.rm_rf!(scratch)
            {:error, {:unexpected_layout, target_parent}}
        end

      {:error, reason} ->
        File.rm_rf!(scratch)
        {:error, {:tar_error, reason}}
    end
  end
end
