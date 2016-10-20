require 'optics-agent/agent'
require 'optics-agent/reporting/query'

module OpticsAgent
  class RackMiddleware
    def initialize(app, options={})
      @app = app
    end

    def call(env)
      begin
        start_time = Time.now

        # XXX: figure out a way to pass this in here
        agent = OpticsAgent::Agent.instance
        query = OpticsAgent::Reporting::Query.new

        # Attach so resolver middleware can access
        env[:optics_agent] = {
          agent: agent,
          query: query
        }
        env[:optics_agent].define_singleton_method(:with_document) do |document|
          self[:query].document = document
          self
        end

        result = @app.call(env)

        # XXX: this approach means if the user forgets to call with_document
        # we just never log queries. Can we detect if the request is a graphql one?
        puts "middleware request finished, has document: #{query.document}"
        if (query.document)
          puts "middleware attaching query to agent"
          p agent
          agent.add_query(query, env, start_time, Time.now)
        end

        result
      rescue Exception => e
        puts "Rack Middleware Error: #{e}"
        puts e.backtrace
      end
    end
  end
end
