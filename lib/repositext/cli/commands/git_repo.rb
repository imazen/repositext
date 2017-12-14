class Repositext
  class Cli
    # This namespace contains methods related to the `git_repo` command.
    module GitRepo

    private

      # Clones all git repos that don't exist on local filesystem yet.
      # Run this from inside primary repo.
      # @param [Hash] options
      def git_repo_clone_missing_repos(options)
        if !config.setting(:is_primary_repo)
          raise "Please run this command from inside the primary repository"
        end
        RepositorySet.new(Repositext::PARENT_DIR).git_clone_missing_repos(:all_content_repos)
      end

      # Runs `rt delete all_pdf_exports` on all content repos
      def git_repo_delete_all_pdf_exports(options)
        RepositorySet.new(Repositext::PARENT_DIR).delete_all_pdf_exports(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt export pdf_book` on all content repos
      def git_repo_export_pdf_book_all(options)
        RepositorySet.new(Repositext::PARENT_DIR).export_pdf_book(
          :all_content_repos,
          content_type
        )
      end

      # Fetches all branches and pulls current branch.
      # @param [Hash] options
      def git_repo_fetch_and_pull_all_content(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_fetch_and_pull(:all_content_repos)
      end

      # Runs `rt fix add_first_par_class` on all content repos
      def git_repo_fix_add_first_par_class(options)
        RepositorySet.new(Repositext::PARENT_DIR).fix_add_first_par_class(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt fix add_initial_data_json_file` on all content repos
      def git_repo_fix_add_initial_data_json_file(options)
        RepositorySet.new(Repositext::PARENT_DIR).fix_add_initial_data_json_file(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt fix normalize_trailing_newlines` on all content repos
      def git_repo_fix_normalize_trailing_newlines(options)
        RepositorySet.new(Repositext::PARENT_DIR).fix_normalize_trailing_newlines(
          :all_content_repos,
          content_type
        )
      end

      # Initializes any empty language repos. Copies standard files from primary repo.
      # Run this from inside primary repo.
      # @param [Hash] options
      def git_repo_initialize_empty_content_repos(options)
        if !config.setting(:is_primary_repo)
          raise "Please run this command from inside the primary repository"
        end
        RepositorySet.new(Repositext::PARENT_DIR).initialize_empty_content_repos(Dir.pwd)
      end

      # Pulls latest commits from all upstream code repositories.
      # @param [Hash] options
      def git_repo_pull_all_code(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_pull(:code_repos)
      end

      # Pulls latest commits from all upstream content repositories.
      # @param [Hash] options
      def git_repo_pull_all_content(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_pull(:all_content_repos)
      end

      # Runs `rt report content_sources` on all content repos
      def git_repo_report_all_content_sources(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_content_sources(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report count_files_with_gap_marks_and_subtitle_marks` on all content repos
      def git_repo_report_all_count_files_with_gap_marks_and_subtitle_marks(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_count_files_with_gap_marks_and_subtitle_marks(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report quotes_details` on all content repos
      def git_repo_report_all_quotes_details(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_quotes_details(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report character_inventory` on all content repos
      def git_repo_report_character_inventory(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_character_inventory(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report files_that_dont_have_st_sync_active` on all content repos
      def git_repo_report_files_that_dont_have_st_sync_active(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_files_that_dont_have_st_sync_active(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report files_with_subtitles_that_require_review` on all foreign content repos
      def git_repo_report_files_with_subtitles_that_require_review(options)
        RepositorySet.new(Repositext::PARENT_DIR).report_files_with_subtitles_that_require_review(
          :foreign_content_repos,
          content_type
        )
      end

      # Resets the git repo for all content repositories
      # @param [Hash] options
      def git_repo_reset_all_content(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_reset(:all_content_repos)
      end

      # Prints git status for all code repositories.
      # @param [Hash] options
      def git_repo_status_all_code(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_status(:code_repos)
      end

      # Prints git status for all content repositories.
      # @param [Hash] options
      def git_repo_status_all_content(options)
        RepositorySet.new(Repositext::PARENT_DIR).git_status(:all_content_repos)
      end

      # Updates RubyGems in all code and content repos
      def git_repo_update_all_rubygems(options)
        RepositorySet.new(Repositext::PARENT_DIR).update_all_rubygems
      end

      # Runs `rt validate content` on all content repos
      def git_repo_validate_all_content(options)
        RepositorySet.new(Repositext::PARENT_DIR).validate_content(
          :all_content_repos,
          content_type
        )
      end

    end
  end
end
