class Repositext
  class Cli
    module Report

    private

      # Compares the titles in Content AT with those from ERP (provided as
      # CSV file in the language repo's `data` directory)
      def report_compare_titles_with_those_of_erp(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        titles_from_erp = load_titles_from_erp
        file_count = 0
        titles_with_differences = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          nil,
          "Reading AT files",
          options
        ) do |contents, filename|
          title_from_content_at = contents.match(/(?<=^#)[^\n]+/)
                                          .to_s
                                          .gsub('*', '')
                                          .strip
          date_code = Repositext::Utils::FilenamePartExtractor.extract_date_code(filename)
          title_attrs_from_erp = titles_from_erp[date_code]
          if title_attrs_from_erp.nil?
            titles_with_differences << {
              erp: "[Could not find title from ERP with date code #{ date_code.inspect }",
              content_at: title_from_content_at,
              filename: filename,
              date_code: date_code
            }
          else
            title_from_erp = title_attrs_from_erp[:title].to_s
                                 .gsub("'", '’') # convert straight quote to typographic one
                                 .gsub('Questions And Answers', 'Questions and Answers') # ignore difference in capitalization for 'And'
                                 .gsub('#', '') # ignore presence of hash
            if title_from_erp != title_from_content_at
              titles_with_differences << {
                erp: title_from_erp,
                content_at: title_from_content_at,
                filename: filename,
                date_code: date_code
              }
            end
          end
          file_count += 1
        end
        lines = []
        titles_with_differences.sort { |a,b| a[:date_code] <=> b[:date_code] }.each do |attrs|
          l = " - #{ attrs[:date_code].ljust(8) } ERP: #{ attrs[:erp].inspect.ljust(40) } Content AT: #{ attrs[:content_at].inspect }"
          $stderr.puts l
          lines << l
        end
        summary_line = "Found #{ lines.length } titles with differences in #{ file_count } files at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir('reports_dir'), 'compare_titles_with_those_of_erp.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Compare content AT titles with those of ERP\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report compare_titles_with_those_of_erp`\n"
        }
      end

      # Generate summary of folio import warnings
      def report_folio_import_warnings(options)
        input_file_spec = options['input'] || 'folio_import_dir/json_files'
        uniq_warnings = Hash.new(0)
        file_count = 0
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.folio.warnings\.json\Z/i,
          nil,
          "Reading folio import warnings",
          options
        ) do |contents, filename|
          warnings = JSON.load(contents)
          warnings.each do |warning|
            message_stub = warning['message'].split(':').first || ''
            uniq_warnings[message_stub] += 1
          end
          file_count += 1
        end
        w = []
        uniq_warnings.to_a.sort { |a,b| a.first <=> b.first }.each do |(message, count)|
          l = " - #{ message }: #{ count }"
          $stderr.puts l
          w << l
        end
        report_file_path = File.join(config.base_dir('reports_dir'), 'folio_import_warnings_summary.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Folio Import Warnings Summary\n"
          f.write '-' * 40
          f.write "\n"
          f.write w.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write "Found #{ w.length } warnings in #{ file_count } files at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report folio_import_warnings`\n"
        }
      end

      # Generates a report with gap_mark counts for all content AT files that
      # contain gap_marks
      def report_gap_mark_count(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        file_count = 0
        files_with_gap_marks = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          nil,
          "Reading AT files",
          options
        ) do |contents, filename|
          gap_mark_count = contents.scan(/(?<!\\)%/).size
          date_code = Repositext::Utils::FilenamePartExtractor.extract_date_code(filename)
          if gap_mark_count > 0
            files_with_gap_marks << {
              gap_mark_count: gap_mark_count + 2, # add two for correct count in final document
              filename: filename,
              date_code: date_code,
            }
          end
          file_count += 1
        end
        lines = []
        files_with_gap_marks.sort { |a,b| a[:date_code] <=> b[:date_code] }.each do |attrs|
          l = " - #{ attrs[:date_code].ljust(10) } - #{ attrs[:gap_mark_count].to_s.rjust(5) }"
          $stderr.puts l
          lines << l
        end
        summary_line = "Found #{ lines.length } of #{ file_count } files with gap_marks at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir('reports_dir'), 'gap_mark_count.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Gap_mark count\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report gap_mark_count`\n"
        }
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
        newline = %(\n)
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
        output_lines = []
        files_hash = {}
        context_size = 4 # num of chars to add before and after excerpt for context

        input_file_spec = options['input'] || 'content_dir/at_files'
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          nil,
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
        output_lines << "Detecting invalid typographic quotes"
        output_lines << '-' * 80
        total_count = 0
        files_hash.to_a.sort { |a,b| a.first <=> b.first }.each do |(filename, instances)|
          output_lines << "File: #{ filename }"
          instances.each do |instance|
            total_count += 1
            output_lines << [
              " - #{ sprintf("line %5s", instance[:line]) }",
              " - |#{ instance[:excerpt].truncate_in_the_middle(120) }|",
            ].join
          end
        end
        output_lines << "-" * 80
        output_lines << "Found #{ total_count } instances of invalid typographic quotes in #{ files_hash.size } files."
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir('reports_dir'), 'invalid_typographic_quotes.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Invalid Typographic Quotes in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report invalid_typographic_quotes`\n"
        }
      end

      # Generates a report that counts all paragraph class combinations it encounters.
      def report_paragraph_classes_inventory(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        file_count = 0
        paragraph_class_combinations = Hash.new(0)
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          nil,
          "Reading AT files",
          options
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          doc_paragraph_class_combinations = doc.to_report_paragraph_classes_inventory
          doc_paragraph_class_combinations.each do |pcc, count|
            paragraph_class_combinations[pcc] += count
          end
          file_count += 1
        end
        lines = []
        paragraph_class_combinations.to_a.sort { |a,b| a.first <=> b.first }.each do |(classes, count)|
          l = " - #{ classes }: #{ count }"
          $stderr.puts l
          lines << l
        end
        report_file_path = File.join(config.base_dir('reports_dir'), 'paragraph_classes_inventory.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Paragraph classes inventory\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write "Found #{ lines.length } combinations of paragraph classes in #{ file_count } files at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report paragraph_classes_inventory`\n"
        }
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
        report_file_path = File.join(config.base_dir('reports_dir'), 'content_quotes_details.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Quotes Details in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report quotes_details`\n"
        }
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
        report_file_path = File.join(config.base_dir('reports_dir'), 'content_quotes_summary.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Quotes Summary in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report quotes_summary`\n"
        }
      end

      def report_words_with_apostrophe(options)
        # TODO: add report that shows all words starting with apostrophe that have only one character
        input_file_spec = options['input'] || 'folio_import_dir/at_files'
        apostrophe_at_beginning = {}
        apostrophe_in_the_middle = {}
        other = {}
        ouputs_lines = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.folio\.at\Z/i,
          nil,
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
        output_lines << "-" * 80
        output_lines << "Words starting with apostrophe."
        apostrophe_at_beginning.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines << "-" * 80
        output_lines << "Words containing apostrophe."
        apostrophe_in_the_middle.to_a.sort { |a,b|
          # sort first by post, then by pre
          a_pre, a_post = a.first.split("'")
          b_pre, b_post = b.first.split("'")
          [a_post.strip, a_pre.strip] <=> [b_post.strip, b_pre.strip]
        }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines << "-" * 80
        output_lines << "Others."
        other.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir('reports_dir'), 'words_with_apostrophe.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Words with Apostrophe in Content\n"
          f.write '-' * 40
          f.write output_lines.join("\n")
          f.write "\nCommand to generate this file: `repositext report words_with_apostrophe`"
        }
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
          nil,
          "Reading folio at files",
          options
        ) do |contents, filename|
          # iterate over all straight quotes
          # Don't include straight quotes inside IALs
          contents.gsub(/\{[^\{\}]*\}/, ' ') # remove all ials
                  .scan(/(.{0,20})((?<!\=)#{ quote_char }(?!\}))(.{0,20})/m) { |(pre, quote, post)|
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

      # Returns a hash with the titles from ERP with the date code as keys
      def load_titles_from_erp
        # Expects pwd to be root of the current repo
        filename = File.expand_path('data/titles_from_erp.csv', Dir.pwd)
        h = {}
        CSV.foreach(filename, { col_sep: "\t", headers: :first_row }) do |row|
          h[row['ProductID'].downcase] = {
            date_code: row['ProductID'].downcase,
            product_identity_id: row['ProductIdentityID'],
            title: row['ProductTitle']
          }
        end
        h
      end

    end
  end
end
