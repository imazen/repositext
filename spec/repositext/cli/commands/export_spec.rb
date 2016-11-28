require_relative '../../../helper'

class Repositext
  class Cli
    describe Export do

      describe '#compute_pdf_export_page_settings_key' do

        [
          [[nil, true, 'stitched', 'book'], :english_stitched],
          [[nil, true, 'bound', 'book'], :english_bound],
          [[nil, false, 'stitched', 'book'], :foreign_stitched],
          [[nil, false, 'bound', 'book'], :foreign_bound],
          [[nil, false, 'bound', 'enlarged'], :foreign_stitched],
          [[nil, true, 'bound', 'enlarged'], :english_bound],
          [['foreign_stitched', true, 'bound', 'enlarged'], :foreign_stitched],
        ].each do |attrs, xpect|
          it "handles #{ attrs.inspect }" do
            page_settings_key_override, is_primary_repo, binding, size = attrs
            Cli.new(
              ['_'],
              ['--content-type-name', '_', '--rtfile', '_']
            ).send(
              :compute_pdf_export_page_settings_key,
              page_settings_key_override,
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
