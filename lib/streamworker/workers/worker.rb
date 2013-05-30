module Streamworker
  module Workers
    class Worker
      include Enumerable

      QUERIES_PER_BLOCK = 500
      TIME_PER_BLOCK = 300

      TIMEOUT_MARGIN = 5
      attr_accessor :view_context, :opts
      attr_accessor :repeats
      attr_accessor :line_num # subclasses responsible for setting this as appropriate
      attr_accessor :title
      attr_accessor :num_records, :num_success, :num_errors

      def initialize(view_context, opts={})
        @opts = opts.with_indifferent_access
        @view_context = view_context

        @title = "Working..."
        @repeats = opts[:repeats] || 1
        @repeats = @repeats.to_i
        @fragment = false
        @started_at = Time.now
        @opts[:unicorn_timeout] ||= 30
        @opts[:unicorn_timeout] = @opts[:unicorn_timeout].to_i
        @num_records = opts[:num_records].to_i || 1
        @num_success = 0
        @num_errors = 0
      end


      def queries_per_record
        1
      end

      def projected_queries
        (self.num_records * self.queries_per_record).to_f
      end

      def num_queries
        (self.num_success + self.num_errors) .to_f * self.queries_per_record
      end

      def calculate_times
        actual_time_used = Time.now - @started_at
        work_time_remaining = opts[:unicorn_timeout] - actual_time_used
        theoretical_total_time = (projected_queries / QUERIES_PER_BLOCK) * TIME_PER_BLOCK
        theoretical_time_used = (num_queries / QUERIES_PER_BLOCK) * TIME_PER_BLOCK
        factor = actual_time_used.to_f / theoretical_time_used
        factor = [factor, 1].max if projected_queries > QUERIES_PER_BLOCK
        total_time = theoretical_total_time * factor

        # puts "--------- calculate_times ---------"
        # puts "Time.now: #{Time.now.inspect}"
        # puts "@started_at: #{@started_at.inspect}"
        # puts "QUERIES_PER_BLOCK: #{QUERIES_PER_BLOCK.inspect}"
        # puts "TIME_PER_BLOCK: #{TIME_PER_BLOCK.inspect}"
        # puts "(self.num_records * self.queries_per_record): #{(self.num_records * self.queries_per_record).inspect}"
        # puts "opts[:unicorn_timeout] : #{opts[:unicorn_timeout] .inspect}"
        # puts "actual_time_used: #{actual_time_used.inspect}"
        # puts "work_time_remaining: #{work_time_remaining.inspect}"
        # puts "theoretical_total_time: #{theoretical_total_time.inspect}"
        # puts "theoretical_time_used: #{theoretical_time_used.inspect}"
        # puts "factor: #{factor.inspect}"
        # puts "total_time: #{total_time.inspect}"
        # puts "(total_time - actual_time_used): #{(total_time - actual_time_used).inspect}"
        # puts
        {
          work_time: opts[:unicorn_timeout] .to_i,
          work_time_remaining: work_time_remaining,
          time_used: actual_time_used,
          time_remaining: (total_time - actual_time_used),
          total_time: total_time
        }
      end

      def imminent_timeout?
        # puts "--------- imminent_timeout ---------"
        # puts "work_time_remaining: #{calculate_times[:work_time_remaining].inspect}"
        # puts "TIMEOUT_MARGIN: #{TIMEOUT_MARGIN.inspect}"
        calculate_times[:work_time_remaining] < TIMEOUT_MARGIN
      end

      def report_timeout_footer(msg={})
        msg[:work_desc] ||= "#{num_success} records"
        msg[:how_to_finish] ||= "resubmit the last #{num_records - num_success} records."
        times = calculate_times
        %Q{ 
          </div>
          <hr/>
          <div class="alert alert-error alert_block span8">
            
            <h4><i class="icon-time icon-large pull-left"></i>Server Timeout!</h4>
            <br/>
              Unfortunately, the backend processing time is limited to #{times[:work_time]} seconds, so we have to stop processing this job after #{msg[:work_desc]}.
            
            <br/><br/>
              To finish processing, please #{msg[:how_to_finish]}.
            
          </div>
          #{scroll}
        </div>#{self.foot}
        }
      end

      def set_headers(response)
        response.headers['Last-Modified'] = Time.now.ctime.to_s
        response.headers.delete('Content-Length')
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['Transfer-Encoding'] = 'chunked'
      end

      def header
        repeats =  ""
        repeats = %Q{<p class="muted">Repeating #{@repeats} times</p>} if @repeats > 1 

        header = <<-EOHTML
        #{self.head}<div class="container">
            #{repeats}
            <div class="import-results">
        EOHTML
        # Safari waits until it gets the first 1024 bytes to start displaying
        Rails.logger.debug header

        header + (" " * [0, (1025 - header.length)].max) 
      end

      def head(scroll=true)
        scroll = scroll ? "" : %Q{ style="overflow: hidden;"}
        %Q{
    <!DOCTYPE html>
    <html class="white"#{scroll}>
      <head>
        #{view_context.stylesheet_link_tag('application')}
        #{view_context.javascript_include_tag('application')}
        #{view_context.javascript_include_tag('scroller')}
        <title>#{self.title}</title>
      </head>
      <body class="stream-worker-results">      
        }
      end

      def footer(msg)
        <<-EOHTML
          </div>
          <h3>#{msg}</h3>
          #{scroll}

        </div>#{self.foot}
        EOHTML
      end

      def foot
        %Q{
      </body>
    </html>
      }
      end

      def scroll
        %Q{<script type="text/javascript">
              scrollBottom();
              parent.update_stream_worker_progress(#{num_records}, #{num_success}, #{num_errors});
            </script>
        }
      end

      def open_report_line(str)
        report_line(str, close: false)
      end

      def fragment?
        @fragment
      end

      def report_fragment(str)
        fragment? ? str : open_report_line(str)
      end

      def close_report_line
        fragment? ? report_line("", close: true) : ""
      end

      def report_line(str, opts={})
        # Rails.logger.info("report_line str: #{str.inspect} opts: #{opts.inspect} fragment?: #{fragment?.inspect}")
        opts = {close: true}.merge(opts)
        p_class = ["report-line", opts[:class]].compact.join(" ")
        start = fragment? ?  "" : %Q{
            <p class="#{p_class}">}
        @fragment = ! opts[:close]
        close = ""
        if opts[:close]
          close = %Q{</p>
              #{scroll}
    } 
        end
        out = %Q{#{start}#{str}#{close}}
        # Rails.logger.info("    out: #{out.inspect}")
        out
      end


      def report_error(str, list=[])
        err = %Q{
            #{error_line_num}
            <div class="alert alert-error">
                <p class="text-error"><i class="icon-warning-sign icon-large"></i>#{str}</p>
              }
        err << %Q{<ul class="error-list">\n} unless list.empty?
        list.each { |e| err << %Q{              <li>#{e}</li>\n} }
        err << %Q{              </ul>\n} unless list.empty?
        err << %Q{           </div>}
        
        err
      end

      def success_line_num
        %Q{<span class="badge badge-success badge-line-num">#{line_num}</span>}
      end

      def error_line_num
        %Q{<span class="badge badge-important badge-line-num">#{line_num}</span>}
      end

      def each
        raise "Worker subclasses must implement each to yield their output"
      end

    end
  end
end