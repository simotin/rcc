$LOAD_PATH.push('./ast')
require 'ast_base'

class ASTFuncCall < ASTBase
  def initialize name, args = nil
      @name = name
      @args = args
  end
end
