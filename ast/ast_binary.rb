require './ast_base'

class ASTBinary < ASTBase
  def initialize sym, left_node, right_node
    @sym = sym
    @left_node = left_node
    @right_node = right_node
  end

  def eval
    result = nil
    case @sym
    when :T_ASTER
      @left_node.eval * @right_node.eval
    when :T_SLASH
      @left_node.eval / @right_node.eval
    when :T_PLUS
      @left_node.eval / @right_node.eval
    when :T_MINUS
      @left_node.eval / @right_node.eval
    else
      raise RccException.new("EVAL_ERROR", "Unexpected Symbol #{@sym}")
    end
  end

end
