class Repositext
  class Cli
    module Report

    private

      # Generate summary of folio import warnings
      def report_folio_import_warnings(options)
        input_file_spec = options['input'] || 'import_folio_xml_dir/json_files'
        uniq_warnings = Hash.new(0)
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.folio.warnings\.json\Z/i,
          "Reading folio import warnings",
          options
        ) do |contents, filename|
          warnings = JSON.load(contents)
          warnings.each do |warning|
            message_stub = warning['message'].split(':').first || ''
            uniq_warnings[message_stub] += 1
          end
        end
        uniq_warnings.to_a.sort { |a,b| a.first <=> b.first }.each do |(message, count)|
          $stderr.puts " - #{ message }: #{ count }"
        end
      end

      def report_quotes_summary(options)
        output_lines = []
        ["'", '"'].each { |quote_char|
          output_lines << "Detecting #{ quote_char } quotes"
          output_lines << '-' * 80
          instances = find_all_quote_instances(quote_char, options)
          sequences = {}
          instances.each do |attrs|
            # normalize key
            key = compute_sequence_key(attrs[:pre], quote_char, attrs[:post])
            # add to hash
            sequences[key] ||= { :pre => nil, :post => nil, :count => 0 }
            sequences[key][:count] += 1
            sequences[key][:pre] = attrs[:pre]
            sequences[key][:post] = attrs[:post]
          end
          quote_instances_count = 0
          sequences.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, attrs)|
            example = "#{ attrs[:pre] }#{ quote_char }#{ attrs[:post] }".gsub(/\n/, '\\n')
            output_lines << " #{ key }    - #{ example.ljust(50, ' ') }   - #{ attrs[:count] }"
            quote_instances_count += attrs[:count]
          end
          output_lines << "-" * 80
          output_lines << "Found #{ quote_instances_count } #{ quote_char } quotes in #{ sequences.size } distinct character sequences."
          output_lines << ''
        }
        output_lines.each { |e| $stderr.puts e }
      end

      def report_quotes_details(options)
        output_lines = []
        ["'", '"'].each { |quote_char|
          output_lines << "Detecting #{ quote_char } quotes"
          output_lines << '-' * 80
          instances = find_all_quote_instances(quote_char, options)
          sequences = {}
          instances.each do |attrs|
            # normalize key
            key = compute_sequence_key(attrs[:pre], quote_char, attrs[:post])
            # add to hash
            sequences[key] ||= []
            extract = "#{ attrs[:pre] }#{ quote_char }#{ attrs[:post] }".gsub(/\n/, '\\n')
            sequences[key] << { :extract => extract, :filename => attrs[:filename] }
          end
          quote_instances_count = 0
          sequences.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, instances)|
            instances.each { |quote_instance|
              output_lines << " #{ key } - #{ quote_instance[:extract].ljust(45, ' ') } - #{ quote_instance[:filename] }"
              quote_instances_count += 1
            }
          end
          output_lines << "-" * 80
          output_lines << "Found #{ quote_instances_count } #{ quote_char } quotes in #{ sequences.size } distinct character sequences."
          output_lines << ''
        }
        output_lines.each { |e| $stderr.puts e }
      end

      # Finds invalid quote sequences, e.g., two subsequent open double quotes.
      # An invalid sequence is:
      # * two quotes of same QuoteType with no other quote inbetween (applies to s-quote-open or d-quote-close only)
      # * two d-quote-open with no other quote or paragraph boundary inbetween.
      #   When a quote spans multiple paragraphs, only the last para has a d-quote-close
      #   but all paras start with d-quote-open.
      # Note that s-quote-close is also used as apostrophe, and we could have multiple
      # of those in subsequent order without being invalid. So we don't test
      # for s-quote-close.
      # QuoteType is defined by single/double and open/close.
      # @param[String] source the kramdown source string
      # @param[Array] errors collector for errors
      # @param[Array] warnings collector for warnings
      def report_invalid_typographic_quotes(options)
        s_quote_open_and_d_quote_close = %(‘”)
        d_quote_open = %(“)
        apostrophe = %(’)
        straight_quotes = %("')
        all_quotes = [s_quote_open_and_d_quote_close, d_quote_open, apostrophe, straight_quotes].join
        invalid_quotes_rx = /
          (?:                                       # this non-capturing group handles s-quote-open and d-quote-close
            ([#{ s_quote_open_and_d_quote_close }]) # one of s-quote-open or d-quote-close
            [^#{ all_quotes }]*                     # zero or more non-quote chars inbetween
            \1                                      # same quote type as capture group 1
          )
          |
          (?:                                       # this non-capturing group handles d-quote-open
            #{ d_quote_open }                       # d-quote-open
            [^#{ all_quotes + newline }]*           # zero or more non-quote or para chars inbetween
            #{ d_quote_open }                       # d-quote-open
          )
        /mx                                         # NOTE: we don't handle s-quote-close as this is also used for apostrophes
        files_hash = {}
        context_size = 4 # num of chars to add before and after excerpt for context

        input_file_spec = options['input'] || 'content_dir/at_files'
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          "Reading folio at files",
          options
        ) do |contents, filename|
          str_sc = Kramdown::Utils::StringScanner.new(contents)
          while !str_sc.eos? do
            if(match = str_sc.scan_until(invalid_quotes_rx))
              quote_type = match[-1]
              position_of_previous_quote = match.rindex(quote_type, -2) || 0
              start_position = [position_of_previous_quote - context_size, 0].max
              excerpt = match[start_position..-1]
              excerpt << str_sc.peek(context_size)
              excerpt = excerpt.inspect
                               .gsub(/^\"/, '') # Remove leading double quotes (from inspect)
                               .gsub(/\"$/, '') # Remove trailing double quotes (from inspect)
              files_hash[filename] ||= []
              files_hash[filename] << {
                :line => str_sc.current_line_number,
                :excerpt => excerpt,
              }
            else
              break
            end
          end
        end
        $stderr.puts "Detecting invalid typographic quotes"
        $stderr.puts '-' * 80
        total_count = 0
        files_hash.to_a.sort { |a,b| a.first <=> b.first }.each do |(filename, instances)|
          $stderr.puts "File: #{ filename }"
          instances.each do |instance|
            total_count += 1
            $stderr.puts [
              " - #{ sprintf("line %5s", instance[:line]) }",
              " - |#{ instance[:excerpt].truncate_in_the_middle(120) }|",
            ].join
          end
        end
        $stderr.puts "-" * 80
        $stderr.puts "Found #{ total_count } instances of invalid typographic quotes in #{ files_hash.size } files."
      end

      def report_words_starting_with_apostrophe(options)
        # TODO: add report that shows all words starting with apostrophe that have only one character
        input_file_spec = options['input'] || 'import_folio_xml_dir/at_files'
        apostrophe_at_beginning = {}
        apostrophe_in_the_middle = {}
        other = {}
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.folio\.at\Z/i,
          "Reading folio at files",
          options
        ) do |contents, filename|
          # iterate over all single quotes followed by a character
          contents.scan(/(.{0,20})('(?=\w))(\w{0,20})/m) { |(pre, s_quote, post)|
            bin = nil
            # process key
            if pre.length > 0 && pre[-1] =~ /[^\w]/
              # at beginning of word
              l_pre = pre.rjust(4, ' ')[-4..-1]
              key = [s_quote, post].compact.join
              #key = [l_pre, s_quote, post].compact.join
              bin = apostrophe_at_beginning
            elsif pre.length > 0 && pre[-1] =~ /\w/
              # inside a word
              l_pre = pre.match(/\w+\z/)
              key = [l_pre, s_quote, post].compact.join
              bin = apostrophe_in_the_middle
            else
              # other
              key = [pre, s_quote, post].compact.join
              bin = other
            end
            key = key.downcase.ljust(20, ' ')

            # add to hash
            bin[key] ||= 0
            bin[key] += 1
          }
        end
        $stderr.puts "-" * 80
        $stderr.puts "Words starting with apostrophe."
        apostrophe_at_beginning.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          $stderr.puts " #{ key } - #{ count }"
        end
        $stderr.puts "-" * 80
        $stderr.puts "Words containing apostrophe."
        apostrophe_in_the_middle.to_a.sort { |a,b|
          # sort first by post, then by pre
          a_pre, a_post = a.first.split("'")
          b_pre, b_post = b.first.split("'")
          [a_post.strip, a_pre.strip] <=> [b_post.strip, b_pre.strip]
        }.each do |(key, count)|
          $stderr.puts " #{ key } - #{ count }"
        end
        $stderr.puts "-" * 80
        $stderr.puts "Others."
        other.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          $stderr.puts " #{ key } - #{ count }"
        end
      end

    private

      # Detects and counts quote instances. Returns an array of hashes with an entry
      # for each quote instance in the following form:
      # [
      #   { :pre => 'text before quote', :post => 'text after quote', :filename => 'path to file' },
      # ]
      # {
      #   '.".' => { :pre => 'text before quote', :post => 'text after quote', :count => 42 },
      #   ...
      # }
      # @param[String] quote_char the type of quote to detect
      # @param[Hash] options
      def find_all_quote_instances(quote_char, options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        instances = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          "Reading folio at files",
          options
        ) do |contents, filename|
          # iterate over all straight quotes
          contents.scan(/(.{0,20})((?<!\=)#{ quote_char }(?!\}))(.{0,20})/m) { |(pre, quote, post)|
            # add to array
            instances << { :pre => pre, :post => post, :filename => filename }
          }
        end
        instances
      end

      def compute_sequence_key(pre, quote_char, post)
        key = [pre[-1], quote_char, post[0]].compact.join
        key = key.gsub(/^[a-zA-Z]/, 'a') # Replace all leading chars with 'a'
                 .gsub(/[a-zA-Z]$/, 'z') # Replace all trailing chars with 'z'
                 .downcase
                 .inspect # Make non-printable chars visible
                 .gsub(/^\"/, '') # Remove leading double quotes (from inspect)
                 .gsub(/\"$/, '') # Remove trailing double quotes (from inspect)
                 .gsub(/\\"/, '"') # Unescape double quotes
                 .ljust(8, ' ') # pad on the right with space for tabular display
      end

    end
  end
end
