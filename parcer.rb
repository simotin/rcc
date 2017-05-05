require 'ast'

# =============================================================================
# 構文解析器
# Policy
#   - LL(1)パーサー
# =============================================================================
class Parcer
  def parce tokens

    # トークン情報を初期化
    @tokens = tokens
    @token_pos = 0

    # ========================================
    # 文法ルールに則って解析を行う
    # 構文解析の結果ASTの構築を行う
    # ========================================
    result = program(next_token)

  end

private

  def program token
    ast = AST.new
    loop do
      parse_error if token[:sym] != :T_IDENTIFER
      token = next_token

      parse_error if nt[:sym] != :T_EQUAL
      token = next_token

      if token.nil?

      end
    end

    # TODO
    # - 関数呼び出し
    # - 宣言

  end

  # 式
  # - None
  # - term
  # - term + term
  # - term - term
  def exp token
    term(token)
    nt = next_token
    return if nt.nil?
  end

  # 項
  # - 数値
  # - 掛け算,割り算
  def term token
    if token[:sym] == :T_INTEGER

  end

  def next_token
    # トークン位置チェック
    return nil if next_token (@tokens.length - 1) < (@token_pos + 1)
    @token_pos += 1
    @tokens[@token_pos]
  end

  def parse_error token, expect
    throw "parse error #{expect} is expected, but #{token[:sym]}."
  end

end
