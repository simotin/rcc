require './exception'

# =============================================================================
# 構文解析器
# Policy
#   - LL(1)パーサー
# =============================================================================

# TODO データサイズ
SIZE_OF_INT = 4
SIZE_OF_CHAR = 1

class Parser
  def initialize filepath
    @filepath = filepath

    @data_types = [
      {sym: :T_KW_INT, size: SIZE_OF_INT},
      {sym: :T_KW_CHAR, size: SIZE_OF_CHAR}
    ]
  end

  def parse tokens

    @tokens = tokens
    @token_pos = 0
    # ========================================
    # 文法ルールに則って解析を行う
    # 構文解析の結果ASTの構築を行う
    # 開始記号をprogramとする
    # ========================================
    result = program(@tokens[0])
  end

private

  # 開始記号 program の解析
  def program token
    AppLoger.call_in

    loop do
      # 関数定義
      node = func_define(token)
    end
  end

  # 関数定義
  def func_define token
    AppLoger.call_in

    # とりあえずint型のみとしてみる
    ret = check_token(token, :T_KW_INT)
    token_mismatch_error(token, :T_KW_INT) unless ret


    # ポインタチェック
    token = next_token
    pointer = check_pointer(token)
    AppLoger.trace("pointer: #{pointer}")

    # 関数名
    ret = check_token(token, :T_IDENTIFER)
    token_mismatch_error(token, :T_IDENTIFER) unless ret
    AppLoger.trace("function name: #{token[:value]}")

    # 引数チェック
    token = next_token
    check_args(token)

    AppLoger.call_out
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
  end
  def next_token
    # トークン位置チェック
    return nil if (@tokens.length - 1) < (@token_pos + 1)

    @token_pos += 1
    @tokens[@token_pos]
  end

  # 指定したタイプのトークンかどうか調べる
  # 一致しなければトークン異常とする
  def check_token token, token_type
    token[:sym] == token_type
  end

  # ポインタの数を数える
  def check_pointer token
    pointer = 0
    while token[:sym] == :T_ASTER
      pointer += 1
      token = next_token
    end
    pointer
  end

  # 引数の情報を調べる
  def check_args token
    AppLoger.call_in

    # 開始かっこのチェック
    ret = check_token(token, :T_OPEN_PAREN)
    token_mismatch_error(token, :T_OPEN_PAREN) unless ret

    argc = 0
    argv = []

    # 閉じかっこが出てくるまでは、 型 変数名 カンマ が続く
    token = next_token
    until check_token(token, :T_CLOSE_PAREN) != true
      ret = check_data_type(token)
      if ret == false
        # データ型がない
        raise RccException.new("PARSE_ERROR",
          "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not Data tyoe.")
      end

      # 変数名取得
      token = next_token
      ret = check_token(token, :T_IDENTIFER)
      token_mismatch_error(token, :T_IDENTIFER) unless ret

      token = next_token
      if (token[:sym] == :T_COMMA)
        # カンマであれば次のトークンの処理を行う
        token = next_token
      elsif token[:sym] == :T_CLOSE_PAREN
        # 閉じかっこであれば引数のチェックを終了する
        break
      else
        raise RccException.new("PARSE_ERROR",
          "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not expected.")
      end
    end
    AppLoger.call_out
  end

  # データ型かどうかチェックする
  # TODO C言語の場合構造体やtypedefが可能だが、とりあえずINT型のみのチェックとする
  def check_data_type token
    data_type_matched = false
    @data_types.each do |data_type|
      if token[:sym] == data_type[:sym]
        data_type_matched = true
        puts data_type[:sym]
        break
      end
    end
    data_type_matched
  end


  # 期待したトークンタイプでない
  def token_mismatch_error token, expect
    raise RccException.new("PARSE_ERROR", "#{@filepath}:#{token[:lineno]} '#{expect}' is expected, receive token is type:'#{token[:sym]}', token:'#{token[:value]}'.")
  end
end
