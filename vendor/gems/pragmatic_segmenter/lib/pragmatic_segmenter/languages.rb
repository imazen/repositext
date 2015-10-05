require 'pragmatic_segmenter/types'
require 'pragmatic_segmenter/processor'
require 'pragmatic_segmenter/cleaner'

require 'pragmatic_segmenter/languages/common'

require 'pragmatic_segmenter/languages/afrikaans'
require 'pragmatic_segmenter/languages/amharic'
require 'pragmatic_segmenter/languages/arabic'
require 'pragmatic_segmenter/languages/armenian'
require 'pragmatic_segmenter/languages/burmese'
require 'pragmatic_segmenter/languages/chinese'
require 'pragmatic_segmenter/languages/deutsch'
require 'pragmatic_segmenter/languages/dutch'
require 'pragmatic_segmenter/languages/english'
require 'pragmatic_segmenter/languages/french'
require 'pragmatic_segmenter/languages/greek'
require 'pragmatic_segmenter/languages/hindi'
require 'pragmatic_segmenter/languages/italian'
require 'pragmatic_segmenter/languages/japanese'
require 'pragmatic_segmenter/languages/persian'
require 'pragmatic_segmenter/languages/polish'
require 'pragmatic_segmenter/languages/russian'
require 'pragmatic_segmenter/languages/spanish'
require 'pragmatic_segmenter/languages/urdu'

module PragmaticSegmenter
  module Languages
    LANGUAGE_CODES = {
      'af' => Afrikaans,
      'am' => Amharic,
      'ar' => Arabic,
      'de' => Deutsch,
      'el' => Greek,
      'en' => English,
      'es' => Spanish,
      'fa' => Persian,
      'fr' => French,
      'hi' => Hindi,
      'hy' => Armenian,
      'it' => Italian,
      'ja' => Japanese,
      'my' => Burmese,
      'nl' => Dutch,
      'pl' => Polish,
      'ru' => Russian,
      'ur' => Urdu,
      'zh' => Chinese,
    }

    def self.get_language_by_code(code)
      LANGUAGE_CODES[code] || Common
    end
  end
end
