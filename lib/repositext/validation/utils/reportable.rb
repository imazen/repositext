class Repositext
  class Validation
    # Represents an issue that should be reported in a validation (errors or warnings).
    class Reportable

      attr_accessor :location, :details, :level

      # Instantiates a new error instance
      # @param location [Array<String>] the location of the reportable, from
      #     more general to more specific. E.g., ['file', story x', line y']
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
      # @param location [Array<String>] the location of the reportable, from
      #     more general to more specific. E.g., ['file', story x', line y']
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
      # @param location [Array<String>] the location of the reportable, from
      #     more general to more specific. E.g., ['file', story x', line y']
      # @param data [Object] typically an Array or Hash
      def self.stat(location, data)
        new(location, data, :stat)
      end

      # Instantiates a new reportable instance. You should not call this directly
      # but use the `error` and `warning` class methods.
      # @param location [Array<String>] the location of the reportable, from
      #     more general to more specific. E.g., ['file', story x', line y']
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
        location = @location[1..-1] # remove file_descriptor
        details = @details.first(3) # remove additional details
        [
          '    ',
          location.join(', ').ljust(33),
          details.join(': ')
        ].join
      end

    end
  end
end
