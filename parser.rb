require './exception'
require './ast/ast_integer'

# =============================================================================
# 構文解析器
# =============================================================================

# TODO ポインタ型サイズ
SIZE_OF_POINTER = 4

class Parser
  def initialize filepath
    @filepath = filepath

    # TODO データ型一覧・サイズ
    @data_types = [
      {sym: :T_KW_INT, size: 4},
      {sym: :T_KW_CHAR, size: 1},
      {sym: :T_KW_VOID, size: 0}
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
    program = program(@tokens[0])
  end

private

  # 開始記号 program の解析
  def program token
    AppLoger.call_in

    nodes = []
    loop do

      # 宣言部解析
      # TODO
      # グローバルスコープはマクロを除けば
      # - 変数宣言
      # - プロトタイプ宣言
      # - 構造体定義
      # - enum型定義
      # - typedef宣言
      # parse_struct_declare(token)
      # parse_enum_declare(token)
      # parse_typedef_declare(token)

      # ===================================================
      # 宣言部解析
      # 関数宣言・変数宣言共通
      # ===================================================
      declare_info = parse_decration_head(token)
      token = next_token
      if check_token(token, :T_OPEN_PAREN)
        # 関数定義
        node = parse_func_define(token)
        nodes << node
      else
        # 変数宣言
        parse_global_variables(token, declare_info)
      end
      token = next_token
      if token.nil?
        break
      end
    end
    nodes
  end

  # 宣言部解析
  # int a;
  # int a[10];
  # int *a;
  # int a = 10;
  # int a(void); int a(void){}
  def parse_decration_head token
    AppLoger.call_in
    access_level = check_access_level(token)
    data_type = {}
    ret = check_data_type(token, data_type)
    unless ret
      raise RccException.new("PARSE_ERROR",
      "#{@filepath}:#{token[:lineno]}, unexpected '#{token}' found. Data type expected.")
    end

    # 型の後に識別子がない → 異常
    token = next_token
    token_mismatch_error(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
    h = {access_level: access_level, name:token[:value], data_type: data_type}
    puts h
    AppLoger.call_out

    h
  end

  # 変数宣言の解析
  # 変数宣言 static int a;
  # 関数定義 static int a();

  # アクセス修飾子チェック
  # :default ファイル内(externなし)
  # :extern extern宣言
  # :static
  def check_access_level token
    access_level = :default
    access_level = :extern if  check_token(token, :T_KW_EXTERN)
    access_level = :extern if  check_token(token, :T_KW_STATIC)
    access_level
  end

  # グローバル変数の解析
  # int a;
  # int a[123];
  # int a = 10;
  def parse_global_variables token, var_info
    AppLoger.call_in
    dimention = 1
    element_size = 1
    default_value = 0

    # セミコロン → 宣言のみで終了
    return var_info if check_token(token, :T_SEMICOLON)

    if check_token(token, :T_OPEN_BRACKET)
      # 配列型
      until check_token(token, :T_SEMICOLON)
        token = next_token
        check_token(token, :T_OPEN_BRACKET)

        # 添え字が数値でなければ異常
        token_mismatch_error(token, :T_NUMBER) unless check_token(token, :T_NUMBER)

        # 要素のサイズを計算
        elm_size *= token[:value].to_i

        # 閉じかっこ']' でなければ異常
        token_mismatch_error(token, :T_CLOSE_BRACKET) unless check_token(token, :T_CLOSE_BRACKET)
      end
    elsif check_token(token, :T_EQUAL)
      # 宣言と同時の代入
      token = next_token

      # 代入は定数であること
      # TODO とりあえず直値のみとする
      token_mismatch_error(token, :T_NUMBER) unless check_token(token, :T_NUMBER)
      token = next_token
      token_mismatch_error(token, :T_SEMICOLON) unless check_token(token, :T_SEMICOLON)

      # 初期値を更新
      default_value = token[:value].to_i
    end

    # 初期値, 配列次元数
    h = {default_value: default_value, dimention: dimention, element_size: element_size}
    puts h
    AppLoger.call_out
    h
  end

  # 関数定義
  def parse_func_define token
    AppLoger.call_in

    # 関数宣言部 - (引数リスト)の解析
    func_def_info = parse_func_define_head(token)

    # 関数の処理部解析
    token = next_token
    func_body_info = parse_func_define_body token
    func_def_info[:func_body_info] = func_body_info

    puts func_def_info
    AppLoger.call_out
    func_def_info
  end

  # 関数宣言部解析
  # 引数のかっこ以降の解析を行う
  def parse_func_define_head token
    AppLoger.call_in

    # 引数チェック
    f_def_info = {}
    args = check_args(token)
    f_def_info[:args] = args

    puts f_def_info
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
puts "local_vars:#{local_vars}"

    # 関数本体の'{'に対応する'}'が見つかるまで解析を行う
    token = cur_token
    puts "token:#{token}"
    max_nest_level = 0
    loop do
      if token[:sym] == :T_OPEN_BRACE
        stack_tmp.push(token)
        max_nest_level += 1 if  max_nest_level < stack_tmp.size
        next
      end

      # 閉じかっこ'}'による関数定義の終了チェック
      if token[:sym] == :T_CLOSE_BRACE
        top = stack_tmp.pop
        if top[:sym] == :T_OPEN_BRACE
          break if stack_tmp.size == 0
        else
          raise RccException.new("PARSE_ERROR",
            "#{@filepath}:#{token[:lineno]}, unexpected '}' found.")
        end
      end

      # 関数内処理(文)の解析
      ret = parse_stmt(token)
      token = next_token
    end
    func_body_info[:max_nest_level] = max_nest_level
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
      if check_data_type(token, var_info)
        token = next_token
        token_mismatch_error(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
        var_info[:name] = token[:value]
        local_var_list << var_info

        token = next_token
        # ex).int hoge;
        if token[:sym] == :T_SEMICOLON
          # 宣言終了';' → 変数名を保持
          # 次の変数へ
          token = next_token;
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
    AppLoger.call_out

    # 常に正常終了
    true
  end

  # 文の解析
  # 文 → 代入、関数呼び出し
  def parse_stmt token
    AppLoger.call_in
    until token[:sym] == :T_SEMICOLON
      case token[:sym]
      when :T_IDENTIFER
        token = next_token
        puts "token:#{token}"
        if check_token(token, :T_EQUAL)
          # 式
          token = next_token
          parse_exp(token)
        elsif check_token(token, :T_OPEN_PAREN)
          puts "function call!!!"
          # 関数呼び出し
          token = next_token
          ast = parse_func_call(token)

        else
          # 代入でも関数呼び出しでもない
          raise RccException.new("PARSE_ERROR",
            "#{@filepath}:#{token[:lineno]}" +
            " unexpected token sym:'#{token[:sym]}', token:'#{token[:value]}'.")
        end
      when :T_KW_RETURN
        puts "return !!!!!!!!"
        token = next_token
        parse_exp token
        token = cur_token
        puts "cur token:#{token}"
      else
        # 式でも関数呼び出しでもない
        raise RccException.new("PARSE_ERROR",
          "#{@filepath}:#{token[:lineno]}" +
          " unexpected token sym:'#{token[:sym]}', token:'#{token[:value]}'.")
      end
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
    # 引数チェック
    until token[:sym] == T_CLOSE_PAREN
      if check_token(token, :T_IDENTIFER)
        # ローカル変数 or グローバル変数
      elsif check_token(token, :T_IDENTIFER)
        # 直値を引数として渡している
      end
    end
    AppLoger.call_out
  end

  # 式
  # None
  # indetifyer
  # term
  # term + term
  # term - term
  def parse_exp token
    AppLoger.call_in
    puts "token:#{token}"
    ret = term(token)
    AppLoger.call_out
  end

  # 項
  # - factor
  # - factor * factor
  # - (exp)
  # - 数値 123
  # - 掛け算,割り算 a * 3, 123 / 5
  def term token
    AppLoger.call_in
    ast = nil
    loop do
      ast = factor(token)
      unless ast.nil?
        token = next_token
        break if token.nil?

        if token[:sym] == :T_ASTER || token[:sym] == :T_SLASH
          token = next_token
          ast_right = factor(token)
          if ast_right.nil?
            # データ型がない
            raise RccException.new("PARSE_ERROR", "#{@filepath}:#{token[:lineno]} factor is expected.")
          end
        else
          puts "not * or /"
          puts "token:#{token}"
          break
        end
      else
        # factor 以外のトークン
        puts "************* not factor #{token} ********************"
        break
      end
    end
    AppLoger.call_out
    ast
  end

  # 因子
  # - 数値
  def factor token
    if check_token(token, :T_INTEGER)
      ast = ASTInteger.new(token)
    end
    ast
  end

 # 現在位置のトークンを取得する
 def cur_token
   @tokens[@token_pos]
 end

  # 次のトークンを取得する
  def next_token
    # トークン位置チェック
    return nil if (@tokens.length - 1) < (@token_pos + 1)

    @token_pos += 1
    @tokens[@token_pos]
  end

  # トークン位置をチェック処理などで余分に読み出しをしてしまったとき用
  # 余分な呼び出しをしないようにもできるが同じような処理が多くなるためトークンの返却で対応する
  def back_token_pos
    @token_pos -= 1
  end

  # 指定したタイプのトークンかどうか調べる
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
          "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not Data type.")
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
