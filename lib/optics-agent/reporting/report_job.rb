require 'sucker_punch'
require 'optics-agent/reporting/report'

module OpticsAgent::Reporting
  class ReportJob
    include SuckerPunch::Job

    def perform(agent)
      report = OpticsAgent::Reporting::Report.new
      items = agent.clear_query_queue
      puts "reporting: queue length is #{items.length}"
      p agent
      items.each do |item|
        report.add_query(*item)

        # XXX: don't send *every* trace
        query_trace = QueryTrace.new(*item)
        query_trace.send
      end

      report.decorate_from_schema(agent.schema)
      report.send

      self.class.perform_in(60, agent)
    end
  end
end
