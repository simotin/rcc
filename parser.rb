require './exception'

# =============================================================================
# 構文解析器
# =============================================================================

# TODO データサイズ
SIZE_OF_INT = 4
SIZE_OF_CHAR = 1
SIZE_OF_POINTER = 1

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
      node = parse_func_define(token)
    end
  end

  # 関数定義
  def parse_func_define token
    AppLoger.call_in

    # 関数宣言部 - 戻り値 関数名(引数リスト)の解析
    func_def_info = parse_func_define_head token

    # 関数の処理部解析
    token = next_token
    parse_func_define_body token
    token_mismatch_error(token, :T_OPEN_PAREN) unless check_token(token, :T_OPEN_PAREN)

    AppLoger.call_out
  end

  # 関数宣言部解析
  def parse_func_define_head token
    AppLoger.call_in

    f_def_info = {}

    # 戻り値型チェック
    ret_info = {}
    ret = check_data_type(token, ret_info)
    unless ret
      # 戻り値型が不正
      token_mismatch_error(token, :T_KW_INT) unless check_token(token, :T_KW_INT)
    end

    f_def_info[:ret] = ret_info

    # 関数名
    token = next_token
    token_mismatch_error(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
    f_def_info[:name] = token[:value]
    AppLoger.trace("function name: #{token[:value]}")

    # 引数チェック
    token = next_token
    args = check_args(token)
    f_def_info[:args] = args

    AppLoger.call_out
    f_def_info
  end

  # 関数処理部解析
  def parse_func_define_body token
    AppLoger.call_in
    func_body_info = {}
    stack_tmp = []

    # 開始の'{'記号チェック
    token_mismatch_error(token, :T_OPEN_BRACE) unless check_token(token, :T_OPEN_BRACE)

    # 対応チェック用スタックにpush
    stack_tmp.push(token)

    # ローカル変数の宣言チェック
    # TODO ローカル変数の情報を更新
    token = next_token
    local_vars = []
    parse_local_variables_declare(token, local_vars)

    # 関数本体の'{'に対応する'}'が見つかるまで解析を行う
    loop do
      token = next_token
      # 閉じかっこ'}'による関数定義の終了チェック
      if token[:sym] == :T_CLOSE_BRACE
        top = stack_tmp.pop
        if top[:sym] == :T_OPEN_BRACE
          # 関数の終了'}'の検出
          break if stack_tmp.size == 0
        else
          raise RccException.new("PARSE_ERROR",
            "#{@filepath}:#{token[:lineno]}, unexpected '}' found.")
        end
      end

      # 関数内処理(文)の解析
      ret = parse_stmt(token)
    end
    AppLoger.call_out
    func_body_info
  end

  # ローカル変数の宣言チェック
  def parse_local_variables_declare token, local_var_list
    AppLoger.call_in

    # TODO int a; int b; のような宣言には対応できているが、カンマ区切りによる複数の変数宣言には対応できていない
    # TODO 宣言と同時の代入に対応できていない
    loop do

      var_info = {}
      ret = check_data_type(token, var_info)
      if ret
        token = next_token
        token_mismatch_error(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
        var_info[:name] = token[:value]
        local_var_list << var_info

        token = next_token
        # ex).int hoge;
        if token[:sym] == :T_SEMICOLON
          # 宣言終了';' → 変数名を保持
          # 次の変数へ
          next
        end
=begin
        # ex).int hoge = 123;
        if token[:sym] == :T_EQUAL
          # 代入 → 式かどうかをチェックする
          token = next_token
          exp(token)
          next
        end
=end
      else
        # 変数宣言終了 → 処理の解析へ
        break
      end
    end
    puts "local_var_list:#{local_var_list}"
    puts token
    AppLoger.call_out

    # 常に正常終了
    true
  end

  # 文の解析
  # 文 → 代入、関数呼び出し
  def parse_stmt token
    AppLoger.call_in
    # 文 → 代入、関数呼び出し
    if check_token(token, :T_IDENTIFER)
      token = next_token
      ret = check_token(token, :T_EQUAL)
      if ret
        # 式
        token = next_token
        parse_exp(token)
      else
        # 関数呼び出し
        token = next_token
        token_mismatch_error(token, :T_OPEN_PAREN) unless check_token(token, :T_OPEN_PAREN)
      end
    else
      # 式でも関数呼び出しでもない
      raise RccException.new("PARSE_ERROR",
        "#{@filepath}:#{token[:lineno]} stmt is expected '#{token[:sym]}', token:'#{token[:value]}'.")
    end
    AppLoger.call_out
  end

  # 代入文の解析
  def parse_assign token
    AppLoger.call_in
  end

  # 関数呼び出しの解析
  def parse_func_call token
    AppLoger.call_in
    if check_token(token[:sym], :T_IDENTIFER)
    end
    AppLoger.call_out
  end
  # 式
  # - None
  # - term
  # - term + term
  # - term - term
  def parse_exp token
    # TODO
    2017-05-07 ここまで a = 123;の行で式の解析までたどり着いた
    AppLoger.call_in
    term(token)
    nt = next_token
    AppLoger.call_out
    return if nt.nil?

  end

  # 項
  # - 数値
  # - 掛け算,割り算
  def term token
  end

  # 次のトークンを取得する
  def next_token
    # トークン位置チェック
    return nil if (@tokens.length - 1) < (@token_pos + 1)

    @token_pos += 1
    @tokens[@token_pos]
  end

  # トークン位置を
  # 注意:チェック処理などで余分に読み出しをしてしまったとき用
  # 余分な呼び出しをしないようにもできるが同じような処理が多くなるためトークンの返却で対応する
  def back_token_pos
    @token_pos -= 1
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

    # 注意:最後の1トークンは次の解析の為、便宜上戻しておく
    back_token_pos

    pointer
  end

  # 引数の情報を調べる
  def check_args token
    AppLoger.call_in

    # 開始かっこのチェック
    args_info = []
    ret = check_token(token, :T_OPEN_PAREN)
    token_mismatch_error(token, :T_OPEN_PAREN) unless ret

    # 閉じかっこが出てくるまでは、 型 変数名 カンマ が続く
    token = next_token
    arg_info = {}
    until check_token(token, :T_CLOSE_PAREN) == true
      ret = check_data_type(token, arg_info)
      if ret == false
        # データ型がない
        raise RccException.new("PARSE_ERROR",
          "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not Data tyoe.")
      end

      # 変数名取得
      token = next_token
      ret = check_token(token, :T_IDENTIFER)
      token_mismatch_error(token, :T_IDENTIFER) unless ret
      arg_info[:name] = token[:value]
      args_info << arg_info

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
    args_info
  end

  # データ型かどうかチェックする
  # TODO C言語の場合構造体やtypedefが可能だが、とりあえずINT型のみのチェックとする
  # TODO 配列型のチェック
  def check_data_type token, data_type_info
    AppLoger.call_in
    data_type_matched = false
    @data_types.each do |data_type|
      if token[:sym] == data_type[:sym]
        data_type_matched = true
        data_type_info[:data_type] = token[:sym]
        data_type_info[:size] = data_type[:size]
        break
      end
    end

    if data_type_matched
      # ポインタ数のチェック
      token = next_token
      pointer = check_pointer(token)
      data_type_info[:pointer] = pointer

      # ポインタ型であればサイズ更新
      data_type_info[:size] = SIZE_OF_POINTER if (0 < pointer)

      # TODO 配列のチェック未対応 →とりあえず1固定
      data_type_info[:elms] = 1
    end

    AppLoger.call_out

    # 0:結果 1:データ型情報
    data_type_matched
  end

  # 期待したトークンタイプでない
  def token_mismatch_error token, expect
    raise RccException.new("PARSE_ERROR", "#{@filepath}:#{token[:lineno]} '#{expect}' is expected, receive token is type:'#{token[:sym]}', token:'#{token[:value]}'.")
  end
end
