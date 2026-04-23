defmodule JioNLP.Extracted do
  @moduledoc """
  A span of text matched by one of the `JioNLP.extract_*` functions, with the
  byte offset at which it was found in the original input.
  """
  @enforce_keys [:text, :offset]
  defstruct [:text, :offset]

  @type t :: %__MODULE__{
          text: String.t(),
          offset: {non_neg_integer, non_neg_integer}
        }
end

defmodule JioNLP.PlateInfo do
  @moduledoc "Result of `JioNLP.parse_motor_vehicle_licence_plate/1`."
  @enforce_keys [:car_loc, :car_type]
  defstruct [:car_loc, :car_type, car_size: nil]

  @type t :: %__MODULE__{
          car_loc: String.t(),
          car_type: String.t(),
          car_size: nil | String.t()
        }
end

defmodule JioNLP.IdCardInfo do
  @moduledoc "Result of `JioNLP.parse_id_card/1`."
  @enforce_keys [
    :province,
    :birth_year,
    :birth_month,
    :birth_day,
    :gender,
    :check_code
  ]
  defstruct [
    :province,
    :city,
    :county,
    :birth_year,
    :birth_month,
    :birth_day,
    :gender,
    :check_code
  ]

  @type t :: %__MODULE__{
          province: String.t(),
          city: nil | String.t(),
          county: nil | String.t(),
          birth_year: String.t(),
          birth_month: String.t(),
          birth_day: String.t(),
          gender: String.t(),
          check_code: String.t()
        }
end

defmodule JioNLP.RadicalInfo do
  @moduledoc "Per-char radical info returned by `JioNLP.char_radical/1`."
  @enforce_keys [:char, :radical, :structure, :corner_coding, :stroke_order, :wubi_coding]
  defstruct [:char, :radical, :structure, :corner_coding, :stroke_order, :wubi_coding]

  @type t :: %__MODULE__{
          char: String.t(),
          radical: String.t(),
          structure: String.t(),
          corner_coding: String.t(),
          stroke_order: String.t(),
          wubi_coding: String.t()
        }
end

defmodule JioNLP.PhoneInfo do
  @moduledoc "Result of `JioNLP.phone_location/1`."
  @enforce_keys [:number, :phone_type]
  defstruct [:number, :province, :city, :phone_type, :operator]

  @type t :: %__MODULE__{
          number: String.t(),
          province: nil | String.t(),
          city: nil | String.t(),
          phone_type: String.t(),
          operator: nil | String.t()
        }
end

defmodule JioNLP.LocationMatch do
  @moduledoc "A single admin-division match found by `JioNLP.recognize_location/1`."
  @enforce_keys [:name, :level, :offset]
  defstruct [:name, :level, :offset]

  @type level :: String.t()
  @type t :: %__MODULE__{
          name: String.t(),
          level: level,
          offset: {non_neg_integer, non_neg_integer}
        }
end

defmodule JioNLP.ParsedLocation do
  @moduledoc "Consolidated province/city/county returned by `JioNLP.parse_location/1`."
  defstruct [:province, :city, :county]

  @type t :: %__MODULE__{
          province: nil | String.t(),
          city: nil | String.t(),
          county: nil | String.t()
        }
end

defmodule JioNLP.LocationParseResult do
  @moduledoc """
  Full Python-parity result of `JioNLP.parse_location_full/3` — equivalent
  to Python's `jio.parse_location(text, town_village=bool, change2new=bool)`
  dict output: province / city / county / detail / full_location /
  orig_location, plus optional town / village when `town_village: true`.
  """
  @enforce_keys [
    :province, :city, :county, :detail, :full_location, :orig_location,
    :town, :village
  ]
  defstruct [
    :province, :city, :county, :detail, :full_location, :orig_location,
    :town, :village
  ]

  @type t :: %__MODULE__{
          province: nil | String.t(),
          city: nil | String.t(),
          county: nil | String.t(),
          detail: String.t(),
          full_location: String.t(),
          orig_location: String.t(),
          town: nil | String.t(),
          village: nil | String.t()
        }
end

defmodule JioNLP.MoneyInfo do
  @moduledoc """
  Result of `JioNLP.parse_money/1`.

  * `num` is the value (lower bound for ranges).
  * `end_num` is the upper bound for ranges like "100-200元"; `nil` for
    single values.
  * `definition` is `"accurate"` or `"blur"` (`"blur"` for 约/大约/左右).
  """
  @enforce_keys [:num, :case, :definition]
  defstruct [:num, :case, :definition, end_num: nil]

  @type t :: %__MODULE__{
          num: float,
          case: String.t(),
          definition: String.t(),
          end_num: nil | float
        }
