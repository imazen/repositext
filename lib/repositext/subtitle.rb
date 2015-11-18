class Repositext

  # Represents a Repositext subtitle
  class Subtitle

    # Characters that are allowed for persistent_ids:
    STID_CHARS = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'.freeze
    # stid forbidden chars: iloIO01

    STID_REGEX = /\A[#{ Regexp.escape(STID_CHARS) }]{4}\z/

    attr_reader :char_length,
                :persistent_id,
                :record_id,
                :relative_milliseconds,
                :samples

    # @param stid [String]
    # @return [Boolean] true if stid is valid format.
    def self.valid_stid_format?(stid)
      !!(stid =~ STID_REGEX)
    end

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
