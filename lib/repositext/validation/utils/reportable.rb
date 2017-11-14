class Repositext
  class Validation
    # Represents an issue that should be reported in a validation (errors or warnings).
    class Reportable

      attr_accessor :location, :details, :level

      # Instantiates a new error instance
      # @param location [Hash{Symbol => Object}] the location of the reportable,
      #   as a Hash with the following keys:
      #   * :filename
      #   * :line
      #   * :column
      #   * :context
      #   * :corr_filename
      #   * :corr_line
      #   * :corr_column
      #   * :corr_context
      # @param details [Array<String>] an array with information about the
      #     reportable, from more general to more specific. Follow this convention:
      #     1. error class as string
      #     2. error messages as string (up to 80 characters so it fits on a line)
      #     3. error additional details (optional) no limit here. Only used for
      #        highest level of verbosity.
      def self.error(location, details)
        new(location, details, :error)
      end

      # Instantiates a new warning instance
      # @param location [Hash{Symbol => Object}] the location of the reportable,
      #   as a Hash with the following keys:
      #   * :filename
      #   * :line
      #   * :column
      #   * :context
      #   * :corr_filename
      #   * :corr_line
      #   * :corr_column
      #   * :corr_context
      # @param details [Array<String>] an array with information about the
      #     reportable, from more general to more specific. Follow this convention:
      #     1. error class as string
      #     2. error messages as string (up to 80 characters so it fits on a line)
      #     3. error additional details (optional) no limit here. Only used for
      #        highest level of verbosity.
      def self.warning(location, details)
        new(location, details, :warning)
      end

      # Instantiates a new stat instance
      # @param location [Hash{Symbol => Object}] the location of the reportable,
      #   as a Hash with the following keys:
      #   * :filename
      #   * :line
      #   * :column
      #   * :context
      #   * :corr_filename
      #   * :corr_line
      #   * :corr_column
      #   * :corr_context
      # @param data [Object] typically an Array or Hash
      def self.stat(location, data)
        new(location, data, :stat)
      end

      # Instantiates a new reportable instance. You should not call this directly
      # but use the `error` and `warning` class methods.
      # @param location [Hash{Symbol => Object}] the location of the reportable,
      #   as a Hash with the following keys:
      #   * :filename
      #   * :line
      #   * :column
      #   * :context
      #   * :corr_filename
      #   * :corr_line
      #   * :corr_column
      #   * :corr_context
      # @param details [Array<String>] an array with information about the
      #     reportable, from more general to more specific. Follow this convention:
      #     1. error class as string
      #     2. error messages as string (up to 80 characters so it fits on a line)
      #     3. error additional details (optional) no limit here. Only used for
      #        highest level of verbosity.
      # @param level [Symbol] one of :error or :warning
      def initialize(location, details, level)
        @location = location
        @details = details
        @level = level
      end

      # Returns self as string on a single line
      # @return [String]
      def to_line
        [@location.join(', '), @details.join(': ')].join(' - ')
      end

      # Returns self as string suitable as part of console logging
      def log_to_console
        details_attrs = details.first(3) # remove additional details
        location_attrs = []
        if location[:line]
          location_attrs << "line #{ location[:line] }"
        end
        if location[:context]
          location_attrs << location[:context].inspect
        end
        [
          '    ',
          location_attrs.join(': ').ljust(50),
          details_attrs.join(': ')
        ].join
      end

    end
  end
end
