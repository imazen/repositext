class Repositext

  # Represents a Repositext subtitle
  class Subtitle

    # Characters that are allowed for subtitle_ids:
    STID_CHARS_WITHOUT_ZERO = '123456789'.freeze
    STID_CHARS = '0123456789'.freeze
    STID_LENGTH = 7
    STID_REGEX = /\A[#{ Regexp.escape(STID_CHARS_WITHOUT_ZERO) }][#{ Regexp.escape(STID_CHARS) }]{#{ STID_LENGTH - 1 }}\z/

    attr_reader :char_length,
                :content,
                :persistent_id,
                :record_id,
                :relative_milliseconds,
                :samples,
                :tmp_attrs

    # @param stid [String]
    # @return [Boolean] true if stid is valid format.
    def self.valid_stid_format?(stid)
      !!(stid =~ STID_REGEX)
    end

    # @param attrs [Hash] with symbolized keys
    def initialize(attrs)
      @char_length = attrs[:char_length].to_i  if attrs[:char_length]
      @content = attrs[:content]
      @persistent_id = attrs[:persistent_id]
      @record_id = attrs[:record_id]
      @relative_milliseconds = attrs[:relative_milliseconds].to_i  if attrs[:relative_milliseconds]
      @samples = attrs[:samples].to_i  if attrs[:samples]
      @tmp_attrs = attrs[:tmp_attrs] || {}
    end

    # Returns timestamp in absolute milliseconds, computed from samples.
    # Audio is sampled at 44.1 kHz.
    # @return [Integer]
    def absolute_milliseconds
      (samples / 44.1).round
    end

    def to_s
      %(#<Repositext::Subtitle @persistent_id=#{ persistent_id.inspect }, @record_id=#{ record_id.inspect }>)
    end

    # Returns a Hash describing self
    def to_hash
      h = {
        stid: persistent_id,
        before: tmp_attrs[:before],
        after: tmp_attrs[:after],
      }
      h[:comments] = "st_index: #{ tmp_attrs[:index] }"  if tmp_attrs[:index]
      h[:afterStid] = tmp_attrs[:afterStid]  if tmp_attrs[:afterStid]
      h
    end

    def inspect
      to_s
    end

  end
end
