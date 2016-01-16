# A customized parser for validation purposes. It has the following modifications
# from Kramdown::Parser::IdmlStory:
#
# * Adds validation to parsing, both at parse and update_tree time.
module Kramdown
  module Parser

    class DocxValidation < Kramdown::Parser::Docx

    end
  end
end
