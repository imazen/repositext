class Repositext

  # Represents a Repositext subtitle
  class Subtitle

    # Characters that are allowed for subtitle_ids:
    STID_CHARS_WITHOUT_ZERO = '123456789'.freeze
    STID_CHARS = '0123456789'.freeze
    STID_LENGTH = 7
    STID_REGEX = /\A[#{ Regexp.escape(STID_CHARS_WITHOUT_ZERO) }][#{ Regexp.escape(STID_CHARS) }]{#{ STID_LENGTH - 1 }}\z/

    attr_accessor :char_length,
                  :content,
                  :persistent_id,
                  :record_id,
                  :relative_milliseconds,
                  :samples,
                  :tmp_attrs

    # Instantiates instance of self from hash
    def self.from_hash(hash)
      new(
        persistent_id: hash[:stid],
        record_id: hash[:record_id],
        tmp_attrs: {
          after: hash[:after],
          before: hash[:before],
          index: hash[:index],
        }
      )
    end

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

    # Returns true if other_obj is a subtitle and has same persistent id.
    # @param other_obj [Object]
    def ==(other_obj)
      other_obj.is_a?(Subtitle) && other_obj.persistent_id == persistent_id
    end

    # Returns timestamp in absolute milliseconds, computed from samples.
    # Audio is sampled at 44.1 kHz.
    # @return [Integer]
    def absolute_milliseconds
      (samples / 44.1).round
    end

    def inspect
      to_s
    end

    def tmp_after
      tmp_attrs[:after]
    end

    def tmp_before
      tmp_attrs[:before]
    end

    def tmp_index
      tmp_attrs[:index]
    end

    # Returns a Hash describing self
    def to_hash
      h = {
        stid: persistent_id,
        record_id: record_id,
        before: tmp_attrs[:before],
        after: tmp_attrs[:after],
      }
      # h[:comments] = "st_index: #{ tmp_attrs[:index] }"  if tmp_attrs[:index]
      h[:afterStid] = tmp_attrs[:afterStid]  if tmp_attrs[:afterStid]
      h
    end

    def to_s
      attrs = %w[
        persistent_id
        record_id
        char_length
        relative_milliseconds
        samples
        content
        tmp_attrs
      ].map{ |e| "@#{ e }=#{ self.send(e).inspect }"}.join(', ')
      %(#<Repositext::Subtitle #{ attrs }>)
    end

  end
end
