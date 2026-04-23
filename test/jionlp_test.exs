defmodule JioNLPTest do
  use ExUnit.Case, async: false
  doctest JioNLP, except: [:moduledoc]

  # ─── gadget ──────────────────────────────────────────────────────────────

  test "split_sentence coarse" do
    assert JioNLP.split_sentence("今天天气真好。我要去公园！", :coarse) ==
             ["今天天气真好。", "我要去公园！"]
  end

  test "split_sentence fine" do
    assert JioNLP.split_sentence("中华古汉语，泱泱大国。", :fine) ==
             ["中华古汉语，", "泱泱大国。"]
  end

  test "tra2sim char" do
    assert JioNLP.tra2sim("今天天氣好晴朗") == "今天天气好晴朗"
  end

  test "sim2tra char" do
    assert JioNLP.sim2tra("今天天气好晴朗") == "今天天氣好晴朗"
  end

  test "remove_stopwords filters common stopwords" do
    out = JioNLP.remove_stopwords(["他", "的", "苹果"])
    refute "的" in out
    assert "苹果" in out
  end

  test "parse_motor_vehicle_licence_plate GV" do
    assert %JioNLP.PlateInfo{car_loc: "川A", car_type: "GV", car_size: nil} =
             JioNLP.parse_motor_vehicle_licence_plate("川A·23047")
  end

  test "parse_motor_vehicle_licence_plate NEV big PEV" do
    assert %JioNLP.PlateInfo{car_loc: "川A", car_type: "PEV", car_size: "big"} =
             JioNLP.parse_motor_vehicle_licence_plate("川A·23047B")
  end

  test "parse_motor_vehicle_licence_plate invalid" do
    assert JioNLP.parse_motor_vehicle_licence_plate("bogus") == nil
  end

  # ─── extractors ─────────────────────────────────────────────────────────

  test "extract_email" do
    [e] = JioNLP.extract_email("ping me at hi@test.com, thanks")
    assert e.text == "hi@test.com"
    assert is_tuple(e.offset)
  end

  test "extract_ip_address" do
    r = JioNLP.extract_ip_address("hosts: 10.0.0.1 and 192.168.0.1.")
    assert length(r) == 2
    assert hd(r).text == "10.0.0.1"
  end

  test "extract_id_card" do
    [e] = JioNLP.extract_id_card("身份证 11010519900307123X ，请保密")
    assert String.length(e.text) == 18
  end

  test "extract_url" do
    [e] = JioNLP.extract_url("see https://example.com/path?q=1. ok")
    assert String.starts_with?(e.text, "https://")
  end

  test "extract_chinese" do
    assert JioNLP.extract_chinese("hello 中文 world 测试 ok") == ["中文", "测试"]
  end

  test "extract_parentheses nested" do
    r = JioNLP.extract_parentheses("a (b (c) d) e", "()")
    texts = Enum.map(r, & &1.text)
    assert "(c)" in texts
    assert "(b (c) d)" in texts
  end

  test "extract_motor_vehicle_licence_plate" do
    [e] = JioNLP.extract_motor_vehicle_licence_plate("车牌 川A·23047B 停车")
    assert e.text == "川A·23047B"
  end

  # ─── checkers ───────────────────────────────────────────────────────────

  test "check_any_chinese_char" do
    assert JioNLP.check_any_chinese_char("hello 中")
    refute JioNLP.check_any_chinese_char("hello")
  end

  test "check_all_chinese_char" do
    assert JioNLP.check_all_chinese_char("全中文")
    refute JioNLP.check_all_chinese_char("中文 mixed")
    refute JioNLP.check_all_chinese_char("")
  end

  test "check_id_card" do
    assert JioNLP.check_id_card("11010519900307123X")
    refute JioNLP.check_id_card("not an id")
  end

  test "check_cell_phone" do
    assert JioNLP.check_cell_phone("13912345678")
    refute JioNLP.check_cell_phone("12312345678")
  end

  test "check_motor_vehicle_licence_plate" do
    assert JioNLP.check_motor_vehicle_licence_plate("川A23047")
    refute JioNLP.check_motor_vehicle_licence_plate("ABC12345")
  end

  # ─── third round additions ────────────────────────────────────────────────

  test "parse_id_card" do
    info = JioNLP.parse_id_card("440105199001012345")
    assert %JioNLP.IdCardInfo{province: "广东省", city: "广州市"} = info
    assert info.birth_year == "1990"
    assert info.gender in ["男", "女"]
  end

  test "parse_id_card invalid" do
    assert JioNLP.parse_id_card("not an id") == nil
  end

  test "char_radical returns per-char info" do
    r = JioNLP.char_radical("天地A")
    assert length(r) == 3
    assert Enum.at(r, 0).__struct__ == JioNLP.RadicalInfo
    # ASCII falls back to <cr_unk>.
    assert Enum.at(r, 2).radical == "<cr_unk>"
  end

  test "num2char simplified" do
    assert JioNLP.num2char("38009") == "三万八千零九"
    assert JioNLP.num2char(1234) == "一千二百三十四"
  end

  test "num2char traditional" do
    assert JioNLP.num2char("1234", :traditional) == "壹仟贰佰叁拾肆"
  end

  test "char2num" do
    assert JioNLP.char2num("二十三") == 23.0
    assert JioNLP.char2num("三千五百万") == 35_000_000.0
  end

  test "remove_html_tag" do
    assert JioNLP.remove_html_tag("<p>hello <b>world</b></p>") == "hello world"
  end

  test "clean_html decodes entities" do
    assert JioNLP.clean_html("<p>a &amp; b</p>") == "a & b"
  end

  test "remove_redundant_char default" do
    assert JioNLP.remove_redundant_char("你 好\t哈！") == "你好！"
  end

  test "remove_redundant_char custom" do
    assert JioNLP.remove_redundant_char("a!b?c.", "!?.") == "abc"
  end

  # ─── fourth round additions ──────────────────────────────────────────────

  test "phone_location cell phone" do
    info = JioNLP.phone_location("13812345678")
    assert %JioNLP.PhoneInfo{phone_type: "cell_phone"} = info
    assert info.operator == "中国移动"
  end

  test "phone_location landline Beijing" do
    info = JioNLP.phone_location("010-12345678")
    assert info.phone_type == "landline_phone"
    assert info.province =~ "北京"
  end

  test "phone_location unknown" do
    info = JioNLP.phone_location("hello")
    assert info.phone_type == "unknown"
    assert info.province == nil
  end

  test "recognize_location finds province and city" do
    matches = JioNLP.recognize_location("我出生在广东省广州市海珠区。")
    names = Enum.map(matches, & &1.name)
    assert "广东省" in names
    assert "广州市" in names
  end

  test "parse_location returns triple" do
    loc = JioNLP.parse_location("我家在四川省成都市锦江区")
    assert %JioNLP.ParsedLocation{} = loc
    # At least one of the three should be populated.
    assert loc.province != nil or loc.city != nil or loc.county != nil
  end

  # ─── fifth round additions ───────────────────────────────────────────────

  test "pinyin standard" do
    r = JioNLP.pinyin("中国")
    assert r == ["zhōng", "guó"]
  end

  test "pinyin simple" do
    r = JioNLP.pinyin("中国", :simple)
    assert r == ["zhong1", "guo2"]
  end

  test "pinyin detail" do
    [%JioNLP.PinyinDetail{consonant: c, vowel: v, tone: t} | _] =
      JioNLP.pinyin("中", :detail)

    assert c == "zh"
    assert v == "ong"
    assert t == "1"
  end

  test "pinyin ascii fallback" do
    assert JioNLP.pinyin("A") == ["<py_unk>"]
  end

  test "parse_money basic yuan" do
    m = JioNLP.parse_money("100元")
    assert %JioNLP.MoneyInfo{num: 100.0, case: "元"} = m
  end

  test "parse_money chinese wan" do
    m = JioNLP.parse_money("三千五百万元")
    assert m.num == 35_000_000.0
    assert m.case == "元"
  end

  test "parse_money usd suffix" do
    m = JioNLP.parse_money("100美元")
    assert m.num == 100.0
    assert m.case == "美元"
  end

  test "parse_money nil on gibberish" do
    assert JioNLP.parse_money("abc") == nil
  end

  test "parse_money default unit override" do
    m = JioNLP.parse_money("100", default_unit: "美元")
    assert m.case == "美元"
  end

  # ─── sixth round additions ───────────────────────────────────────────────

  test "parse_money currency symbol ￥" do
    m = JioNLP.parse_money("￥100")
    assert m.num == 100.0
    assert m.case == "元"
  end

  test "parse_money currency symbol $" do
    m = JioNLP.parse_money("$100.5")
    assert m.num == 100.5
    assert m.case == "美元"
  end

  test "parse_money 元角分 triple" do
    m = JioNLP.parse_money("100元5角3分")
    assert_in_delta m.num, 100.53, 1.0e-9
    assert m.case == "元"
  end

  test "parse_money blur modifier" do
    m = JioNLP.parse_money("约100元")
    assert m.definition == "blur"
    assert m.num == 100.0
  end

  test "parse_money blur suffix" do
    m = JioNLP.parse_money("100元左右")
    assert m.definition == "blur"
  end

  test "parse_money range dash" do
    m = JioNLP.parse_money("100-200元")
    assert m.num == 100.0
    assert m.end_num == 200.0
  end

  test "parse_money range 到" do
    m = JioNLP.parse_money("100到200元")
    assert m.num == 100.0
    assert m.end_num == 200.0
  end

  test "recognize_location alias 京 → 北京市" do
    matches = JioNLP.recognize_location("出差去京")
    assert Enum.any?(matches, fn m -> m.name == "北京市" end)
  end

  test "recognize_location alias 粤 → 广东省" do
    matches = JioNLP.recognize_location("他是粤人")
    assert Enum.any?(matches, fn m -> m.name == "广东省" end)
  end

  # ─── seventh round additions ─────────────────────────────────────────────

  test "parse_time absolute date" do
    t = JioNLP.parse_time("2024年3月5日")
    assert %JioNLP.TimeInfo{time_type: "time_point"} = t
    assert String.starts_with?(t.start, "2024-03-05")
    assert String.starts_with?(t.end, "2024-03-05")
  end

  test "parse_time dash format" do
    t = JioNLP.parse_time("2024-03-05")
    assert String.starts_with?(t.start, "2024-03-05")
  end

  test "parse_time relative with reference" do
    t = JioNLP.parse_time("明天", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-16")
  end

  test "parse_time with clock" do
    t = JioNLP.parse_time("2024年3月5日下午3点")
    assert String.starts_with?(t.start, "2024-03-05T15:00:00")
  end

  test "parse_time invalid returns nil" do
    assert JioNLP.parse_time("not a time") == nil
  end

  test "simhash identical text" do
    a = JioNLP.simhash("今天天气真好")
    b = JioNLP.simhash("今天天气真好")
    assert a == b
    assert JioNLP.hamming_distance(a, b) == 0
  end

  test "simhash near-duplicate has small distance" do
    a = JioNLP.simhash("今天天气真好")
    b = JioNLP.simhash("今天天气非常好")
    d = JioNLP.hamming_distance(a, b)
    assert d < 20
  end

  test "simhash_similarity range" do
    a = JioNLP.simhash("hello world")
    assert JioNLP.simhash_similarity(a, a) == 1.0
  end

  # ─── eighth round additions ──────────────────────────────────────────────

  test "parse_time holiday 国庆节" do
    t = JioNLP.parse_time("国庆节", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-10-01")
  end

  test "parse_time holiday 双十一" do
    t = JioNLP.parse_time("双十一", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-11-11")
  end

  test "parse_time range" do
    t = JioNLP.parse_time("2024年3月5日到8日")
    assert t.time_type == "time_span"
    assert String.starts_with?(t.start, "2024-03-05")
    assert String.starts_with?(t.end, "2024-03-08")
  end

  test "pinyin phrase idiom" do
    # "一丘之貉" is in pinyin_phrase.zip → phrase trie should override the
    # default single-char reading for 貉.
    r = JioNLP.pinyin("一丘之貉")
    assert r == ["yī", "qiū", "zhī", "hé"]
  end

  test "extract_keyphrase returns list" do
    text = "机器学习是人工智能的一个分支,研究如何从数据中自动学习规律和模式。机器学习广泛应用于自然语言处理。"
    r = JioNLP.extract_keyphrase(text, top_k: 5)
    assert length(r) <= 5
    assert Enum.all?(r, &match?(%JioNLP.KeyPhrase{}, &1))
  end

  test "extract_keyphrase empty text" do
    assert JioNLP.extract_keyphrase("") == []
  end

  # ─── ninth round additions ───────────────────────────────────────────────

  test "sentiment_score neutral for empty" do
    assert JioNLP.sentiment_score("") == 0.5
  end

  test "sentiment_score positive text" do
    s = JioNLP.sentiment_score("今天是美好的一天,我非常开心。")
    assert s > 0.5
  end

  test "sentiment_score negative text" do
    s = JioNLP.sentiment_score("事故造成严重伤亡,令人悲痛万分。")
    assert s < 0.5
  end

  test "extract_summary returns top_k sentences" do
    text = "北京是中国的首都。上海是金融中心。广州是南方大都市。深圳是科技之都。"
    out = JioNLP.extract_summary(text, 2)
    assert length(out) == 2
    assert Enum.all?(out, &match?(%JioNLP.SummarySentence{}, &1))
  end

  test "extract_summary preserves order" do
    text = "第一句话。第二句话。第三句话。第四句话。"
    out = JioNLP.extract_summary(text, 3)
    positions = Enum.map(out, & &1.position)
    assert positions == Enum.sort(positions)
  end

  test "swap_char_position deterministic with seed" do
    a = JioNLP.swap_char_position("中华人民共和国是美好的家园", 3, swap_ratio: 0.3, seed: 42)
    b = JioNLP.swap_char_position("中华人民共和国是美好的家园", 3, swap_ratio: 0.3, seed: 42)
    assert a == b
  end

  test "swap_char_position variants have same length" do
    src = "中华人民共和国是美好的家园"
    src_len = String.length(src)
    r = JioNLP.swap_char_position(src, 3, swap_ratio: 0.3, seed: 1)
    Enum.each(r, fn v -> assert String.length(v) == src_len end)
  end

  # ─── tenth round additions ──────────────────────────────────────────────

  test "random_add_delete deterministic with seed" do
    a = JioNLP.random_add_delete("今天天气真好我要去公园散步", 3, add_ratio: 0.3, delete_ratio: 0.1, seed: 42)
    b = JioNLP.random_add_delete("今天天气真好我要去公园散步", 3, add_ratio: 0.3, delete_ratio: 0.1, seed: 42)
    assert a == b
    assert length(a) > 0
  end

  test "homophone_substitution generates variants" do
    r = JioNLP.homophone_substitution("今天天气真好", 3, sub_ratio: 0.5, seed: 42)
    assert length(r) == 3
    # Same CJK length after substitution.
    Enum.each(r, fn v -> assert String.length(v) == String.length("今天天气真好") end)
  end

  test "replace_entity respects types and offsets" do
    text = "一位名叫“伊藤慧太”的男子身着日本匠人常穿的作务衣"
    entities = [
      %JioNLP.NamedEntity{text: "伊藤慧太", entity_type: "Person", offset: {15, 27}},
      %JioNLP.NamedEntity{text: "日本", entity_type: "Country", offset: {33, 39}}
    ]
    replacements = [
      {"Person", [{"张三", 3.0}, {"李四", 2.0}]},
      {"Country", [{"美国", 2.0}, {"英国", 1.0}]}
    ]

    out = JioNLP.replace_entity(text, entities, replacements, n: 3, replace_ratio: 0.9, seed: 42)
    assert length(out) > 0

    for v <- out do
      assert length(v.entities) == 2
      for e <- v.entities do
        {s, e_end} = e.offset
        assert binary_part(v.text, s, e_end - s) == e.text
      end
    end
  end

  test "recognize_entities picks leftmost longest" do
    lexicon = [
      {"Drug", ["阿司匹林", "布洛芬"]},
      {"Univ", ["北京", "北京大学"]}
    ]

    r = JioNLP.recognize_entities("他在北京大学吃了阿司匹林", lexicon)
    assert length(r) == 2

    names = Enum.map(r, & &1.text)
    assert "北京大学" in names
    refute "北京" in names
    assert "阿司匹林" in names
  end

  # ─── eleventh round additions ───────────────────────────────────────────

  test "parse_time timespan 8点到12点" do
    t = JioNLP.parse_time("8点到12点", reference_time: "2024-03-15T10:30:00")
    assert t.time_type == "time_span"
    assert t.start =~ "T08:00:00"
    assert t.end =~ "T12:00:00"
  end

  test "parse_time timespan with relative day" do
    t = JioNLP.parse_time("明天下午3点到5点", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-16T15:00:00")
    assert String.starts_with?(t.end, "2024-03-16T17:00:00")
  end

  test "parse_time recurring 每周一" do
    t = JioNLP.parse_time("每周一", reference_time: "2024-03-15T10:30:00")
    # 2024-03-15 is Friday → next Monday = 2024-03-18
    assert String.starts_with?(t.start, "2024-03-18")
  end

  test "parse_time recurring 每月20号" do
    t = JioNLP.parse_time("每月20号", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-20")
  end

  test "parse_time recurring daily with clock" do
    t = JioNLP.parse_time("每天早上8点", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-16T08:00:00")
  end

  # ─── twelfth round additions ───────────────────────────────────────────

  test "parse_time delta 三天后" do
    t = JioNLP.parse_time("三天后", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-18")
  end

  test "parse_time delta 半小时后" do
    t = JioNLP.parse_time("半小时后", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-15T11:00:00")
  end

  test "parse_time delta 两周前" do
    t = JioNLP.parse_time("两周前", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-03-01")
  end

  test "parse_time named 本周" do
    t = JioNLP.parse_time("本周", reference_time: "2024-03-15T10:30:00")
    assert t.time_type == "time_span"
    assert String.starts_with?(t.start, "2024-03-11")
    assert String.starts_with?(t.end, "2024-03-17")
  end

  test "parse_time named 上个月" do
    t = JioNLP.parse_time("上个月", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-02-01")
    # 2024 is a leap year → 29 days in Feb
    assert String.starts_with?(t.end, "2024-02-29")
  end

  test "parse_time named 去年" do
    t = JioNLP.parse_time("去年", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2023-01-01")
    assert String.starts_with?(t.end, "2023-12-31")
  end

  # ─── thirteenth round additions ────────────────────────────────────────

  test "parse_time fuzzy 刚才" do
    t = JioNLP.parse_time("刚才", reference_time: "2024-03-15T10:30:00")
    assert t.definition == "blur"
    # start/end are ISO strings; both strictly before reference (10:30).
    assert t.start < "2024-03-15T10:30:00"
  end

  test "parse_time fuzzy 最近 spans past days" do
    t = JioNLP.parse_time("最近", reference_time: "2024-03-15T10:30:00")
    assert t.definition == "blur"
    # start at least 5 days before ref
    {:ok, start_dt} = NaiveDateTime.from_iso8601(t.start)
    {:ok, ref_dt} = NaiveDateTime.from_iso8601("2024-03-15T10:30:00")
    assert NaiveDateTime.diff(ref_dt, start_dt, :day) >= 4
  end

  test "bpe roundtrip mixed scripts" do
    src = "Hello 世界 🌍 テスト"
    assert JioNLP.bpe_decode(JioNLP.bpe_encode(src)) == src
  end

  test "bpe space remapped" do
    # Space is NOT a printable ASCII member in the GPT-2 byte-level scheme.
    assert JioNLP.bpe_encode(" ") == "Ġ"
    assert JioNLP.bpe_decode("Ġ") == " "
  end

  test "extract_summary_mmr returns top_k" do
    text = "北京是中国首都。上海是金融中心。广州是南方大都市。深圳是科技之都。"
    out = JioNLP.extract_summary_mmr(text, 2, 0.7)
    assert length(out) == 2
    assert Enum.all?(out, &match?(%JioNLP.SummarySentence{}, &1))
  end

  test "extract_summary_mmr lambda 1 matches basic" do
    text = "第一句话。第二句话。第三句话。"
    a = JioNLP.extract_summary(text, 2) |> Enum.map(& &1.position)
    b = JioNLP.extract_summary_mmr(text, 2, 1.0) |> Enum.map(& &1.position)
    assert a == b
  end

  # ─── fourteenth round additions ────────────────────────────────────────

  test "parse_time lunar 春节 2024" do
    t = JioNLP.parse_time("2024年春节")
    assert String.starts_with?(t.start, "2024-02-10")
  end

  test "parse_time lunar 中秋 alias" do
    t = JioNLP.parse_time("中秋", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-09-17")
  end

  test "parse_time lunar 端午节 2023" do
    t = JioNLP.parse_time("2023年端午节")
    assert String.starts_with?(t.start, "2023-06-22")
  end

  test "parse_time lunar 除夕" do
    t = JioNLP.parse_time("除夕", reference_time: "2024-03-15T10:30:00")
    assert String.starts_with?(t.start, "2024-02-09")
  end

  test "parse_time lunar 2019 春节 via full 1900-2100 table" do
    # Round 15 added the full 1900-2100 lunar converter, so 2019 is now in
    # range. 2019-02-05 is the correct Gregorian date for 2019's 春节.
    t = JioNLP.parse_time("2019年春节")
    assert String.starts_with?(t.start, "2019-02-05")
  end

  test "parse_time lunar truly out of range returns nil" do
    # 1899 is outside the 1900-2100 lunar window.
    assert JioNLP.parse_time("1899年春节") == nil
  end

  test "extract_keyphrase_textrank returns list" do
    text = "机器学习是人工智能的一个分支。机器学习研究数据。机器学习应用广泛。"
    r = JioNLP.extract_keyphrase_textrank(text, top_k: 3)
    assert length(r) <= 3
    assert Enum.all?(r, &match?(%JioNLP.KeyPhrase{}, &1))
  end

  test "extract_keyphrase_textrank sorted descending" do
    text = "北京是中国首都。北京有名胜古迹。北京人口众多。"
    r = JioNLP.extract_keyphrase_textrank(text, top_k: 5)

    weights = Enum.map(r, & &1.weight)
    assert weights == Enum.sort(weights, &>=/2)
  end
end
