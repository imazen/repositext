# Defines some string constants used throughout repositext.
class Repositext

  # Returns a Hash with options to be used whenever we generate JSON
  JSON_FORMATTING_OPTIONS = {
    indent: '  ',
    space: '',
    space_before: '',
    object_nl: "\n",
    array_nl: "\n",
    allow_nan: false,
    max_nesting: 100,
  }

  PARALLEL_CORES = case ENV['NUMBER_OF_CORES_FOR_PARALLEL_PROCESSING']
  when /\A\d+\z/
    # Set to numeric value
    ENV['NUMBER_OF_CORES_FOR_PARALLEL_PROCESSING'].to_i
  when 'all'
    Parallel.processor_count
  when 'all_but_one'
    Parallel.processor_count - 1
  else
    raise "Invalid value for NUMBER_OF_CORES_FOR_PARALLEL_PROCESSING: #{ ENV['NUMBER_OF_CORES_FOR_PARALLEL_PROCESSING'].inspect }"
  end

  # Returns absolute path to repositext_parent directory.
  # NOTE: This implementation only works as long as we're using
  # local/path gems. Once we install them from somewhere else,
  # we'll have to update this implementation.
  PARENT_DIR = File.expand_path('../../../../', __FILE__)

  # We use this character to delimit sentences, e.g., in Lucene exported plain
  # text proximity
  # 0x256B - Box Drawings Vertical Double And Horizontal Single
  # (utf8 representation: E2 95 AB)
  SENTENCE_DELIMITER = "╫"
  SENTENCE_TERMINATOR_CHARS = ['.', '!', '?']

  US_STATES = {
    'AK' => 'Alaska',
    'AL' => 'Alabama',
    'AR' => 'Arkansas',
    'AS' => 'American Samoa',
    'AZ' => 'Arizona',
    'CA' => 'California',
    'CO' => 'Colorado',
    'CT' => 'Connecticut',
    'DC' => 'District of Columbia',
    'DE' => 'Delaware',
    'FL' => 'Florida',
    'GA' => 'Georgia',
    'GU' => 'Guam',
    'HI' => 'Hawaii',
    'IA' => 'Iowa',
    'ID' => 'Idaho',
    'IL' => 'Illinois',
    'IN' => 'Indiana',
    'KS' => 'Kansas',
    'KY' => 'Kentucky',
    'LA' => 'Louisiana',
    'MA' => 'Massachusetts',
    'MD' => 'Maryland',
    'ME' => 'Maine',
    'MI' => 'Michigan',
    'MN' => 'Minnesota',
    'MO' => 'Missouri',
    'MS' => 'Mississippi',
    'MT' => 'Montana',
    'NC' => 'North Carolina',
    'ND' => 'North Dakota',
    'NE' => 'Nebraska',
    'NH' => 'New Hampshire',
    'NJ' => 'New Jersey',
    'NM' => 'New Mexico',
    'NV' => 'Nevada',
    'NY' => 'New York',
    'OH' => 'Ohio',
    'OK' => 'Oklahoma',
    'OR' => 'Oregon',
    'PA' => 'Pennsylvania',
    'PR' => 'Puerto Rico',
    'RI' => 'Rhode Island',
    'SC' => 'South Carolina',
    'SD' => 'South Dakota',
    'TN' => 'Tennessee',
    'TX' => 'Texas',
    'UT' => 'Utah',
    'VA' => 'Virginia',
    'VI' => 'Virgin Islands',
    'VT' => 'Vermont',
    'WA' => 'Washington',
    'WI' => 'Wisconsin',
    'WV' => 'West Virginia',
    'WY' => 'Wyoming',
  }

end
