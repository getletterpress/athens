require 'bigdecimal'

module Athens
  class Connection
    attr_reader :database_name
    attr_reader :client

    def initialize(database_name)
      @database_name = database_name
      @client = Aws::Athena::Client.new
    end

    # Runs a query against Athena, returning an Athens::Query object
    # that you can use to wait for it to finish or get the results
    def execute(query)
      resp = @client.start_query_execution(
        query_string: query,
        query_execution_context: context,
        result_configuration: result_config
      )

      return Athens::Query.new(self, resp.query_execution_id)
    end

    private

      def context 
        Aws::Athena::Types::QueryExecutionContext.new(database: @database_name)
      end

      def result_config
        Aws::Athena::Types::ResultConfiguration.new(
          output_location: Athens.configuration.output_location,
          encryption_configuration: {
            encryption_option: "SSE_S3"
          }
        )
      end

  end
end
