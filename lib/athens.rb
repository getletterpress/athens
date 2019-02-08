require "athens/error"
require "athens/version"
require "athens/configuration"
require "athens/query"

require 'aws-sdk-athena'

module Athens
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
