# Athens

Athens is a wrapper around the standard AWS athena sdk, with a much simpler interface for executing queries and processing results.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'athens'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install athens

## Usage

### Quickstart

There are two main classes for Athens, the `Connection` and the `Query`.  First "open" a connection to the database:

```ruby
conn = Athens::Connection.new(database: 'sample')
```

Then start a query:
```ruby
query = conn.execute("SELECT * FROM mytable")
```

That kicks off an Athena query in the background.  If you want you can just wait for it to finish:
```ruby
query.wait
# or
query.wait(5) # Wait 5 seconds at most
```

When your query is done, grab the results as an array:
```ruby
results = query.to_a
# [
#   ['column_1', 'column_2', 'column_3'],
#   [15, 'data', true],
#   [20, 'foo', false],
#   ...
# ]
```

Or as a hash (which is really an array where each row is a hash):
```ruby
results = query.to_h
# [
#   {'column_1': 15, 'column_2': 'data', 'column_3': true},
#   {'column_1': 20, 'column_2': 'foo', 'column_3': false},
#   ...
# ]
```

Results are also available as unbuffered enumerators of row arrays:
```ruby
query.rows.each {|row| ...}
# ['column_1', 'column_2', 'column_3']
# [15, 'data', true]
# [20, 'foo', false],
# ...
```

Or hashes:
```ruby
query.records.each {|record| ...}
# {'column_1': 15, 'column_2': 'data', 'column_3': true}
# {'column_1': 20, 'column_2': 'foo', 'column_3': false}
# ...
```

Athens attempts to parse the sql data types into their ruby equivalents, although there's currently no support for the more complex Array/Map types.

### Configuration

Configure your AWS settings in an `Athens.configure` block (in rails put this in `config/initializers/athens.rb`):

```ruby
Athens.configure do |config|
  config.output_location = "s3://my-bucket/my-folder/athena/results/"  # Required
  config.aws_access_key      = 'access'     # Optional
  config.aws_secret_key      = 'secret'     # Optional
  config.aws_region          = 'us-east-1'  # Optional
  config.wait_polling_period = 0.25         # Optional - What period should we poll for the complete query?
end
```

The aws parameters are all "optional", in that you can omit those in favor of any of the standard AWS configuration options (i.e. IAM Roles, environment variables, .aws/credentials files).

You can also override the AWS client configuration on a per-connection basis:

```ruby
conn = Athens::Connection.new(aws_client_override: {})
```

Take a look at the [AWS Athena SDK](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Athena/Client.html#initialize-instance_method) for a list of all the available options.

### Advanced Usage

Providing a database name to the connection is optional, if you omit the name you'll have to specify it in your query:

```ruby
conn = Athens::Connection.new(database 'sample')
query = conn.execute("SELECT * FROM mytable")

# or

conn = Athens::Connection.new
query = conn.execute("SELECT * FROM sample.mytable")
```

While waiting for a query to finish, you could get one of two exceptions:

```ruby
conn = Athens::Connection.new(database 'sample')
query = conn.execute("SELECT * FROM mytable")

begin
  query.wait()
rescue Athens::QueryFailedError => qfe
  # Query returned a failure message, qfe.message has details
rescue Athens::QueryCancelledError => qce
  # Query was canceled (usually by the user), qce.message has details
end
```

When a query is running you can do a few things:

```ruby
conn = Athens::Connection.new(database: 'sample')
query = conn.execute("SELECT * FROM mytable")

query.state  # Returns one of QUEUED, RUNNING, SUCCEEDED, FAILED, or CANCELLED (https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Athena/Types/QueryExecutionStatus.html#state-instance_method)
query.state_reason  # Further details from AWS about the state
query.query_execution_id  # The id of the query returned from AWS
query.cancel   # Attempts to cancel an in-progress query, returns true or false (if the query has already finished this will return false)

query.to_a(header_row: false)  # If you want your query results returned without a header row of column names
```

The execute method also optionally supports the `request_token` and `work_group` [parameters](https://docs.aws.amazon.com/athena/latest/APIReference/API_StartQueryExecution.html#API_StartQueryExecution_RequestSyntax):

```ruby
conn = Athens::Connection.new(database: 'sample')
query = conn.execute("SELECT * FROM mytable", request_token: single_use_token, work_group: my_work_group)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

If you want you can use Vagrant instead, there's already a `Vagrantfile` so a simple `vagrant up` should get you setup.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/getletterpress/athens. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [WTFPL License](http://www.wtfpl.net/).

## Code of Conduct

Everyone interacting in the Athens project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/getletterpress/athens/blob/master/CODE_OF_CONDUCT.md).
g
