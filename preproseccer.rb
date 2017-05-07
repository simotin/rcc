require './app_logger'

class Preprocessor

  # プリプロセス処理
  def execute code
    # // コメント行を除去
    code.gsub(/\/\/.*/,"")
  end

  private
  def push_token symbol, value
    @tokens << {sym: symbol, value: value}
  end
end
