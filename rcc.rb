require 'strscan'

class Rcc

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

  def scan_line line
    s = StringScanner.new line
    while !s.eos?
      # スペース,タブはスキップ(無視)
      s.scan(/[\s\t]+/)
      @token_rules.each do |rule|
        c = s.scan(rule[:reg])
        push_token(rule[:sym], c) unless c.nil?
      end
    end
    puts @tokens
  end

  def push_token symbol, value
    @tokens << {sym: symbol, value: value}
  end

  def parse_tokens
    result = assign(@tokens[0])
    puts result
  end

  def assign token
    if token[:sym] == :T_IDENTIFER
      t = next_token
      if t[:sym] == :T_EQUAL
        t = next_token
        val = exp(t)
      end
    end
    # TODO 記号表を更新
    val
  end

  # number + number + ...
  def exp token
    val = term(token)
  end

  def term(token)
    val = 0
    status = :STATUS_ADD
    until token.nil?
      puts "token:#{token}, status:#{status}"
      if token[:sym] == :T_NUMBER
        tmp = token[:value].to_i
        case status
        when :STATUS_ADD
          val += tmp
        when :STATUS_DEL
          val -= tmp
        else
          # TODO 異常系
          puts status
          puts "Error Status"
        end
        status = :STATUS_WAIT_OPERATOR
      elsif token[:sym] == :T_ADD
        status = :STATUS_ADD if status == :STATUS_WAIT_OPERATOR
      elsif token[:sym] == :T_DEL
        status = :STATUS_DEL if status == :STATUS_WAIT_OPERATOR
      else
        # TODO
        puts "Error Not Number"
      end
      puts "next..."
      token = next_token
    end
    val
  end

  def next_token
    @pos += 1
    @tokens[@pos]
  end
end

line = "a = 1 + 2 + 3 - 10"
parser = Rcc.new
parser.scan_line line
parser.parse_tokens
