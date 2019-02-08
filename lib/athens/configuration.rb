module Athens
  class Configuration
    attr_accessor :aws_access_key, 
                  :aws_secret_key, 
                  :database_name,
                  :output_location

    def initialize
      @aws_access_key = nil
      @aws_secret_key = nil
      @database_name = nil
      @output_location = nil
    end
  end
end