require 'strscan'
require './app_logger'

# =============================================================================
# 実装方針
#   - 各フェーズの独立性を高める
#   - 先に字句解析を行う
# =============================================================================
class Rcc
  def compile code

    # =========================================================================
    # フロントエンド 字句解析～構文解析
    # =========================================================================
    # 解析初期化
    initialize_status

    # 字句解析
    scan code

    # 構文解析
    parse

    # =========================================================================
    # ミドルエンド 意味解析～最適化
    # =========================================================================
    # 意味解析
    analyze

    # 最適化
    optimize

    # =========================================================================
    # バックエンド 意味解析～最適化
    # =========================================================================
    # コード実行
    execute

  end

private
  def initialize
    @pos = 0
    @tokens = []
    @token_rules = [
      { sym: :T_IDENTIFER, reg: /[a-z]|[A-Z]+/ },
      { sym: :T_NUMBER, reg: /[0-9]+/ },
      { sym: :T_EQUAL, reg: /\=/ },
      { sym: :T_ADD, reg: /\+/ },
      { sym: :T_DEL, reg: /\-/ },
      { sym: :T_MUL, reg: /\*/ },
      { sym: :T_OP, reg: /\(/ },
      { sym: :T_CP, reg: /\)/ }
    ]
  end

  def initialize_status
  end

  # 字句解析
  def scan line
    s = StringScanner.new line
    while !s.eos?
      # スペース,タブはスキップ(無視)
      s.scan(/[\s\t]+/)
      @token_rules.each do |rule|
        c = s.scan(rule[:reg])
        push_token(rule[:sym], c) unless c.nil?
      end
    end
    puts @tokens.to_s
  end

  # 構文解析
  def parse
    AppLoger.trace("#{__method__} called...")
  end

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

# ==============================================================================
# test
# ==============================================================================
AppLoger.setup

rcc = Rcc.new
rcc.compile "a = (1 + 2) * 3 - 1"
