=begin

# Notes

* I can't convert latex to pdf without temporary files (xelatex generates a bunch
  of output files, not just one).
* I can use stdin to xelatex to avoid the input file.

I'm collecting text fragments in logs of aborted jobs to detect issues during export:

* 'job aborted'
* 'Emergency stop.'
* 'Overfull \hbox (22.5pt too wide) in paragraph at lines 853--862'
* 'Underfull \hbox (badness 1009) in paragraph at lines 786--787'
* 'Undefined control sequence'
* 'Package microtype Error'

* 'file:line:error style messages enabled.' # don't match on this! find other instances of error
* 'No complaints by nag'

=end

class Repositext
  class Convert
    class LatexToPdf

      class XelatexNotInstalledError < ::StandardError; end

      # @param latex [String] a latex document
      # @return [PDF] a pdf binary string
      def self.convert(latex)
        xelatex_location = `which xelatex`.strip
        if '' == xelatex_location || !FileTest.executable?(xelatex_location)
          raise(XelatexNotInstalledError.new('Could not find xelatex. Please install xelatex to generate PDFs.'))
        end
        pdf = ''
        log = ''
        Dir.mktmpdir { |tmp_dir|
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
          tex_file_contents = File.read(File.join(tmp_dir, 'tmp.tex'))
          log_file_contents = File.read(File.join(tmp_dir, 'tmp.log'))
          # puts '-' * 80
          # puts Dir.entries(tmp_dir)
          # puts '-' * 80
          # puts tex_file_contents
          # puts '-' * 80
          # puts log_file_contents
          # puts '-' * 80

          pdf_filename = File.join(tmp_dir, 'tmp.pdf')
          pdf = File.binread(pdf_filename)
        }
        # TODO: consider not removing the tmp dir on exception so that the log
        # can be inspected. Or print out log on exception.
        pdf
      end

    end
  end
end
