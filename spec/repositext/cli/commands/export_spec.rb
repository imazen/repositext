require_relative '../../../helper'

class Repositext
  class Cli
    describe Export do

      describe '#compute_pdf_export_page_settings_key' do

        [
          [[true, 'stitched', 'book'], :english_stitched],
          [[true, 'bound', 'book'], :english_bound],
          [[false, 'stitched', 'book'], :foreign_stitched],
          [[false, 'bound', 'book'], :foreign_bound],
          [[false, 'bound', 'enlarged'], :foreign_stitched],
          [[true, 'bound', 'enlarged'], :english_bound],
        ].each do |attrs, xpect|
          it "handles #{ attrs.inspect }" do
            is_primary_repo, binding, size = attrs
            Cli.new(
              ['_'],
              ['--content-type-name', '_', '--rtfile', '_']
            ).send(
              :compute_pdf_export_page_settings_key,
              is_primary_repo,
              binding,
              size
            ).must_equal(xpect)
          end
        end

      end

    end
  end
end
