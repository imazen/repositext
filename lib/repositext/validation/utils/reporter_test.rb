class Repositext
  class Validation

    # This reporter is for testing. It doesn't output anything to keep the
    # console clean during test runs.
    class ReporterTest

      attr_reader :errors, :warnings, :stats

      # @param _input_base_dir [String]
      # @param _file_selector [String]
      # @param _file_extension [String]
      # @param logger [Logger]
      def initialize(_input_base_dir, _file_selector, _file_extension, logger)
        @errors = []
        @warnings = []
        @stats = []
      end

      # Use this method to add an error to self.
      # @param [Reportable] _reportable
      def add_error(_reportable)
        @errors << _reportable
      end

      # Use this method to add an array of errors to self.
      # @param [Array<Reportable>] _errors
      def add_errors(_errors)
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

    end
  end
end
