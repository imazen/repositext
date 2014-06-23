=begin

# Notes

* I can't convert latex to pdf without temporary files (xelatex generates a bunch
  of output files, not just one).
* I can use stdin to xelatex to avoid the input file.

=end

class Repositext
  class Convert
    class LatexToPdf

      class XelatexNotInstalledError < ::StandardError; end

      def self.convert(latex)
        xelatex_location = `which xelatex`.strip
        if '' == xelatex_location || !FileTest.executable?(xelatex_location)
          raise(XelatexNotInstalledError.new('Could not find xelatex. Please install xelatex to generate PDFs.'))
        end
        r = nil
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
          # puts '-' * 80
          # puts Dir.entries(tmp_dir)
          # puts '-' * 80
          # puts File.read(File.join(tmp_dir, 'tmp.tex'))
          # puts '-' * 80
          # puts File.read(File.join(tmp_dir, 'tmp.log'))
          # puts '-' * 80
          pdf_filename = File.join(tmp_dir, 'tmp.pdf')
          r = File.binread(pdf_filename)
        }
        # TODO: consider not removing the tmp dir on exception so that the log
        # can be inspected. Or print out log on exception.
        r
      end

    end
  end
end
