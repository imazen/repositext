module Kramdown
  module Parser
    # A customized parser for validation purposes. Customize in subclass.
    class DocxValidation < Kramdown::Parser::Docx
    end
  end
end
