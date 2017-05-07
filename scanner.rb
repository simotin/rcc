require 'strscan'
require './app_logger'

# =============================================================================
# 実装方針
#   - 各フェーズの独立性を高める
#   - 先に字句解析を行う
# =============================================================================
class Scanner
  def initialize filepath
    @filepath = filepath
    @pos = 0
    @tokens = []
    @@token_rules = [
      { sym: :T_EQUAL			    ,	reg: /\=/ },
      { sym: :T_ADD				    ,	reg: /\+/ },
      { sym: :T_DEL				    ,	reg: /\-/ },
      { sym: :T_ASTER			    ,	reg: /\*/ },
      { sym: :T_OPEN_PAREN		,	reg: /\(/ },
      { sym: :T_CLOSE_PAREN		,   reg: /\)/ },
      { sym: :T_OPEN_BRACE		,	reg: /{/ },
      { sym: :T_CLOSE_BRACE		,   reg: /}/ },
      { sym: :T_COMMA			    ,	reg: /,/ },
      { sym: :T_SEMICOLON		 ,	reg: /;/ },
      { sym: :T_NUMBER			 ,	reg: /[0-9]+/ }
    ]

	@@keywords = [
      { sym: :T_KW_VOID      	,	keyword: "void"      },
      { sym: :T_KW_CHAR      	,	keyword: "char"      },
      { sym: :T_KW_SHORT     	,	keyword: "short"     },
      { sym: :T_KW_INT       	,	keyword: "int"       },
      { sym: :T_KW_LONG      	,	keyword: "long"      },
      { sym: :T_KW_FLOAT     	,	keyword: "float"     },
      { sym: :T_KW_DOUBLE    	,	keyword: "double"    },
      { sym: :T_KW_AUTO      	,	keyword: "auto"      },
      { sym: :T_KW_STATIC    	,	keyword: "static"    },
      { sym: :T_KW_CONST     	,	keyword: "const"     },
      { sym: :T_KW_SIGNED    	,	keyword: "signed"    },
      { sym: :T_KW_UNSIGNED  	,	keyword: "unsigned"  },
      { sym: :T_KW_EXTERN    	,	keyword: "extern"    },
      { sym: :T_KW_VOLATILE  	,	keyword: "volatile"  },
      { sym: :T_KW_REGISTER  	,	keyword: "register"  },
      { sym: :T_KW_RETURN    	,	keyword: "return"    },
      { sym: :T_KW_GOTO      	,	keyword: "goto"      },
      { sym: :T_KW_IF        	,	keyword: "if"        },
      { sym: :T_KW_ELSE      	,	keyword: "else"      },
      { sym: :T_KW_SWITCH    	,	keyword: "switch"    },
      { sym: :T_KW_CASE      	,	keyword: "case"      },
      { sym: :T_KW_DEFAULT   	,	keyword: "default"   },
      { sym: :T_KW_BREAK     	,	keyword: "break"     },
      { sym: :T_KW_FOR       	,	keyword: "for"       },
      { sym: :T_KW_WHILE     	,	keyword: "while"     },
      { sym: :T_KW_DO        	,	keyword: "do"        },
      { sym: :T_KW_CONTINUE  	,	keyword: "continue"  },
      { sym: :T_KW_TYPEDEF   	,	keyword: "typedef"   },
      { sym: :T_KW_STRUCT    	,	keyword: "struct"    },
      { sym: :T_KW_ENUM      	,	keyword: "enum"      },
      { sym: :T_KW_UNION     	,	keyword: "union"     },
      { sym: :T_KW_SIZEOF    	,	keyword: "sizeof"    }
	]
  end

  # 字句解析
  def scan code
    s = StringScanner.new code
    c = ""

    # 解析行
    lineno = 1
    while !s.eos?
      # スペース,タブはスキップ(無視)
      c = s.scan(/[\t ]+/)

      # 改行コードは行番号をカウント
      c = s.scan(/\n|\r\n/)
      lineno += 1 unless c.nil?

      @@token_rules.each do |rule|
        c = s.scan(rule[:reg])
        unless c.nil?
          push_token(rule[:sym], c, lineno)
          break
        end
      end

      # 既に一致していれば次へ
      next unless c.nil?

      # キーワード・識別子判定
      c = s.scan(/[a-zA-Z_][a-zA-Z0-9_]*/)
      next if c.nil?

      keyword_matched = false
      @@keywords.each do |keyword|
      	if c == keyword[:keyword]
      	  # キーワードに一致
          keyword_matched = true
          push_token(keyword[:sym], c, lineno)
      	end
      end

	  # キーワードに一致しない→識別子として保持
    unless keyword_matched
      push_token(:T_IDENTIFER, c, lineno)
    end

    end

    @tokens
  end

  private
  def push_token symbol, value, lineno
    @tokens << {sym: symbol, value: value, lineno: lineno}
  end
end
