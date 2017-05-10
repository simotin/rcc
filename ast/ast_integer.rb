require './ast_base'

class ASTInteger < ASTBase
  def initialize token
    @token = token
  end

  def get
    @token[:value].token
  end

end
