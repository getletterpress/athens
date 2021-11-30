module Athens
  class Query
    attr_reader :query_execution_id

    def initialize(connection, query_execution_id)
      @connection = connection
      @query_execution_id = query_execution_id
      @state = nil
      @state_reason = nil
      @cancelled = false

      @results = nil
      @hash_results = nil

      version = RUBY_VERSION.split('.').map {|v| v.to_i}
      @decimal_without_new = (version[0] >= 2 && version[1] >= 5)
      @decimal_without_new = (version[0] == 2 && version[1] >= 5) || (version[0] >= 3)
    end

    def state
      refresh_state if state_needs_refresh?
      @state
    end

    def state_reason
      refresh_state if state_needs_refresh?
      @state_reason
    end

    def wait(max_seconds = nil)
      if max_seconds.nil?
        stop_at = nil
      else
        stop_at = Time.now + max_seconds
      end

      while true
        if stop_at != nil && Time.now > stop_at
          return false
        end

        refresh_state

        if @state == 'SUCCEEDED'
          return true
        elsif @state == 'FAILED'
          raise QueryFailedError.new(@state_reason)
        elsif state == 'CANCELLED'
          raise QueryCancelledError.new(@state_reason)
        end

        # Wait a bit and check again
        sleep(Athens.configuration.wait_polling_period.to_f)
      end
    end

    def cancel
      unless @cancelled
        resp = @connection.client.stop_query_execution({
          query_execution_id: @query_execution_id
        })
        @cancelled = true
        refresh_state
      end

      if @state == 'CANCELLED'
        return true
      else
        return false
      end
    end

    def rows
      raise InvalidRequestError.new("Query must be in SUCCEEDED state to return results") unless @state == 'SUCCEEDED'

      Enumerator.new do |y|
        result = @connection.client.get_query_results({query_execution_id: @query_execution_id})

        metadata = result.result_set.result_set_metadata
        first = true

        while true
          rows = result.result_set.rows
          break if rows.empty?

          if first
            y << rows.shift.data.map {|col| col.var_char_value}
            first = false
          end

          rows.each {|row| y << map_types(metadata, row)}

          break unless result.next_token

          result = @connection.client.get_query_results({
            query_execution_id: @query_execution_id,
            next_token: result.next_token
          })
        end
      end
    end

    def records
      Enumerator.new do |y|
        headers = nil

        rows.each_with_index do |row|
          if headers.nil?
            headers = row
            next
          end

          y << Hash[headers.zip(row)]
        end
      end
    end

    def to_a(header_row: true)
      (@results ||= rows.to_a).drop(header_row ? 0 : 1)
    end

    def to_h
      @hash_results ||= records.to_a
    end

    private
      def state_needs_refresh?
        @state.nil? || (['QUEUED', 'RUNNING'].include?(@state))
      end

      def refresh_state
        resp = @connection.client.get_query_execution({query_execution_id: @query_execution_id})

        @state = resp.query_execution.status.state
        @state_reason = resp.query_execution.status.state_change_reason
      end

      def map_types(metadata, row)
        mapped = []

        metadata.column_info.each_with_index do |col, index|
          data = row.data[index].var_char_value
          nullable = ["UNKNOWN", "NULLABLE"].include?(col.nullable)

          if nullable && data.nil?
            mapped << data
          elsif !nullable && data.nil?
            raise InvalidNullError.new("Got null data from a non-null field (#{col.name})")
          else
            case col.type
            when 'tinyint', 'smallint', 'int', 'integer', 'bigint'
              mapped << data.to_i
            when 'timestamp'
              mapped << Time.parse(data)
            when 'varchar', 'string'
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
            when 'json'
              mapped << Oj.load(data, symbol_keys: true)
            else
              puts "WARNING: Unsupported type: #{col.type}, defaulting to string"
              mapped << data
            end
          end
        end

        return mapped
      end


  end
end
