module Athens
  class Error < StandardError; end

  class QueryFailedError < Error; end
  class QueryCancelledError < Error; end

end