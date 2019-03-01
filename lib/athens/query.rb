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
        sleep(0.25)
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

    def to_a(header_row: true)
      raise InvalidRequestError.new("Query must be in SUCCEEDED state to return results") unless @state == 'SUCCEEDED'

      if @results.nil?
        # Need to load and map all of the rows from the original result
        @results = []
        result = @connection.client.get_query_results({query_execution_id: @query_execution_id})

        metadata = result.result_set.result_set_metadata
        first = true

        while true
          rows = result.result_set.rows
          break if rows.empty?

          if first
            @results << rows.shift.data.map {|col| col.var_char_value}
            first = false
          end

          rows.each do |row|
            @results << map_types(metadata, row)
          end

          if result.next_token
            result = @connection.client.get_query_results({
              query_execution_id: @query_execution_id,
              next_token: result.next_token
            })
          else
            # No more rows, break out and return our mapped data
            break
          end
        end
      end

      if header_row
        return @results
      else
        return @results[1, @results.size]
      end
    end

    def to_h
      if @hash_results.nil?
        all_rows = self.to_a(header_row: true)

        headers = all_rows.shift

        @hash_results = []

        unless headers.nil?
          all_rows.each do |row|
            map = {}
            headers.each_with_index do |header, index|
              map[header] = row[index]
            end
            @hash_results << map
          end
        end
      end

      return @hash_results
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

