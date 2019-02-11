require 'bigdecimal'

module Athens
  class Connection
    attr_reader :database_name

    def initialize(database_name)
      @database_name = database_name
      @client = Aws::Athena::Client.new

      version = RUBY_VERSION.split('.').map {|v| v.to_i}
      @decimal_without_new = (version[0] >= 2 && version[1] >= 5)
    end

    def execute(query)
      resp = @client.start_query_execution(
        query_string: query,
        query_execution_context: context,
        result_configuration: result_config
      )


      result = nil

      while true
        result = @client.get_query_execution(query_execution_id: resp.query_execution_id)

        state = result.query_execution.status.state

        if state == 'SUCCEEDED'
          break
        elsif state == 'FAILED'
          raise QueryFailedError.new(result.query_execution.status.state_change_reason)
          break
        elsif state == 'CANCELLED'
          raise QueryCancelledError.new(result.query_execution.status.state_change_reason)
          break
        end

        # Wait a bit and check again
        sleep(0.25)
      end

      # If here it was successful, grab the results and return those

      query_result = @client.get_query_results({query_execution_id: result.query_execution.query_execution_id})

      return query_result
    end

    def execute_to_array(query, header_row:true)
      result = execute(query)

      metadata = result.result_set.result_set_metadata
      rows = result.result_set.rows

      array = []

      first_row = rows.shift

      if header_row
        array << first_row.data.map {|col| col.var_char_value}
      end

      rows.each do |row|
        array << map_types(metadata, row)
      end

      return array
    end

    def execute_to_hash(query)
      rows = execute_to_array(query, header_row: true)
      headers = rows.shift

      array = []
      rows.each do |row|
        map = {}
        headers.each_with_index do |header, index|
          map[header] = row[index]
        end
        array << map
      end

      return array
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

      def map_types(metadata, row)
        mapped = []

        metadata.column_info.each_with_index do |col, index|
          data = row.data[index].var_char_value

          case col.type
          when 'tinyint', 'smallint', 'int', 'integer', 'bigint'
            mapped << data.to_i
          when 'timestamp'
            mapped << Time.parse(data)
          when 'varchar'
            mapped << data
          when 'float', 'double'
            mapped << data.to_f
          when 'decimal'
            if @decimal_without_new
              mapped << BigDecimal(data)
            else
              mapped << BigDecimal.new(data)
            end
          when 'date'
            mapped << Date.parse(data)
          when 'boolean'
            mapped << (data == "true")
          else
            puts "WARNING: Unsupported type: #{col.type}, defaulting to string"
            mapped << data
          end
        end

        return mapped
      end    
  end
end
