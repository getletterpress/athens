require "athens/error"
require "athens/version"
require "athens/configuration"
require "athens/connection"
require "athens/query"

require 'aws-sdk-athena'
require 'oj'

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
