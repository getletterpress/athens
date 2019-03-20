module Athens
  class Error < StandardError; end

  class QueryFailedError < Error; end
  class QueryCancelledError < Error; end
  class InvalidRequestError < Error; end
  class InvalidNullError < Error; end

end