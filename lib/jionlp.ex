defmodule JioNLP do
  @moduledoc """
  High-level API for jionlp-rs, the Rust port of JioNLP.

  Call `JioNLP.init/1` once before using any other function (the application
  does this automatically if `:jionlp_ex, :dictionary_path` is configured).

  ## Examples

      iex> JioNLP.split_sentence("今天天气真好。我要去公园！")
      ["今天天气真好。", "我要去公园！"]

      iex> JioNLP.tra2sim("今天天氣好晴朗")
      "今天天气好晴朗"
  """

  alias JioNLP.Native

  @type criterion :: :coarse | :fine
  @type ts_mode :: :char | :word

  @default_parens "{}「」[]【】()（）<>《》〈〉『』〔〕｛｝＜＞〖〗"

  # ─────────────────────────── Initialization ───────────────────────────────

  @doc "Initialize dictionaries from `path`. Idempotent."
  @spec init(String.t()) :: :ok | {:error, term}
  def init(path), do: Native.init_dictionaries(path)

  # ─────────────────────────── gadget ───────────────────────────────────────

  @doc "Split Chinese text into sentences."
  @spec split_sentence(String.t(), criterion) :: [String.t()]
  def split_sentence(text, criterion \\ :coarse) when criterion in [:coarse, :fine] do
    Native.split_sentence(text, criterion)
  end

  @doc "Remove stop-words from a list of segmented words."
  @spec remove_stopwords([String.t()], keyword) :: [String.t()]
  def remove_stopwords(words, opts \\ []) when is_list(words) do
    save_negative = Keyword.get(opts, :save_negative_words, false)
    Native.remove_stopwords(words, save_negative)
  end

  @doc "Traditional → Simplified Chinese."
  @spec tra2sim(String.t(), ts_mode) :: String.t()
  def tra2sim(text, mode \\ :char) when mode in [:char, :word] do
    Native.tra2sim(text, mode)
  end

  @doc "Simplified → Traditional Chinese."
  @spec sim2tra(String.t(), ts_mode) :: String.t()
  def sim2tra(text, mode \\ :char) when mode in [:char, :word] do
    Native.sim2tra(text, mode)
  end

  @doc "Parse a mainland Chinese licence plate. Returns `nil` for invalid input."
  @spec parse_motor_vehicle_licence_plate(String.t()) :: JioNLP.PlateInfo.t() | nil
  def parse_motor_vehicle_licence_plate(plate),
    do: Native.parse_motor_vehicle_licence_plate(plate)

  @doc """
  Parse an 18-char mainland Chinese ID card. Returns `nil` if the input
  doesn't match the format or the admin code is unknown.
  """
  @spec parse_id_card(String.t()) :: JioNLP.IdCardInfo.t() | nil
  def parse_id_card(id), do: Native.parse_id_card(id)

  @doc "Per-char radical / structure / coding info."
  @spec char_radical(String.t()) :: [JioNLP.RadicalInfo.t()]
  def char_radical(text), do: Native.char_radical(text)

  @doc """
  Convert a number string to Chinese numerals.

  `style` is `:simplified` (default — 一二三, 千百十) or `:traditional`
  (壹贰叁, 仟佰拾) for invoice-style amounts.
  """
  @spec num2char(String.t() | integer | float, :simplified | :traditional) :: String.t()
  def num2char(num, style \\ :simplified) when style in [:simplified, :traditional] do
    Native.num2char(to_string(num), style)
  end

  @doc "Parse a Chinese numeric expression into a number."
  @spec char2num(String.t()) :: float
  def char2num(text), do: Native.char2num(text)

  # ─────────────────────────── html_cleansing ───────────────────────────────

  @doc "Strip HTML tags, preserving inner text."
  def remove_html_tag(text), do: Native.remove_html_tag(text)

  @doc "Best-effort HTML → plain text (strip script/style/comments, tags, decode entities)."
  def clean_html(text), do: Native.clean_html(text)

  @doc """
  Remove noise chars. With no `custom`, removes the default noise set
  (spaces, tabs, newlines, 啊哈呀, fullwidth spaces, middots). Pass a string
  of chars to override the set.
  """
  def remove_redundant_char(text, custom \\ nil),
    do: Native.remove_redundant_char(text, custom)

  # ─────────────────────────── extractors ───────────────────────────────────

  @doc "Extract email addresses."
  @spec extract_email(String.t()) :: [JioNLP.Extracted.t()]
  def extract_email(text), do: Native.extract_email(text)

  @doc "Extract mobile phone numbers (1[3-9]x, 11 digits)."
  def extract_cell_phone(text), do: Native.extract_cell_phone(text)

  @doc "Extract mainland landline numbers."
  def extract_landline_phone(text), do: Native.extract_landline_phone(text)

  @doc "Extract both mobile and landline numbers, sorted by offset."
  def extract_phone_number(text), do: Native.extract_phone_number(text)

  @doc "Extract IPv4 addresses."
  def extract_ip_address(text), do: Native.extract_ip_address(text)

  @doc "Extract 18-char mainland Chinese ID cards."
  def extract_id_card(text), do: Native.extract_id_card(text)

  @doc "Extract URLs (http/https/ftp/file, bare www.)."
  def extract_url(text), do: Native.extract_url(text)

  @doc "Extract QQ numbers (6-11 digits not starting with 0)."
  def extract_qq(text), do: Native.extract_qq(text)

  @doc "Extract mainland Chinese licence plates."
  def extract_motor_vehicle_licence_plate(text),
    do: Native.extract_motor_vehicle_licence_plate(text)

  @doc "Extract runs of Chinese characters."
  @spec extract_chinese(String.t()) :: [String.t()]
  def extract_chinese(text), do: Native.extract_chinese(text)

  @doc """
  Extract paired parentheses with their inner content (supports nesting).

  `table` is a string of concatenated open/close pairs, e.g. `"()[]"`.
  Default covers common ASCII and Chinese brackets.
  """
  def extract_parentheses(text, table \\ @default_parens),
    do: Native.extract_parentheses(text, table)

  # ─────────────────────────── checkers ─────────────────────────────────────

  def check_any_chinese_char(text), do: Native.check_any_chinese_char(text)
  def check_all_chinese_char(text), do: Native.check_all_chinese_char(text)
  def check_any_arabic_num(text), do: Native.check_any_arabic_num(text)
  def check_all_arabic_num(text), do: Native.check_all_arabic_num(text)
  def check_id_card(text), do: Native.check_id_card(text)
  def check_cell_phone(text), do: Native.check_cell_phone(text)

  def check_motor_vehicle_licence_plate(text),
    do: Native.check_motor_vehicle_licence_plate(text)

  # ─────────────────────────── phone location ──────────────────────────────

  @doc "Classify a phone string and look up its home location."
  @spec phone_location(String.t()) :: JioNLP.PhoneInfo.t()
  def phone_location(text), do: Native.phone_location(text)

  @doc "Same as `phone_location/1` but assumes the input is a cell phone with pre-extracted digits."
  def cell_phone_location(text, digits), do: Native.cell_phone_location(text, digits)

  @doc "Same as `phone_location/1` but assumes the input is a landline."
  def landline_phone_location(text), do: Native.landline_phone_location(text)

  # ─────────────────────────── location ────────────────────────────────────

  @doc "Find all admin-division names in the text (province / city / county)."
  @spec recognize_location(String.t()) :: [JioNLP.LocationMatch.t()]
  def recognize_location(text), do: Native.recognize_location(text)

  @doc "Extract the first province / city / county found in the text."
  @spec parse_location(String.t()) :: JioNLP.ParsedLocation.t()
  def parse_location(text), do: Native.parse_location(text)

  @doc """
  Full Python-parity location parser. Returns a
  `%JioNLP.LocationParseResult{}` with province / city / county / detail /
  full_location / orig_location — matching `jionlp.parse_location(text,
  change2new=bool)`.

  Options:
    * `:town_village` (boolean, default false) — reserved; currently ignored
      (5-level port pending).
    * `:change2new`  (boolean, default true) — when true, deprecated admin
      names are upgraded (e.g. `襄樊市 → 襄阳市`).
  """
  @spec parse_location_full(String.t(), keyword) :: JioNLP.LocationParseResult.t()
  def parse_location_full(text, opts \\ []) do
    tv = Keyword.get(opts, :town_village, false)
    c2n = Keyword.get(opts, :change2new, true)
    Native.parse_location_full(text, tv, c2n)
  end

  # ─────────────────────────── pinyin ───────────────────────────────────────

  @doc """
  Annotate each char in `text` with its primary pinyin reading.

  `format`:
    * `:standard` — accented form `["zhōng", "huá"]` (default)
    * `:simple`   — ascii + tone digit `["zhong1", "hua2"]`
    * `:detail`   — list of `%JioNLP.PinyinDetail{}` with consonant/vowel/tone
  """
  @spec pinyin(String.t(), :standard | :simple | :detail) :: [String.t() | JioNLP.PinyinDetail.t()]
  def pinyin(text, format \\ :standard) do
    case format do
      :standard -> Native.pinyin_standard(text)
      :simple -> Native.pinyin_simple(text)
      :detail -> Native.pinyin_detail(text)
    end
  end

  # ─────────────────────────── money ────────────────────────────────────────

  @doc """
  Parse a Chinese/numeric money string. Returns `nil` when it can't be
  interpreted.

  Supports "100元", "1,000.50元", "一百元", "三千五百万元", "1.5万美元" etc.
  """
  @spec parse_money(String.t(), keyword) :: JioNLP.MoneyInfo.t() | nil
  def parse_money(text, opts \\ []) do
    case Keyword.get(opts, :default_unit) do
      nil -> Native.parse_money(text)
      unit -> Native.parse_money_with_default(text, unit)
    end
  end

  # ─────────────────────────── time ─────────────────────────────────────────

  @doc """
  Parse a Chinese time expression. Currently handles absolute dates,
  relative days (今天/明天/昨天 etc.) and clock times.

  Pass `reference_time:` as `"YYYY-MM-DDTHH:MM:SS"` to anchor relative
  expressions to a specific moment (useful for tests or server-side
  processing of messages with a known timestamp).

  Returns `nil` if the input can't be interpreted.
  """
  @spec parse_time(String.t(), keyword) :: JioNLP.TimeInfo.t() | nil
  def parse_time(text, opts \\ []) do
    case Keyword.get(opts, :reference_time) do
      nil -> Native.parse_time(text)
      ref -> Native.parse_time_with_ref(text, ref)
    end
  end

  @doc """
  Extract every time expression from a free-text string.

  Each result is a `%JioNLP.TimeEntity{}` with byte-offset `offset`,
  the matched substring `text`, and (by default) the same
  `JioNLP.TimeInfo` you'd get from `parse_time/1` on that substring
  placed in `detail`.

  ## Options

    * `:reference_time` — ISO string `"YYYY-MM-DDTHH:MM:SS"` to anchor
      relative expressions (defaults to current local time)
    * `:with_parsing` — `false` returns entities without `detail`
      (cheaper when you only need spans); default `true`
    * `:ret_all` — `true` keeps overlapping matches (default `false`)

  ## Example

      iex> JioNLP.extract_time("会议从2024年6月10日开始,持续三天。")
      [
        %JioNLP.TimeEntity{text: "2024年6月10日", offset: {3, 15}, time_type: "time_point", detail: %JioNLP.TimeInfo{...}},
        %JioNLP.TimeEntity{text: "三天", offset: {19, 23}, time_type: "time_delta", detail: ...}
      ]
  """
  @spec extract_time(String.t(), keyword) :: [JioNLP.TimeEntity.t()]
  def extract_time(text, opts \\ []) do
    ref = Keyword.get(opts, :reference_time, "")
    with_parsing = Keyword.get(opts, :with_parsing, true)
    ret_all = Keyword.get(opts, :ret_all, false)
    Native.extract_time(text, ref, with_parsing, ret_all)
  end

  @doc """
  Normalize a free-text time-period or time-delta expression to a
  `JioNLP.TimeDelta`. Returns `nil` if the text doesn't describe a
  duration.

      iex> JioNLP.normalize_time_period("每三天")
      %JioNLP.TimeDelta{day: %JioNLP.DeltaValue{num: 3, ...}, ...}
  """
  @spec normalize_time_period(String.t()) :: JioNLP.TimeDelta.t() | nil
  def normalize_time_period(text), do: Native.normalize_time_period(text)

  # ─────────────────────────── simhash ──────────────────────────────────────

  @doc "Compute a 64-bit SimHash of `text` (default char bigrams)."
  @spec simhash(String.t()) :: non_neg_integer
  def simhash(text), do: Native.simhash(text)

  @doc "SimHash with a custom n-gram size (1-3 typical)."
  @spec simhash(String.t(), pos_integer) :: non_neg_integer
  def simhash(text, n), do: Native.simhash_ngram(text, n)

  @doc "Hamming distance between two 64-bit SimHash values (0-64)."
  @spec hamming_distance(non_neg_integer, non_neg_integer) :: non_neg_integer
  def hamming_distance(a, b), do: Native.hamming_distance(a, b)

  @doc "Similarity in [0.0, 1.0] = `1 - hamming/64`."
  @spec simhash_similarity(non_neg_integer, non_neg_integer) :: float
  def simhash_similarity(a, b), do: Native.simhash_similarity(a, b)

  # ─────────────────────────── keyphrase ────────────────────────────────────

  @doc """
  Extract keyphrases from `text`, scored by TF × IDF over Chinese-char
  n-grams.

  Options:
    * `top_k`   — maximum phrases to return (default 5)
    * `min_n`   — minimum n-gram length (default 2)
    * `max_n`   — maximum n-gram length (default 4)
  """
  @spec extract_keyphrase(String.t(), keyword) :: [JioNLP.KeyPhrase.t()]
  def extract_keyphrase(text, opts \\ []) do
    top_k = Keyword.get(opts, :top_k, 5)
    min_n = Keyword.get(opts, :min_n, 2)
    max_n = Keyword.get(opts, :max_n, 4)
    Native.extract_keyphrase(text, top_k, min_n, max_n)
  end

  @doc """
  Extract keyphrases using TextRank graph ranking over n-gram
  cooccurrences. More thematic than `extract_keyphrase/2` (which is
  pure TF-IDF) at the cost of a few microseconds per doc.
  """
  @spec extract_keyphrase_textrank(String.t(), keyword) :: [JioNLP.KeyPhrase.t()]
  def extract_keyphrase_textrank(text, opts \\ []) do
    top_k = Keyword.get(opts, :top_k, 5)
    min_n = Keyword.get(opts, :min_n, 2)
    max_n = Keyword.get(opts, :max_n, 4)
    Native.extract_keyphrase_textrank(text, top_k, min_n, max_n)
  end

  # ─────────────────────────── sentiment ────────────────────────────────────

  @doc """
  Lexicon-based sentiment analysis. Returns a sigmoided score in `[0, 1]`:
  `0.5` is neutral, `< 0.5` is negative, `> 0.5` is positive. Empty input
  yields `0.5`.
  """
  @spec sentiment_score(String.t()) :: float
  def sentiment_score(text), do: Native.sentiment_score(text)

  # ─────────────────────────── summary ──────────────────────────────────────

  @doc """
  Extractive summary: return the `top_k` highest-scoring sentences of
  `text` in original document order.

  Ranking mirrors Python JioNLP: TF-IDF over char bigrams + LDA
  topic-prominence (when the full data bundle is installed) + length
  penalty (×0.7 if <15 or >70 CJK chars) + lead-3 position bonus (×1.2
  for the first three sentences). For MMR diversity on top of this,
  call `extract_summary_mmr/3`.
  """
  @spec extract_summary(String.t(), pos_integer) :: [JioNLP.SummarySentence.t()]
  def extract_summary(text, top_k \\ 3), do: Native.extract_summary(text, top_k)

  @doc """
  Extractive summary capped at `max_chars` characters. Mirrors Python's
  `extract_summary(..., summary_length=200)`: picks sentences in
  descending weight order and keeps adding until the next one would
  blow the budget. Always returns at least the single highest-scoring
  sentence even if it alone exceeds `max_chars`.
  """
  @spec extract_summary_by_length(String.t(), pos_integer) :: [JioNLP.SummarySentence.t()]
  def extract_summary_by_length(text, max_chars \\ 200),
    do: Native.extract_summary_by_length(text, max_chars)

  # ─────────────────────────── textaug ──────────────────────────────────────

  @doc """
  Generate up to `n` augmented variants of `text` by swapping neighboring
  Chinese characters.

  Options:
    * `swap_ratio` — per-char swap probability (default `0.02`)
    * `seed`       — PRNG seed; `0` = non-deterministic (default `1`)
    * `scale`      — Gaussian scale for swap-distance (default `1.0`)
  """
  @spec swap_char_position(String.t(), pos_integer, keyword) :: [String.t()]
  def swap_char_position(text, n \\ 3, opts \\ []) do
    swap_ratio = Keyword.get(opts, :swap_ratio, 0.02)
    seed = Keyword.get(opts, :seed, 1)
    scale = Keyword.get(opts, :scale, 1.0)
    Native.swap_char_position(text, n, swap_ratio, seed, scale)
  end

  @doc """
  Augment by randomly adding noise chars and deleting CJK chars.

  Options: `add_ratio` (default 0.02), `delete_ratio` (default 0.02),
  `seed` (default 1, `0` = non-deterministic).
  """
  @spec random_add_delete(String.t(), pos_integer, keyword) :: [String.t()]
  def random_add_delete(text, n \\ 3, opts \\ []) do
    add = Keyword.get(opts, :add_ratio, 0.02)
    del = Keyword.get(opts, :delete_ratio, 0.02)
    seed = Keyword.get(opts, :seed, 1)
    Native.random_add_delete(text, n, add, del, seed)
  end

  @doc """
  Augment by substituting Chinese characters with homophones.

  Options: `sub_ratio` (default 0.05), `seed` (default 1).
  """
  @spec homophone_substitution(String.t(), pos_integer, keyword) :: [String.t()]
  def homophone_substitution(text, n \\ 3, opts \\ []) do
    ratio = Keyword.get(opts, :sub_ratio, 0.05)
    seed = Keyword.get(opts, :seed, 1)
    Native.homophone_substitution(text, n, ratio, seed)
  end

  @doc """
  Augment by replacing named entities in the text with weighted-random
  picks from the provided `replacements` lexicon.

  `entities` is a list of `%JioNLP.NamedEntity{}`; `replacements` is a
  keyword-list mapping entity type to a list of `{name, weight}` tuples.

  Options: `replace_ratio` (default 0.1), `seed` (default 1).

  Example:

      entities = [%JioNLP.NamedEntity{text: "日本", entity_type: "Country", offset: {33, 39}}]
      replacements = [{"Country", [{"美国", 2.0}, {"英国", 1.0}]}]
      JioNLP.replace_entity(text, entities, replacements)
  """
  @spec replace_entity(String.t(), [JioNLP.NamedEntity.t()], list, keyword) ::
          [JioNLP.EntityAugmented.t()]
  def replace_entity(text, entities, replacements, opts \\ []) do
    n = Keyword.get(opts, :n, 3)
    ratio = Keyword.get(opts, :replace_ratio, 0.1)
    seed = Keyword.get(opts, :seed, 1)
    Native.replace_entity(text, entities, replacements, n, ratio, seed)
  end

  # ─────────────────────────── LexiconNER ───────────────────────────────────

  @doc """
  Recognize entities from a user-supplied lexicon.

  `lexicon` is a keyword-list of `{entity_type, [term, ...]}`. Leftmost-
  longest match semantics: for overlapping matches, the longest wins.

  Example:

      lexicon = [{"Drug", ["阿司匹林", "布洛芬"]}, {"Company", ["阿里巴巴"]}]
      JioNLP.recognize_entities("他吃了阿司匹林", lexicon)
  """
  @spec recognize_entities(String.t(), list) :: [JioNLP.NerEntity.t()]
  def recognize_entities(text, lexicon), do: Native.recognize_entities(text, lexicon)

  # ─────────────────────────── byte-level BPE ───────────────────────────────

  @doc """
  Byte-level BPE encoder. Maps each UTF-8 byte to a printable Unicode
  code point — this is the byte layer used by GPT-2 / HuggingFace
  tokenizers and is lossless.
  """
  @spec bpe_encode(String.t()) :: String.t()
  def bpe_encode(text), do: Native.bpe_encode(text)

  @doc "Inverse of `bpe_encode/1`."
  @spec bpe_decode(String.t()) :: String.t()
  def bpe_decode(encoded), do: Native.bpe_decode(encoded)

  # ─────────────────────────── summary (MMR) ────────────────────────────────

  @doc """
  Extractive summary with Maximal Marginal Relevance diversity.

  `lambda ∈ [0.0, 1.0]` trades off relevance vs. redundancy — `1.0`
  matches `extract_summary/2` exactly, `0.0` maximizes diversity.
  Default recommendation is `0.7`.
  """
  @spec extract_summary_mmr(String.t(), pos_integer, float) ::
          [JioNLP.SummarySentence.t()]
  def extract_summary_mmr(text, top_k \\ 3, lambda \\ 0.7),
    do: Native.extract_summary_mmr(text, top_k, lambda)

  # ─────────────────────────── Round 35 — newly-exposed ─────────────────────

  @doc "Return the short form (简称) for a Chinese province name."
  @spec get_china_province_alias(String.t()) :: nil | String.t()
  def get_china_province_alias(name), do: Native.get_china_province_alias(name)

  @doc """
  Return the short form for a 市/地区/盟/自治州 name. Options:
  * `:dismiss_diqu` — skip the `地区` suffix rule (default `false`)
  * `:dismiss_meng` — skip the `盟` suffix rule (default `false`)
  """
  @spec get_china_city_alias(String.t(), keyword) :: nil | String.t()
  def get_china_city_alias(name, opts \\ []) do
    Native.get_china_city_alias(
      name,
      Keyword.get(opts, :dismiss_diqu, false),
      Keyword.get(opts, :dismiss_meng, false)
    )
  end

  @doc "Return the short form for a 县/区/旗/林区/自治县 name."
  @spec get_china_county_alias(String.t(), keyword) :: nil | String.t()
  def get_china_county_alias(name, opts \\ []) do
    Native.get_china_county_alias(name, Keyword.get(opts, :dismiss_qi, false))
  end

  @doc "Return the short form for a 镇/乡/街道/地区 name."
  @spec get_china_town_alias(String.t()) :: nil | String.t()
  def get_china_town_alias(name), do: Native.get_china_town_alias(name)

  @doc "Check whether a text looks like a Chinese person name (rule-based)."
  @spec is_person_name(String.t()) :: boolean
  def is_person_name(text), do: Native.is_person_name(text)

  @doc "Convert Gregorian date (`YYYY-MM-DD`) to lunar `{year, month, day, leap?}`."
  @spec solar_to_lunar(String.t()) :: {integer, integer, integer, boolean}
  def solar_to_lunar(iso_date), do: Native.solar_to_lunar(iso_date)

  @doc "Convert lunar date components to Gregorian `YYYY-MM-DD` string."
  @spec lunar_to_solar(integer, integer, integer, boolean) :: nil | String.t()
  def lunar_to_solar(year, month, day, leap_month \\ false),
    do: Native.lunar_to_solar(year, month, day, leap_month)

  # Removal / replacement helpers
  def remove_email(text), do: Native.remove_email(text)
  def remove_url(text), do: Native.remove_url(text)
  def remove_phone_number(text), do: Native.remove_phone_number(text)
  def remove_ip_address(text), do: Native.remove_ip_address(text)
  def remove_id_card(text), do: Native.remove_id_card(text)
  def remove_qq(text), do: Native.remove_qq(text)
  def remove_parentheses(text), do: Native.remove_parentheses(text)
  def remove_exception_char(text), do: Native.remove_exception_char(text)
  def replace_email(text, placeholder), do: Native.replace_email(text, placeholder)
  def replace_url(text, placeholder), do: Native.replace_url(text, placeholder)
  def replace_phone_number(text, placeholder),
    do: Native.replace_phone_number(text, placeholder)
  def replace_chinese(text, placeholder), do: Native.replace_chinese(text, placeholder)
  def convert_full2half(text), do: Native.convert_full2half(text)
  def extract_wechat_id(text), do: Native.extract_wechat_id(text)

  @doc """
  Find the next idiom in a 成语接龙 chain. `seed` seeds the RNG for
  deterministic output. `with_prob: true` samples by frequency; `false`
  picks uniformly among candidates.
  """
  @spec idiom_next_by_char(integer, String.t(), boolean) :: nil | String.t()
  def idiom_next_by_char(seed, cur, with_prob \\ true),
    do: Native.idiom_next_by_char(seed, cur, with_prob)
end