end

defmodule JioNLP.PinyinDetail do
  @moduledoc "Consonant/vowel/tone split of a single pinyin reading."
  @enforce_keys [:consonant, :vowel, :tone]
  defstruct [:consonant, :vowel, :tone]

  @type t :: %__MODULE__{
          consonant: String.t(),
          vowel: String.t(),
          tone: String.t()
        }
end

defmodule JioNLP.TimeDelta do
  @moduledoc """
  Dict-style duration. Populated when a `TimeInfo.time_type` is
  `"time_delta"` or `"time_period"`.

  Each unit is either `nil`, `{:single, n}` for an exact count, or
  `{:range, lo, hi}` for a fuzzy estimate (e.g. `30~90日` →
  `%{day: {:range, 30.0, 90.0}}`).
  """
  @enforce_keys [:year, :month, :day, :hour, :minute, :second, :workday, :zero]
  defstruct [:year, :month, :day, :hour, :minute, :second, :workday, :zero]

  @type value :: {:single, float()} | {:range, float(), float()} | nil
  @type t :: %__MODULE__{
          year: value,
          month: value,
          day: value,
          hour: value,
          minute: value,
          second: value,
          workday: value,
          zero: boolean()
        }
end

defmodule JioNLP.TimePeriod do
  @moduledoc """
  Recurring time. `delta` carries the cadence (e.g. `%{day: {:single, 7.0}}`
  for weekly). `point_time` lists `{start_iso, end_iso}` anchors within
  one cycle. `point_string` preserves the original sub-phrase.
  """
  @enforce_keys [:delta, :point_time, :point_string]
  defstruct [:delta, :point_time, :point_string]

  @type t :: %__MODULE__{
          delta: JioNLP.TimeDelta.t(),
          point_time: [{String.t(), String.t()}],
          point_string: String.t()
        }
end

defmodule JioNLP.TimeInfo do
  @moduledoc """
  Result of `JioNLP.parse_time/1,2`.

  * `time_type` is one of `"time_point"`, `"time_span"`, `"time_delta"`,
    `"time_period"` — matching the four shapes the Python reference returns.
  * `start` / `end` are ISO 8601 strings. For `time_delta` both sentinel to
    `"1970-01-01T00:00:00"` — inspect `delta` instead. For `time_period`
    they point at the *next* concrete occurrence (a handy default when a
    caller wants one date without traversing `period.point_time`).
  * `delta` is populated for `time_delta` and `time_period`.
  * `period` is populated only for `time_period`.
  """
  @enforce_keys [:time_type, :start, :end, :definition]
  defstruct [:time_type, :start, :end, :definition, :delta, :period]

  @type t :: %__MODULE__{
          time_type: String.t(),
          start: String.t(),
          end: String.t(),
          definition: String.t(),
          delta: JioNLP.TimeDelta.t() | nil,
          period: JioNLP.TimePeriod.t() | nil
        }
end

defmodule JioNLP.KeyPhrase do
  @moduledoc "A candidate keyphrase returned by `JioNLP.extract_keyphrase/2,3`."
  @enforce_keys [:phrase, :weight]
  defstruct [:phrase, :weight]

  @type t :: %__MODULE__{phrase: String.t(), weight: float}
end

defmodule JioNLP.SummarySentence do
  @moduledoc "A sentence kept by `JioNLP.extract_summary/2`, with its score and document position."
  @enforce_keys [:text, :score, :position]
  defstruct [:text, :score, :position]

  @type t :: %__MODULE__{
          text: String.t(),
          score: float,
          position: non_neg_integer
        }
end

defmodule JioNLP.NerEntity do
  @moduledoc "One entity matched by `JioNLP.recognize_entities/2`."
  @enforce_keys [:text, :entity_type, :offset]
  defstruct [:text, :entity_type, :offset]

  @type t :: %__MODULE__{
          text: String.t(),
          entity_type: String.t(),
          offset: {non_neg_integer, non_neg_integer}
        }
end

defmodule JioNLP.NamedEntity do
  @moduledoc "Input/output entity for `JioNLP.replace_entity/3`."
  @enforce_keys [:text, :entity_type, :offset]
  defstruct [:text, :entity_type, :offset]

  @type t :: %__MODULE__{
          text: String.t(),
          entity_type: String.t(),
          offset: {non_neg_integer, non_neg_integer}
        }
end

