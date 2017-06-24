require './exception'
require './ast/ast_integer'

# TODO ポインタ型サイズ
SIZE_OF_POINTER = 4

class Parser
  def initialize filepath
    @filepath = filepath

    # TODO データ型・サイズ
    @data_types = [
      {sym: :T_KW_INT, size: 4},
      {sym: :T_KW_CHAR, size: 1},
      {sym: :T_KW_VOID, size: 0}
    ]
  end

  def parse tokens
    @tokens = tokens
    @token_pos = 0
    @parse_result = {}
    @function_list = []
    @parse_result = program(@tokens[0])
  end

private
  def program token
    AppLoger.call_in

    nodes = []
    loop do
      declare_info = parse_decration_head(token)
      token = next_token
      if check_token(token, :T_OPEN_PAREN)
        func_info = parse_func_define(token)

        # 関数表に登録
        func_info.merge! declare_info
        @function_list << func_info
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
  def parse_decration_head token
    AppLoger.call_in
    access_level = check_access_level(token)
    data_type = {}
    unless check_data_type(token, data_type)
      parse_error "#{@filepath}:#{token[:lineno]}, unexpected '#{token}' found. Data type expected."
    end

    token = next_token
    unexpected_token(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)

    dec_info = {name:token[:value], access_level: access_level, data_type: data_type}
    AppLoger.call_out
    dec_info
  end

  # 変数宣言の解析
  def check_access_level token
    access_level = :default
    access_level = :extern if  check_token(token, :T_KW_EXTERN)
    access_level = :static if  check_token(token, :T_KW_STATIC)
    access_level
  end

  # グローバル変数の解析
  def parse_global_variables token, var_info
    AppLoger.call_in
    dimention = 1
    element_size = 1
    default_value = 0

    # セミコロン → 宣言のみで終了
    return var_info if check_token(token, :T_SEMICOLON)

    if check_token(token, :T_OPEN_BRACKET)
      until check_token(token, :T_SEMICOLON)
        token = next_token
        check_token(token, :T_OPEN_BRACKET)

        # 添え字が数値でなければ異常
        unexpected_token(token, :T_NUMBER) unless check_token(token, :T_NUMBER)

        elm_size *= token[:value].to_i

        # 閉じかっこ']' でなければ異常
        unexpected_token(token, :T_CLOSE_BRACKET) unless check_token(token, :T_CLOSE_BRACKET)
      end
    elsif check_token(token, :T_EQUAL)
      # 宣言と同時の代入
      token = next_token
      # TODO とりあえず直値のみとする
      unexpected_token(token, :T_NUMBER) unless check_token(token, :T_NUMBER)
      token = next_token
      unexpected_token(token, :T_SEMICOLON) unless check_token(token, :T_SEMICOLON)

      # 初期値を更新
      default_value = token[:value].to_i
    end

    # 初期値, 配列次元数
    h = {default_value: default_value, dimention: dimention, element_size: element_size}
  end

  # 関数定義
  def parse_func_define token
    AppLoger.call_in

    # 関数宣言部 - (引数リスト)の解析
    func_def_info = parse_func_define_head(token)

    token = next_token
    func_body_info = parse_func_define_body token
    func_def_info[:func_body_info] = func_body_info
    func_def_info
  end

  # 関数宣言部解析 引数のかっこ以降の解析を行う
  def parse_func_define_head token
    AppLoger.call_in

    f_def_info = {}
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

    unexpected_token(token, :T_OPEN_BRACE) unless check_token(token, :T_OPEN_BRACE)

    # 対応チェック用スタックにpush
    stack_tmp.push(token)

    # ローカル変数の宣言チェック
    # TODO ローカル変数の情報を更新
    token = next_token
    local_vars = []
    parse_local_variables_declare(token, local_vars)

    # 関数本体の'{'に対応する'}'が見つかるまで解析を行う
    token = cur_token
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
          parse_error "#{@filepath}:#{token[:lineno]}, unexpected '}' found."
        end
      end

      # 関数内処理(文)の解析
      ret = parse_stmt(token, local_vars)
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
        unexpected_token(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
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
      else
        # 変数宣言終了 → 処理の解析へ
        break
      end
    end
    AppLoger.call_out

    true
  end

  # 文の解析
  def parse_stmt token, local_vars
    AppLoger.call_in
    until token[:sym] == :T_SEMICOLON
      puts "token:#{token}"
      case token[:sym]
      when :T_IDENTIFER
        name = token[:value]
        token = next_token
        if check_token(token, :T_EQUAL)
          # 式
          token = next_token
          exp(token)
        elsif check_token(token, :T_OPEN_PAREN)
          funcs = @function_list.select{|function| function[:name] == name}
          if funcs.empty?
            parse_error  "#{@filepath}:#{token[:lineno]}, function '#{name}' is not defined."
          end

          token = next_token
          ast = parse_func_call(token, funcs, local_vars)
          puts "ast:{ast}"
          token = next_token
        else
          parse_error "#{@filepath}:#{token[:lineno]} unexpected token sym:'#{token[:sym]}', token:'#{token[:value]}'."
        end
      when :T_KW_RETURN
        token = next_token
        exp(token)
        token = cur_token
      else
        parse_error "#{@filepath}:#{token[:lineno]} unexpected token sym:'#{token[:sym]}', token:'#{token[:value]}'."
      end
    end
    AppLoger.call_out
  end

  # 代入文の解析
  def parse_assign token
    AppLoger.call_in
  end

  def parse_func_call token, func_list, local_vars
    AppLoger.call_in

    ast_args = []
    until check_token(token, :T_CLOSE_PAREN)
      ast_args << exp(token)
      if check_token(token, :T_IDENTIFER)
        if local_vars.index{|var| var[:sym] == token[:sym]}
          # check local variables
          token = next_token
          break if check_token(token, :T_CLOSE_PAREN)
          if check_token(token, :T_COMMA)
            token = next_token
            next
          end
        elsif @global_vars.index{|var| var[:sym] == token[:sym]}
          # check global variables
          token = next_token
          break if check_token(token, :T_CLOSE_PAREN)
          if check_token(token, :T_COMMA)
            token = next_token
            next
          end
        else
          # データ型がない
          parse_error "#{@filepath}:#{token[:lineno]} undefined variable '#{token[:sym]}', token:'#{token[:value]}' used for function call."
        end
      elsif check_token(token, :T_INTEGER)
        data_type = func_info[:args][arg_num - 1][:data_type]
        if data_type != :T_KW_INT
          parse_error "#{@filepath}:#{token[:lineno]} arg #{arg_num -1 } type for function '#{func_info[:name]}' is '#{data_type}'"
        end
        token = next_token
        break if check_token(token, :T_CLOSE_PAREN)
        if check_token(token, :T_COMMA)
          token = next_token
          next
        end
      else
        parse_error "#{@filepath}:#{token[:lineno]} unexpected token '#{token[:sym]}' found."
      end
    end
  end

  def exp token
    AppLoger.call_in
    ast_left = term(token)
    token = next_token

    ast = nil
    case token[:sym]
    when :T_PLUS, :T_MINUS
      ast_right = term(token)
      ast_exp = ASTExp.new(token[:sym], ast_left, ast_right)
    else
      unexpected_token token
    end
    AppLoger.call_out
    ast_exp
  end

  def term token
    AppLoger.call_in

    ast_factor = factor(token)
    token = next_token

    ast_ret = nil
    case token[:sym]
    when :T_ASTER, :T_SLASH
      ast_right = term_2(token)
      unless ast_right.nil?
        ast_ret = ASTBinary.new(token[:sym], ast_factor, ast_right)
      else
        ast_ret = ast_factor
      end
    end

    AppLoger.call_out
    ast_ret
  end

  def term_2 token
    ast_term = nil
    until token[:sym] == :T_ASTER || token[:sym] == :T_SLASH
      token = next_token
      ast_term = term(token)
    end
    ast_term
  end

  def factor token
    unexpected_token(:T_INTEGER) unless check_token(token, :T_INTEGER)
    ASTInteger.new(token)
  end

 def cur_token
   @tokens[@token_pos]
 end

  def next_token
    # トークン位置チェック
    return nil if (@tokens.length - 1) < (@token_pos + 1)

    @token_pos += 1
    @tokens[@token_pos]
  end

  def back_token_pos
    @token_pos -= 1
  end

  def check_token token, token_type
    token[:sym] == token_type
  end

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

    args_info = []
    ret = check_token(token, :T_OPEN_PAREN)
    unexpected_token(token, :T_OPEN_PAREN) unless ret

    token = next_token
    arg_info = {}
    until check_token(token, :T_CLOSE_PAREN) == true
      ret = check_data_type(token, arg_info)
      if ret == false
        # データ型がない
        parse_error "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not Data type."
      end

      # 変数名取得
      token = next_token
      unexpected_token(token, :T_IDENTIFER) unless check_token(token, :T_IDENTIFER)
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
        parse_error "#{@filepath}:#{token[:lineno]} '#{token[:sym]}', token:'#{token[:value]}' is not expected."
      end
    end

    AppLoger.call_out
    args_info
  end

  # 配列型のチェック
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

    data_type_matched
  end

  def parse_error msg
  	 raise RccException.new("PARSE_ERROR", msg)
  end

  def unexpected_token token, expect = nil
    msg = "#{@filepath}:#{token[:lineno]} Unexpected token found, "
    msg += "expected token is #{expect}." if expect
    msg += "Received token is '#{token[:value]}', type:'#{token[:sym]}'."
  	parse_error msg
  end
end
