$LOAD_PATH.push('./ast')
require 'ast_base'

class ASTVar < ASTBase
  def initialize val
    @val = val
  end

  def eval
    @val
  end
end