defmodule JioNLP.EntityAugmented do
  @moduledoc "One augmented variant produced by `JioNLP.replace_entity/3`."
  @enforce_keys [:text, :entities]
  defstruct [:text, :entities]

  @type t :: %__MODULE__{
          text: String.t(),
          entities: [JioNLP.NamedEntity.t()]
        }
end

defmodule JioNLP.Native do
  @moduledoc """
  Raw NIF bindings. Prefer the higher-level `JioNLP` module — these are the
  unguarded primitives that talk directly to `jionlp-rs`.

  Loads a precompiled NIF from GitHub Releases when available, and falls
  back to compiling from source otherwise (see `mix.exs`).
  """

  version =
    Mix.Project.config()[:version] ||
      raise "jionlp_ex version missing from mix.exs"

  # Precompiled NIF binaries are fetched from this base URL when the
  # consumer doesn't have `JIONLP_BUILD=1` set. Override via
  # `config :jionlp_ex, :precompiled_base_url, ...` if you fork the repo.
  base_url =
    Application.compile_env(
      :jionlp_ex,
      :precompiled_base_url,
      "https://github.com/Psli/jionlp_rs/releases/download/jionlp_ex-v#{version}"
    )

  # Fall back to building from source when:
  #   1. `JIONLP_BUILD=1` is explicitly set, OR
  #   2. The precompiled checksum file hasn't been committed yet (i.e. no
  #      jionlp_ex-v* release has been cut), so downloading would 404.
  # Once `mix rustler_precompiled.download JioNLP.Native --all --print`
  # generates `checksum-Elixir.JioNLP.Native.exs` and it's committed,
  # consumers automatically switch to the prebuilt binaries.
  checksum_exists? =
    [File.cwd!(), Path.join(__DIR__, "../..")]
    |> Enum.map(&Path.join(&1, "checksum-Elixir.JioNLP.Native.exs"))
    |> Enum.any?(&File.exists?/1)

  use RustlerPrecompiled,
    otp_app: :jionlp_ex,
    crate: :jionlp_nif,
    path: "../jionlp_rs/crates/jionlp_nif",
    base_url: base_url,
    version: version,
    force_build:
      System.get_env("JIONLP_BUILD") in ["1", "true"] or not checksum_exists?,
    targets: ~w(
      aarch64-apple-darwin
      x86_64-apple-darwin
      aarch64-unknown-linux-gnu
      x86_64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      x86_64-unknown-linux-musl
      x86_64-pc-windows-msvc
    ),
    nif_versions: ~w(2.15 2.16)

  # dict
  def init_dictionaries(_path), do: :erlang.nif_error(:nif_not_loaded)

  # gadget
  def split_sentence(_text, _criterion), do: :erlang.nif_error(:nif_not_loaded)
  def remove_stopwords(_words, _save_negative), do: :erlang.nif_error(:nif_not_loaded)
  def tra2sim(_text, _mode), do: :erlang.nif_error(:nif_not_loaded)
  def sim2tra(_text, _mode), do: :erlang.nif_error(:nif_not_loaded)
  def parse_motor_vehicle_licence_plate(_plate), do: :erlang.nif_error(:nif_not_loaded)
  def parse_id_card(_id), do: :erlang.nif_error(:nif_not_loaded)
  def char_radical(_text), do: :erlang.nif_error(:nif_not_loaded)
  def num2char(_num, _style), do: :erlang.nif_error(:nif_not_loaded)
  def char2num(_text), do: :erlang.nif_error(:nif_not_loaded)

  # rule/html_cleansing
  def remove_html_tag(_text), do: :erlang.nif_error(:nif_not_loaded)
  def clean_html(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_redundant_char(_text, _custom), do: :erlang.nif_error(:nif_not_loaded)

  # gadget/phone_location
  def phone_location(_text), do: :erlang.nif_error(:nif_not_loaded)
  def cell_phone_location(_text, _digits), do: :erlang.nif_error(:nif_not_loaded)
  def landline_phone_location(_text), do: :erlang.nif_error(:nif_not_loaded)

  # gadget/location_recognizer
  def recognize_location(_text), do: :erlang.nif_error(:nif_not_loaded)
  def parse_location(_text), do: :erlang.nif_error(:nif_not_loaded)

  # gadget/location_parser (full Python-parity)
  def parse_location_full(_text, _town_village, _change2new),
    do: :erlang.nif_error(:nif_not_loaded)

  # gadget/pinyin
  def pinyin_standard(_text), do: :erlang.nif_error(:nif_not_loaded)
  def pinyin_simple(_text), do: :erlang.nif_error(:nif_not_loaded)
  def pinyin_detail(_text), do: :erlang.nif_error(:nif_not_loaded)

  # gadget/money_parser
  def parse_money(_text), do: :erlang.nif_error(:nif_not_loaded)
  def parse_money_with_default(_text, _default), do: :erlang.nif_error(:nif_not_loaded)

  # gadget/time_parser
  def parse_time(_text), do: :erlang.nif_error(:nif_not_loaded)
  def parse_time_with_ref(_text, _ref_iso), do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/simhash
  def simhash(_text), do: :erlang.nif_error(:nif_not_loaded)
  def simhash_ngram(_text, _n), do: :erlang.nif_error(:nif_not_loaded)
  def hamming_distance(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def simhash_similarity(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/keyphrase
  def extract_keyphrase(_text, _top_k, _min_n, _max_n),
    do: :erlang.nif_error(:nif_not_loaded)

  def extract_keyphrase_textrank(_text, _top_k, _min_n, _max_n),
    do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/sentiment
  def sentiment_score(_text), do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/summary
  def extract_summary(_text, _top_k), do: :erlang.nif_error(:nif_not_loaded)
  def extract_summary_by_length(_text, _max_chars), do: :erlang.nif_error(:nif_not_loaded)

  # textaug
  def swap_char_position(_text, _n, _swap_ratio, _seed, _scale),
    do: :erlang.nif_error(:nif_not_loaded)

  def random_add_delete(_text, _n, _add, _del, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  def homophone_substitution(_text, _n, _sub_ratio, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  def replace_entity(_text, _entities, _replacements, _n, _ratio, _seed),
    do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/ner
  def recognize_entities(_text, _lexicon), do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/bpe
  def bpe_encode(_text), do: :erlang.nif_error(:nif_not_loaded)
  def bpe_decode(_encoded), do: :erlang.nif_error(:nif_not_loaded)

  # algorithm/summary MMR
  def extract_summary_mmr(_text, _top_k, _lambda),
    do: :erlang.nif_error(:nif_not_loaded)

  # rule/extractor
  def extract_email(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_cell_phone(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_landline_phone(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_phone_number(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_ip_address(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_id_card(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_url(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_qq(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_motor_vehicle_licence_plate(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_chinese(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_parentheses(_text, _table), do: :erlang.nif_error(:nif_not_loaded)

  # rule/checker
  def check_any_chinese_char(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_all_chinese_char(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_any_arabic_num(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_all_arabic_num(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_id_card(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_cell_phone(_text), do: :erlang.nif_error(:nif_not_loaded)
  def check_motor_vehicle_licence_plate(_text), do: :erlang.nif_error(:nif_not_loaded)

  # Round 35 — newly-exposed APIs
  def get_china_province_alias(_name), do: :erlang.nif_error(:nif_not_loaded)
  def get_china_city_alias(_name, _dismiss_diqu, _dismiss_meng),
    do: :erlang.nif_error(:nif_not_loaded)
  def get_china_county_alias(_name, _dismiss_qi), do: :erlang.nif_error(:nif_not_loaded)
  def get_china_town_alias(_name), do: :erlang.nif_error(:nif_not_loaded)
  def is_person_name(_text), do: :erlang.nif_error(:nif_not_loaded)
  def solar_to_lunar(_iso_date), do: :erlang.nif_error(:nif_not_loaded)
  def lunar_to_solar(_y, _m, _d, _leap), do: :erlang.nif_error(:nif_not_loaded)

  def remove_email(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_url(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_phone_number(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_ip_address(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_id_card(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_qq(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_parentheses(_text), do: :erlang.nif_error(:nif_not_loaded)
  def remove_exception_char(_text), do: :erlang.nif_error(:nif_not_loaded)
  def replace_email(_text, _placeholder), do: :erlang.nif_error(:nif_not_loaded)
  def replace_url(_text, _placeholder), do: :erlang.nif_error(:nif_not_loaded)
  def replace_phone_number(_text, _placeholder), do: :erlang.nif_error(:nif_not_loaded)
  def replace_chinese(_text, _placeholder), do: :erlang.nif_error(:nif_not_loaded)
  def convert_full2half(_text), do: :erlang.nif_error(:nif_not_loaded)
  def extract_wechat_id(_text), do: :erlang.nif_error(:nif_not_loaded)
  def idiom_next_by_char(_seed, _cur, _with_prob),
    do: :erlang.nif_error(:nif_not_loaded)
end
