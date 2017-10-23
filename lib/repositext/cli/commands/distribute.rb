class Repositext
  class Cli
    # This namespace contains methods related to the `distribute` command.
    module Distribute

    private

      # Adds the corresponding primary title to the filename.
      # NOTE: This has to be done before
      #   distribute_pdf_export_modify_date_code_and_product_identity_id!
      # (We use the product_identity_id as anchor in the regex!)
      def distribute_pdf_export_add_primary_title(options)
        sanitized_primary_titles = options[:primary_titles].inject({}) { |m, (pid, title)|
          # sanitize titles: remove anything other than letters, digits, hyphens, or spaces,
          # and collapse whitespace.
          m[pid] = title.strip
                        .gsub(/[^a-z\d\s\-]/i, '')
                        .gsub(/\s+/, ' ')
          m
        }
        file_rename_proc = Proc.new { |input_filename|
          r_file_stub = RFile::Content.new('_', Language.new, input_filename)
          product_identity_id = r_file_stub.extract_product_identity_id
          title = sanitized_primary_titles[product_identity_id]
          # Insert title into filename, optionally append suffix
          if options[:dist_add_suffix]
            title += options[:pdf_export_filename_title_suffix]
          end
          input_filename.sub(
            /_#{ product_identity_id }\.(?!\-\-)/,
            "_#{ product_identity_id } #{ title }.",
          )
        }
        Repositext::Cli::Utils.rename_files(
          config.compute_base_dir(:pdf_export_distribution_dir),
          config.compute_file_selector(:all_files),
          config.compute_file_extension(:pdf_extension),
          file_rename_proc,
          options['file_filter'],
          "Adding primary titles to filenames",
          options
        )
      end

      # Modifies the filename's date_code and product_identity_id
      # NOTE: This has to be done after distribute_pdf_export_add_primary_title!
      def distribute_pdf_export_modify_date_code_and_product_identity_id(options)
        file_rename_proc = Proc.new { |input_filename|
          input_filename.sub(/(?<=\/)(?<lc_dc>[a-z]{3}\d{2}-\d{4}[a-z]?)_\d{4}/) { |match|
            # Upper case all letters in language and date code, drop product_identity id
            $~[:lc_dc].upcase
          }
        }
        Repositext::Cli::Utils.rename_files(
          config.compute_base_dir(:pdf_export_distribution_dir),
          config.compute_file_selector(:all_files),
          config.compute_file_extension(:pdf_extension),
          file_rename_proc,
          options['file_filter'],
          "Modifying filenames' date_codes and product_identity_ids",
          options
        )
      end

      # Removes the pdf type from the filename
      def distribute_pdf_export_remove_pdf_type(options)
        file_rename_proc = Proc.new { |input_filename|
          input_filename.sub(/\.[^\.]+\.pdf\z/, ".pdf")
        }
        Repositext::Cli::Utils.rename_files(
          config.compute_base_dir(:pdf_export_distribution_dir),
          config.compute_file_selector(:all_files),
          config.compute_file_extension(:pdf_extension),
          file_rename_proc,
          options['file_filter'],
          "Removing pdf type from filenames",
          options
        )
      end

    end
  end
end
