class RccException < StandardError
  def initialize error_type, msg
    message = "[#{error_type}] #{msg}"
    super(message)
  end
end
