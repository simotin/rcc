require './app_logger'

class Preprocessor

  # プリプロセス処理
  def execute code
    # コメントアウト
    code = comment_out(code)
  end

  private

  # // , /* ... */ コメントのコメントアウト
  def comment_out code
    # // コメント行を除去
    code = code.gsub(/\/\/.*/,"")
    code = delete_comment_out(code)
  end

  def delete_comment_out code
    status = :STATUS_WAIT_START_SLASH
    tmp = ""
    comment_out_code = ""
    code.each_char do |c|
      case status
      when :STATUS_WAIT_START_SLASH
        if (c == '/')
          tmp = c
          status = :STATUS_WAIT_START_ASTR
        else
          comment_out_code << c
        end
      when :STATUS_WAIT_START_ASTR
        if (c == '*')
          status = :STATUS_WAIT_END_ASTR
        else
          status = :STATUS_WAIT_START_SLASH
          comment_out_code << tmp
          comment_out_code << c
        end
      when :STATUS_WAIT_END_ASTR
        if (c == '*')
          status = :STATUS_WAIT_END_SLASH
        end
      when :STATUS_WAIT_END_SLASH
        if (c == '/')
          status = :STATUS_WAIT_START_SLASH
        end
      end
    end
    if status != :STATUS_WAIT_START_SLASH
      puts "status error"
    end
    comment_out_code
  end

  def push_token symbol, value
    @tokens << {sym: symbol, value: value}
  end
end
