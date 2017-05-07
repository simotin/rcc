#!/usr/local/bin/ruby

require './app_logger'
require './scanner'
require './parser'
require './preproseccer'

# =============================================================================
# 実装方針
#   - 各フェーズの独立性を高める
#   - 先に字句解析を行う
# =============================================================================
class Rcc
  def compile filepath
    @preprocessor = Preprocessor.new
    @scanner = Scanner.new filepath
    @parser = Parser.new filepath

    code = File.read(filepath)

    # =========================================================================
    # フロントエンド 前処理、字句解析～構文解析
    # =========================================================================
    # 前処理
    preprocessed_code = @preprocessor.execute(code)

    # 字句解析
    tokens = @scanner.scan(preprocessed_code)

    # 構文解析
    parse_result = @parser.parse(tokens)

    # =========================================================================
    # ミドルエンド 意味解析～最適化
    # =========================================================================
    # 意味解析
    #analyze

    # 最適化
    #optimize

    # =========================================================================
    # バックエンド 意味解析～最適化
    # =========================================================================
    # コード実行
    #execute
  end

private

  def analyze
    AppLoger.trace("#{__method__} called...")
  end

  def optimize
    AppLoger.trace("#{__method__} called...")
  end

  def execute
    AppLoger.trace("#{__method__} called...")
  end

  def push_token symbol, value
    @tokens << {sym: symbol, value: value}
  end
end

# 解析異常を例外としてraiseしているのでここで補足する
# TODO
#   - 例外発生時のリソース解放とか考慮していないので補足するレイヤは考える必要がある
begin
  AppLoger.setup "rcc"

  rcc = Rcc.new
  if ARGV.size < 1
    puts "No input file"
    exit -1
  end

  filepath = ARGV[0]
  rcc = Rcc.new
  rcc.compile(filepath)
rescue RccException => ex
  puts ex.message
end
