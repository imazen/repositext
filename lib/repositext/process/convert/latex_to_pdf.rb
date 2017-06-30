class Repositext
  class Process
    class Convert
      # Converts a latex string to a PDF file using xelatex.
      #
      # Notes
      #
      # * I can't convert latex to pdf without temporary files (xelatex generates a bunch
      #   of output files, not just one).
      # * I can use stdin to xelatex to avoid the input file.
      #
      # I'm collecting text fragments in logs of aborted jobs to detect issues during export:
      #
      # * 'job aborted'
      # * 'Emergency stop.'
      # * 'Overfull \hbox (22.5pt too wide) in paragraph at lines 853--862'
      # * 'Underfull \hbox (badness 1009) in paragraph at lines 786--787'
      # * 'Undefined control sequence'
      # * 'Package microtype Error'
      #
      # Page with good info on warnings:
      # http://www.eng.fsu.edu/~dommelen/l2h/warnings.html#undervbh
      #
      # * 'file:line:error style messages enabled.' # don't match on this! find other instances of error
      # * 'No complaints by nag'
      class LatexToPdf

        class XelatexNotInstalledError < ::StandardError; end

        # @param latex [String] a latex document
        # @return [PDF] a pdf binary string
        def self.convert(latex)
          xelatex_location = `which xelatex`.strip
          if '' == xelatex_location || !FileTest.executable?(xelatex_location)
            raise(
              XelatexNotInstalledError.new(
                'Could not find xelatex. Please install xelatex to generate PDFs: http://www.tug.org/mactex/'
              )
            )
          end
          pdf = ''
          Dir.mktmpdir { |tmp_dir|
            max_num_loops = 4
            has_overfull_hboxes = true
            loop_count = 0
            while has_overfull_hboxes && loop_count < max_num_loops do
              loop_count += 1
              s = "   - converting latex to pdf (iteration #{ loop_count })"
              # Highlight last iteration in red because it likely failed.
              if loop_count == max_num_loops
                s = s.color(:red)
              end
              puts s
              convert_latex_to_pdf(tmp_dir, latex)
              log_file_contents = File.read(File.join(tmp_dir, 'tmp.log'))

              # tex_file_contents = File.read(File.join(tmp_dir, 'tmp.tex'))
              # puts '-' * 80
              # puts Dir.entries(tmp_dir)
              # puts '-' * 80
              # puts tex_file_contents
              # puts '-' * 80
              # puts log_file_contents
              # puts '-' * 80

              # Uncomment this to write the tex_file_contents to your Desktop
              # folder for inspection.
              # File.write(File.join(Dir.home, "Desktop/tex_file_contents.txt"), tex_file_contents)

              ohbs = find_overfull_hboxes(log_file_contents)
              ohbs.each { |e| puts "     #{ e.inspect }" }
              if ohbs.any?
                ohbs.each { |ohb|
                  insert_line_break_into_ohb!(ohb, latex)
                }
                has_overfull_hboxes = true
              else
                warn_on_underful_vboxes(log_file_contents)
                has_overfull_hboxes = false
              end
            end

            pdf_filename = File.join(tmp_dir, 'tmp.pdf')
            pdf = File.binread(pdf_filename)
          }
          # TODO: consider not removing the tmp dir on exception so that the log
          # can be inspected. Or print out log on exception.
          pdf
        end

      protected

        # @param tmp_dir [String] the tmp_dir to work inside of
        # @param latex [String] latex source
        def self.convert_latex_to_pdf(tmp_dir, latex)
          latex_filename = File.join(tmp_dir, 'tmp.tex')
          File.write(latex_filename, latex)
          command = [
            "xelatex",
            "-file-line-error",
            "-interaction=nonstopmode",
            "-synctex=1",
            "-output-directory=#{ tmp_dir }",
            latex_filename,
          ].join(' ')
          `#{ command }`
        end

        # Returns any overfull hboxes
        # @param log_file_contents [String] latex log file contents
        # @return [Array<Hash>] [{ overhang_in_pt: 59, line: 557, offensive_string: "Offending text" }]
        def self.find_overfull_hboxes(log_file_contents)
          # We're looking for a log entry like this:
          #
          # Overfull \hbox (59.42838pt too wide) in paragraph at lines 557--558
          # \EU1/Lohit-Tamil(0)/m/n/13.00003 <some text>
          #  <some more text>
          #  []
          #

          # The log file may contain invalid UTF8 byte sequences (see last line in example below)
          # so we have to scrub the string before we run regexes on it.
          #
          # /var/folders/9m/_0s7926s0bd5hkb340dhzlh40000gn/T/d20160202-65202-8g6jgd/tmp.tex
          # :1021: Undefined control sequence.
          # <argument> \TEXTBF
          #                    {\EMPH {எபிரெயர், ஏழாம் அத�...
          # l.1021

          all_ohbs = log_file_contents.scrub.scan(
            /
              (?:^Overfull\s\\hbox\s\() # Start of line
              (\d+) # overhang in pt
              (?:\.\d*pt\stoo\swide\)\sin\sparagraph\sat\slines\s) # middle of line
              (\d+) # line number
              (?:[^\n]+\n) # until end of line
              (?:\s?) # optional space at beginning of line
              (?:[^\s]+\s+) # font preamble until first space
              ([^\[]+) # offensive string
              (?:\[\]) # closing brackets
            /x
          ).map { |overhang_in_pt, line, offensive_string|
            {
              overhang_in_pt: overhang_in_pt.to_i,
              line: line.to_i,
              offensive_string: offensive_string.gsub("\n", '').strip # remove newlines inserted by xelatex logger and surrounding spaces
            }
          }
          ohbs_to_fix = []
          all_ohbs.each { |e|
            # We fix all overfull hboxes with overhang > 5pt.
            # We only fix the first overfull hbox in each paragraph since inserting
            # a manual line break will affect all following line breaks, and the
            # previously reported ohbs won't be valid any more. This approach will
            # result in more iterations, however it will prevent orphaned words on
            # a line where a line break was inserted in the wrong spot.
            if e[:overhang_in_pt] > 0 && ohbs_to_fix.none? { |f| f[:line] == e[:line] }
              ohbs_to_fix << e
            end
          }
          ohbs_to_fix
        end

        # Inserts a latex linebreak into lines with overfull hboxes.
        # @param ohb [Hash] { overhang_in_pt: 59, line: 557, offensive_string: "Offending text" }
        # @param latex [String] the latex string, will be modified in place
        def self.insert_line_break_into_ohb!(ohb, latex)
          # [{ overhang_in_pt: 46, line: 376, offensive_string: "A string" }]
          # Latex doesn't wrap the words because moving the last word to a new
          # line would result in too much inter-word spacing on that line.
          #
          # We insert the `\linebreak` latex command followed by a newline at the
          # last space in the line, so that the last word will be on a new line.
          # OPTIMIZE: ideally we'd replace it only at the specified line! (:ohb[:line])
          latex.gsub!(
            ohb[:offensive_string],
            ohb[:offensive_string].sub(/(\s+)(\S*)\z/, "\\linebreak\n" + '\2')
          )
        end

        # Prints a warning for any underfull vboxes.
        # @param log_file_contents [String] latex log file contents
        def self.warn_on_underful_vboxes(log_file_contents)
          # We're looking for a log entry like this:
          #
          #  [28]
          # Underfull \vbox (badness 336) has occurred while \output is active []
          #
          #  [29]

          # The log file may contain invalid UTF8 byte sequences
          # so we have to scrub the string before we run regexes on it.
          #
          ufvbs = log_file_contents.scrub.scan(
            /
              (?:^Underfull\s\\vbox\s\(badness\s) # Start of line
              (\d+) # badness
              (?:.*?) # skip any content inbetween
              (\[\d+\]) # capture page indicator
            /xm
          )

          if ufvbs.any?
            puts "Found pages with large paragraph spacing (underfull vboxes):".color(:red)
            ufvbs.each { |badness, page_number|
              puts " - Page #{ page_number }, badness: #{ badness }".color(:red)
            }
          end
          true
        end

      end
    end
  end
end
