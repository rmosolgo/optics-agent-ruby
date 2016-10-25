require 'apollo/optics/proto/reports_pb'
require 'optics-agent/reporting/helpers'
require 'optics-agent/normalization/latency'
require 'optics-agent/normalization/query'

module OpticsAgent::Reporting
  # This is a convenience class that enables us to fairly blindly
  # pass in data as we resolve a query
  class Query
    include Apollo::Optics::Proto
    include OpticsAgent::Reporting
    include OpticsAgent::Normalization
    include OpticsAgent::Normalization::Query

    attr_accessor :document

    def initialize
      @reports = []

      @document = nil
      @signature
    end

    def signature
      # Note this isn't actually possible but would be a sensible spot to throw
      # if the user forgets to call `.with_document`
      unless @document
        throw "You must call .with_document on the optics context"
      end

      @signature ||= normalize(document.to_s)
    end

    # we do nothing when reporting to minimize impact
    def report_field(type_name, field_name, start_time, end_time)
      @reports << [type_name, field_name, start_time, end_time]
    end

    def each_report
      @reports.each do |report|
        yield *report
      end
    end

    # add our results to an existing StatsPerSignature
    def add_to_stats(stats_per_signature)
      each_report do |type_name, field_name, start_time, end_time|
        type_stat = stats_per_signature.per_type.find { |ts| ts.name == type_name }
        unless type_stat
          type_stat = TypeStat.new({ name: type_name })
          stats_per_signature.per_type << type_stat
        end

        field_stat = type_stat.field.find { |fs| fs.name == field_name }
        unless field_stat
          field_stat = FieldStat.new({
            name: field_name,
            latency_count: empty_latency_count
          })
          type_stat.field << field_stat
        end

        add_latency(field_stat.latency_count, start_time, end_time)
      end
    end
  end
end
