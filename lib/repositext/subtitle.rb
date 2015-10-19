class Repositext

  # Represents a Repositext subtitle
  class Subtitle

    attr_reader :char_length,
                :persistent_id,
                :record_id,
                :relative_milliseconds,
                :samples

    # @param attrs [Hash] with symbolized keys
    def initialize(attrs)
      @char_length = attrs[:char_length].to_i  if attrs[:char_length]
      @persistent_id = attrs[:persistent_id]
      @record_id = attrs[:record_id]
      @relative_milliseconds = attrs[:relative_milliseconds].to_i  if attrs[:relative_milliseconds]
      @samples = attrs[:samples].to_i  if attrs[:samples]
    end

    # Returns timestamp in absolute milliseconds, computed from samples.
    # Audio is sampled at 44.1 kHz.
    # @return [Integer]
    def absolute_milliseconds
      (samples / 44.1).round
    end

  end
end
