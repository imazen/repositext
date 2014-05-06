# A customized parser for validation purposes. It has the following modifications
# from Kramdown::Parser::Idml:
#
# * Uses the IdmlStoryValidation parser instead of IdmlStory to parse the main story.
#
module Kramdown
  module Parser
    class IdmlValidation < Kramdown::Parser::Idml

      # @param[Array<Story>, optional] stories the stories to import.
      # @param[Hash, optional] options. For validation, pass in an error and
      #                                 warnings collector:
      #     * 'validation_errors' => []
      #     * 'validation_warnings' => []
      #     * 'validation_file_descriptor' => "Descriptor for @file_to_validate or @file_set"
      def parse(stories = self.stories_to_import, options = {})
        data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        data << '<idPkg:Story xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging" DOMVersion="8.0">'
        stories.each do |story|
          data << story.body
        end
        data << '</idPkg:Story>'

        Kramdown::Document.new(
          data,
          { :input => 'IdmlStoryValidation' }.merge(options)
        )
      end

    end
  end
end
