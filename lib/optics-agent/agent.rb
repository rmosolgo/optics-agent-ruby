require 'singleton'
require 'optics-agent/rack-middleware'
require 'optics-agent/graphql-middleware'
require 'optics-agent/reporting/report_job'
require 'optics-agent/reporting/schema_job'
require 'optics-agent/reporting/query-trace'

module OpticsAgent
  # XXX: this is a class but acts as a singleton right now.
  # Need to figure out how to pass the agent into the middleware
  #   (for instance we could dynamically generate a middleware class,
  #    or ask the user to pass the agent as an option) to avoid it
  class Agent
    include Singleton
    include OpticsAgent::Reporting

    attr_reader :schema

    def initialize
      @query_queue = []
      @semaphone = Mutex.new
      ReportJob.perform_in(60, self)
    end

    def instrument_schema(schema)
      @schema = schema
      schema.middleware << graphql_middleware

      puts 'scheduling schema job'
      SchemaJob.perform_in(10, self)
    end

    def add_query(query, rack_env, start_time, end_time)
      puts "adding query to queue"
      @semaphone.synchronize {
        @query_queue << [query, rack_env, start_time, end_time]
      }
      puts "query_queue length is #{@query_queue.length}"
    end

    def clear_query_queue
      puts "clearing query_queue"
      puts "query_queue length is #{@query_queue.length}"
      @semaphone.synchronize {
        queue = @query_queue
        @query_queue = []
        queue
      }
    end

    def rack_middleware
      OpticsAgent::RackMiddleware
    end

    def graphql_middleware
      # graphql middleware doesn't seem to need the agent but certainly could have it
      OpticsAgent::GraphqlMiddleware.new
    end
  end
end
