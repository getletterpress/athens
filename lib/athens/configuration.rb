module Athens
  class Configuration
    attr_accessor :aws_access_key, 
                  :aws_secret_key, 
                  :output_location

    def initialize
      @aws_access_key = nil
      @aws_secret_key = nil
      @output_location = nil
    end
  end
end