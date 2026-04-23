defmodule JioNLP.DataFetcherTest do
  use ExUnit.Case, async: true

  alias JioNLP.DataFetcher

  describe "cache_dir/1" do
    test "derives a user-cache path keyed by version" do
      path = DataFetcher.cache_dir("2026.04.1")
      assert String.ends_with?(path, "jionlp_ex/2026.04.1")
    end

    test "different versions yield different dirs" do
      a = DataFetcher.cache_dir("2026.04.1")
      b = DataFetcher.cache_dir("2026.05.1")
      assert a != b
    end
  end

  describe "data_version/0" do
    test "falls back to the baked-in default" do
      Application.delete_env(:jionlp_ex, :data_version)
      assert DataFetcher.data_version() == DataFetcher.default_data_version()
    end

    test "respects :data_version config override" do
      Application.put_env(:jionlp_ex, :data_version, "9999.99.9")
      on_exit(fn -> Application.delete_env(:jionlp_ex, :data_version) end)
      assert DataFetcher.data_version() == "9999.99.9"
    end
  end
end
