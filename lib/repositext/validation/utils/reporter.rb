class Repositext
  class Validation

    # A Reporter collects data during validation and once the validation is
    # complete, it generates a report from that data. I can then group and
    # summarize the data.
    #
    # Minitest has a pretty good reporter that I can model this after.
    # https://github.com/seattlerb/minitest/blob/master/lib/minitest.rb#L371
    # cool reporter for Test::Unit https://github.com/TwP/turn
    class Reporter

      attr_reader :errors, :warnings, :stats

      # @param _input_base_dir [String]
      # @param _file_selector [String]
      # @param _file_extension [String]
      # @param logger [Logger]
      # @param options [Hash, optional]
      # @option options [Boolean] verbose, default: false
      def initialize(_input_base_dir, _file_selector, _file_extension, logger, options={})
        @file_extension = _file_extension
        @file_selector = _file_selector
        @input_base_dir = _input_base_dir
        @logger = logger
        @options = options

        @errors = []
        @warnings = []
        @stats = []
      end

      # Use this method to add an error to self.
      # @param [Reportable] _reportable
      def add_error(_reportable)
        @errors << _reportable
        @logger.error(
          _reportable.log_to_console.gsub(@input_base_dir, '')
        )
      end

      # Use this method to add an array of errors to self.
      # @param [Array<Reportable>] _errors
      def add_errors(_errors)
        # Sort errors by location
        _errors.sort { |a,b|
          a_attrs = [a.location[:filename], a.location[:line]].compact
          b_attrs = [b.location[:filename], b.location[:line]].compact
          a_attrs <=> b_attrs
        }.each do |e|
          self.add_error(e)
        end
      end

      # Use this method to add a stat to self
      # @param [Reportable] _stat
      def add_stat(_stat)
        @stats << _stat
      end

      # Use this method to add an array of stats to self
      # @param _stats [Array<Reportable>]
      def add_stats(_stats)
        _stats.each do |e|
          self.add_stat(e)
        end
      end

      # Use this method to add a warning to self.
      # @param [Reportable] _reportable
      def add_warning(_reportable)
        @warnings << _reportable
        @logger.warning(
          _reportable.log_to_console.gsub(@input_base_dir, '')
        )
      end

      # Use this method to add an array of warnings to self.
      # @param [Array<Reportable>] _warnings
      def add_warnings(_warnings)
        _warnings.sort { |a,b|
          a_attrs = [a.location[:filename], a.location[:line]].compact
          b_attrs = [b.location[:filename], b.location[:line]].compact
          a_attrs <=> b_attrs
        }.each do |e|
          self.add_warning(e)
        end
      end

      # Returns report data
      # @param [Hash, optional] options
      #   * :grouped_by => :location (default), :class
      # @return [Hash<Array>] recursive Hash with Arrays for collections and
      #   Hashes for objects. Structure depends on :grouped_by option.
      def reportables(options = {})
        options = { :grouped_by => :location }.merge(options)
        r = case options[:grouped_by]
        when :location
          group_reportables_by_location
        when :class
          group_reportables_by_class
        else
          raise(ArgumentError.new("Invalid :grouped_by: #{ options[:grouped_by].inspect }"))
        end
        r
      end

      # Groups data by location
      # 'AFR65-0102.idml' => {
      #   :errors => [],
      #   '/path/to-file' => {
      #     'line 42' => {
      #       :errors => [
      #         {
      #           :location => {
      #             filename: '/path/to-file',
      #             line: 42,
      #             context: '...some context...,
      #           },
      #           :details => ['InvalidUnicodeCharacter', 'U+2029', '<further optional details>'],
      #           :level => :error
      #         },
      #       ],
      #       :warnings => []
      #     }
      #   }
      # }
      def group_reportables_by_location
        @group_reportables_by_location ||= (
          r = RecursiveDataHash.new
          @errors.each do |error|
            filename_hash = r[error.location[:filename]]
            line_hash = filename_hash["line #{ error.location[:line] || 'N/A' }"]
            line_hash[:errors] << {
              :location => error.location,
              :details => error.details,
              :level => error.level
            }
          end
          @warnings.each do |warning|
            filename_hash = r[warning.location[:filename]]
            line_hash = filename_hash["line #{ warning.location[:line] || 'N/A' }"]
            line_hash[:warnings] << {
              :location => warning.location,
              :details => warning.details,
              :level => warning.level
            }
          end
          @stats.each do |stat|
            filename_hash = r[stat.location[:filename]]
            filename_hash[:stats] << {
              :location => stat.location,
              :details => stat.details,
              :level => stat.level
            }
          end
          r
        )
      end

      # Groups data by class
      # {
      #   'InvalidUnicodeCharacter' => {
      #     'U+2029' => {
      #       :errors => [
      #         {
      #           :location => ['AFR65-0102.idml', 'story u1998', 'line 1776'],
      #           :details => ['InvalidUnicodeCharacter', 'U+2029', 'optional'],
      #           :level => :error
      #         },
      #       ],
      #       :warnings => [
      #       ]
      #     }
      #   }
      # }
      def group_reportables_by_class
        @group_reportables_by_class ||= (
          r = RecursiveDataHash.new
          # iterate over all errors to build intermediate structure
          @errors.each do |error|
            sub = r
            error.details.first(2).each{ |el| sub = sub[el] }
            sub[:errors] << {
              :location => error.location,
              :details => error.details,
              :level => error.level
            }
          end
          @warnings.each do |warning|
            sub = r
            warning.details.first(2).each{ |el| sub = sub[el] }
            sub[:warnings] << {
              :location => warning.location,
              :details => warning.details,
              :level => warning.level
            }
          end
          @stats.each do |stat|
            sub = r[stat.details.first]
            sub[:stats] << {
              :location => stat.location,
              :details => stat.details,
              :level => stat.level
            }
          end
          r
        )
      end

      # Returns an array with all reportables, sorted by class
      def sort_reportables_by_class
        r = { errors: [], warnings: [], stats: [] }
        @errors.each do |error|
          r[:errors] << {
            :details => error.details,
            :location => error.location.compact.map { |e| e.gsub(@input_base_dir, '') },
          }
        end
        @warnings.each do |warning|
          r[:warnings] << {
            :details => warning.details,
            :location => warning.location.map { |e| e.gsub(@input_base_dir, '') },
          }
        end
        @stats.each do |stat|
          r[:stats] << {
            :details => stat.details,
            :location => stat.location.map { |e| e.gsub(@input_base_dir, '') },
          }
        end
        [:errors, :warnings, :stats].each { |kind|
          r[kind].sort! { |a,b| a[:details] <=> b[:details] }
        }
        r
      end

      def summarize_reportables_by_location
        @summarize_reportables_by_location ||= (
          group_reportables_by_location.summarize
        )
      end

      def summarize_reportables_by_class
        @summarize_reportables_by_class ||= (
          group_reportables_by_class.summarize
        )
      end

      # Prints report to $stderr and file (optional)
      # @param [String] marker to identify this validation. Typically the validation class name
      # @param [String, nil] report_file_path if given, report will be appended to this file
      def write(marker, report_file_path)
        ap_options = { indent: -2, sort_keys: true, index: false, plain: true }
        r = []
        if @options['verbose']
          r << 'Reportable Details by class'
          r << '=' * 80
          r << group_reportables_by_class.ai(ap_options)
          r << ''
          r << 'Reportable Details by location'
          r << '=' * 80
          r << group_reportables_by_location.ai(ap_options)
          r << ''
        end
        r << 'Summarize Reportables by class'
        r << '=' * 80
        r << summarize_reportables_by_class.ai(ap_options)
        r << ''
        r << 'Summarize Reportables by location'
        r << '=' * 80
        r << summarize_reportables_by_location.ai(ap_options)
        r << ''
        r << ''
        r = r.join("\n")
        $stderr.puts r
        if(report_file_path)
          if !File.exist?(File.dirname(report_file_path))
            FileUtils.mkdir_p(File.dirname(report_file_path))
          end
          File.open(report_file_path, 'a') { |f|
            f.write '-' * 40
            f.write "\n\Validation '#{ marker }' at #{ Time.now.to_s }:\n\n"
            f.write(r)
          }
        end
      end

    end
  end
end
