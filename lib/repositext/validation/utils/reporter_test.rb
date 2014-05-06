class Repositext
  class Validation

    class ReporterTest

      attr_reader :errors, :warnings, :stats

      def initialize(_file_pattern_base_path, _file_pattern, _validation)
        @errors = []
        @warnings = []
        @stats = []
      end

      # Use this method to add an error to self.
      # @param[Reportable] _reportable
      def add_error(_reportable)
        @errors << _reportable
      end

      # Use this method to add an array of errors to self.
      # @param[Array<Reportable>] _errors
      def add_errors(_errors, _sort_by = :location)
        if _sort_by
          _errors = _errors.sort { |a,b| a.send(_sort_by) <=> b.send(_sort_by) }
        end
        _errors.each do |e|
          self.add_error(e)
        end
      end

      # Use this method to add a stat to self
      # @param[Reportable] _stat
      def add_stat(_stat)
        @stats << _stat
      end

      # Use this method to add an array of stats to self
      # @param[Array<Reportable>] _stats
      def add_stats(_stat)
        _stats.each do |e|
          self.add_stat(e)
        end
      end

      # Use this method to add a warning to self.
      # @param[Reportable] _reportable
      def add_warning(_reportable)
        @warnings << _reportable
      end

      # Use this method to add an array of warnings to self.
      # @param[Array<Reportable>] _warnings
      def add_warnings(_warnings, _sort_by = :location)
        if _sort_by
          _warnings = _warnings.sort { |a,b| a.send(_sort_by) <=> b.send(_sort_by) }
        end
        _warnings.each do |e|
          self.add_warning(e)
        end
      end

    end
  end
end
