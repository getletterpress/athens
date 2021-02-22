module Athens
  class Configuration
    attr_accessor :aws_access_key,
                  :aws_secret_key,
                  :aws_region,
                  :output_location,
                  :wait_polling_period

    def initialize
      @aws_access_key = nil
      @aws_secret_key = nil
      @aws_region = nil
      @output_location = nil
      @wait_polling_period = 0.25
    end
  end
end
