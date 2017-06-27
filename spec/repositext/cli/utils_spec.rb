require_relative '../../helper'

class Repositext
  class Cli
    describe Utils do

      let(:mod) { Utils }

      describe 'File operation helper methods' do

        let(:in_cont) { 'Input file content' }
        let(:out_cont) { 'Output file content'}
        let(:in_file_pattern) { '/directory_1/*.in' }
        let(:in_file_filter) { /\.in\z/ }
        let(:in_file_names) { Dir.glob(in_file_pattern).dup }
        let(:desc) { '[description of operation, e.g., export_files]' }

        before do
          # Activate FakeFS
          FakeFS.activate!
          FakeFS::FileSystem.clear
          # Redirect console output for clean test logs
          # NOTE: use STDOUT.puts if you want to print something to the test output
          @stderr = $stderr = StringIO.new
          @stdout = $stdout = StringIO.new

          # Create test input files
          FileUtils.mkdir('/directory_1')
          %w[test1 test2].each { |e|
            File.open("/directory_1/#{ e }.in", 'w') { |f| f.write(in_cont) }
          }
        end

        after do
          FakeFS.deactivate!
          FakeFS::FileSystem.clear
        end

        describe '.change_files_in_place' do

          before do
            # Execute method under test
            mod.change_files_in_place(in_file_pattern, in_file_filter, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => out_cont, :extension => '_ignored' }, ['msg'])]
            end
          end

          it 'leaves existing files intact' do
            Dir.glob(in_file_pattern).must_equal in_file_names
          end

          it 'updates existing files with new content' do
            Dir.glob(in_file_pattern).all? { |e| File.read(e) == out_cont }.must_equal true
          end

          it 'does not create any new files' do
            Dir.glob('/directory_1/*').must_equal in_file_names
          end
        end

        describe '.convert_files' do

          let(:out_file_pattern) { '/directory_1/*.out' }

          before do
            # Execute method under test
            mod.convert_files(in_file_pattern, in_file_filter, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
            end
          end

          it 'leaves existing files intact' do
            Dir.glob(in_file_pattern).must_equal in_file_names
          end

          it 'creates one new file for each input file' do
            Dir.glob(out_file_pattern).size.must_equal in_file_names.size
          end

          it 'new files contain updated content' do
            Dir.glob(out_file_pattern).all? { |e| File.read(e) == out_cont }.must_equal true
          end
        end

        describe '.export_files' do

          let(:out_dir) { '/directory_2/' }
          let(:out_file_pattern) { "#{ out_dir }*.out" }
          let(:input_base_dir) { '/directory_1/' }
          let(:input_file_selector) { '**/*' }
          let(:input_file_extension) { '*.in' } # This contains only the portion after base_dir

          before do
            # Prepare output dir
            FileUtils.mkdir('/directory_2')
            # Execute method under test
            mod.export_files(input_base_dir, input_file_selector, input_file_extension, out_dir, in_file_filter, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
            end
          end

          it 'leaves existing files intact' do
            Dir.glob(in_file_pattern).must_equal in_file_names
          end

          it 'creates one new file for each input file in another directory' do
            Dir.glob(out_file_pattern).size.must_equal in_file_names.size
          end

          it 'new files contain updated content' do
            Dir.glob(out_file_pattern).all? { |e| File.read(e) == out_cont }.must_equal true
          end

        end

        describe '.move_files' do

          let(:out_dir) { '/directory_2/' }
          let(:out_file_pattern) { "#{ out_dir }*.in" } # extension is .in since we're just moving
          let(:input_base_dir) { '/directory_1/' }
          let(:input_file_selector) { '**/*' }
          let(:input_file_extension) { '*.in' } # This contains only the portion after base_dir

          before do
            # Count number of input files before we delete them
            @in_file_count = in_file_names.size
            # Prepare output dir
            FileUtils.mkdir('/directory_2')
            # Execute method under test
            mod.move_files(input_base_dir, input_file_selector, input_file_extension, out_dir, in_file_filter, desc, {})
          end

          it 'removes existing files' do
            Dir.glob(in_file_pattern).must_equal []
          end

          it 'creates one new file for each input file in another directory' do
            Dir.glob(out_file_pattern).size.must_equal @in_file_count
          end

          it 'new files contain original content' do
            Dir.glob(out_file_pattern).all? { |e| File.read(e) == in_cont }.must_equal true
          end

        end

        describe '.dry_run_process' do

          let(:out_dir) { '/directory_2/' }

          it 'does not write any new files' do
            mod.dry_run_process(in_file_pattern, in_file_filter, out_dir, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
            end
            File.directory?(out_dir).must_equal false
            Dir.glob(in_file_pattern).must_equal in_file_names
          end

          it 'prints console output' do
            out, err = capture_io {
              mod.dry_run_process(in_file_pattern, out_dir, in_file_filter, desc, {}) do |contents, filename|
                [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
              end
            }
            err.must_match /\n - Skipping/
          end
        end

        describe '.process_files_helper' do

          let(:out_dir) { '/directory_2' }
          let(:out_file_pattern) { "#{ out_dir }/*.out" }
          let(:output_path_lambda) {
            lambda do |input_filename, output_file_attrs|
              File.join(
                out_dir,
                File.basename(input_filename, File.extname(input_filename)) + "." + output_file_attrs[:extension]
              )
            end
          }

          it 'Processes empty file set' do
            out, err = capture_io {
              mod.process_files_helper('', '', output_path_lambda, '', {}) { '' }
            }
            err.must_match /Finished processing 0 of 0 files/
          end

          it "skips input files that don't match the file_filter" do
            in_file_filter = /test2/
            out, err = capture_io {
              mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
                [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
              end
            }
            err.must_match /\n - Skipping .*test1\.in/
          end

          it "creates new output files if they don't exist yet" do
            out, err = capture_io {
              mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
                [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
              end
            }
            err.must_match /\n  \* Create: .*test1\.out/
          end

          it "updates output files that exist if new content is different" do
            # First create existing output files with old content
            old_content = 'Old content'
            new_content = 'New content'
            mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
            end
            out, err = capture_io {
              mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
                [Outcome.new(true, { :contents => new_content, :extension => 'out' }, ['msg'])]
              end
            }
            err.must_match /\n  \* Update: .*test1\.out/
          end

          it "leaves as is output files that exist if new content is same as existing" do
            # First create existing output files with old content
            old_content = 'Old content'
            new_content = 'New content'
            mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
              [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
            end
            out, err = capture_io {
              mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
                [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
              end
            }
            err.must_match /\n    Leave as is: .*test1\.out/
          end

          it "prints an error message if processing is not successful" do
            out, err = capture_io {
              mod.process_files_helper(in_file_pattern, in_file_filter, output_path_lambda, desc, {}) do |contents, filename|
                [Outcome.new(false, {}, ['msg'])]
              end
            }
            err.must_match(/  x  Error:/)
          end
        end

        describe '.replace_file_extension' do
          [
            ['filename1.ext1', 'ext2', 'filename1.ext2'],
            ['/path1/path2/filename2.ext1', 'ext2', '/path1/path2/filename2.ext2'],
            ['filename3', 'ext1', 'filename3.ext1'],
            ['filename4.ext1.ext2', 'ext3', 'filename4.ext1.ext3'],
            ['filename5.ext1', '.ext_with_dot', 'filename5.ext_with_dot'],
            ['filename6.', 'ext1', 'filename6.ext1'],
          ].each_with_index do |(filename, new_extension, xpect), idx|
            it "Handles scenario #{ idx + 1 }" do
              mod.replace_file_extension(filename, new_extension).must_equal xpect
            end
          end
        end

        describe '.write_file_unless_path_is_blank' do

          it "doesn't write a file if file_path is blank" do
            mod.write_file_unless_path_is_blank('', 'test').must_equal false
          end

          it "writes a file if file_path is not blank" do
            file_path = '/test.txt'
            file_contents = "test string #{ rand(1000) }"
            mod.write_file_unless_path_is_blank(file_path, file_contents)
            File.read(file_path).must_equal file_contents
          end
          # TODO: test what happens if path doesn't exist

          it "returns number of bytes written" do
            file_path = '/test.txt'
            file_contents = "test string #{ rand(1000) }"
            mod.write_file_unless_path_is_blank(file_path, file_contents).must_equal file_contents.size
          end
        end

      end

      describe '.compute_list_of_changed_files' do

        let(:dir_with_test_data) { get_test_data_path_for('repositext/cli/utils/compute_list_of_changed_files') }

        before do
          # Clean up any modifications in test data dir
          `git reset HEAD -- #{ dir_with_test_data }` # reset first to unstage any staged changes
          `git checkout -- #{ dir_with_test_data }` # remove modifications in working tree
          `git clean -d --force -- #{ dir_with_test_data }` # remove new/untracked files and dirs from working tree
        end

        after do
          # Clean up any modifications in test data dir
          `git reset HEAD -- #{ dir_with_test_data }` # reset first to unstage any staged changes
          `git checkout -- #{ dir_with_test_data }` # remove modifications in working tree
          `git clean -d --force -- #{ dir_with_test_data }` # remove new/untracked files and dirs from working tree
        end

        it 'returns nil if given false' do
          mod.compute_list_of_changed_files(false).must_equal nil
        end

        describe 'if given true' do

          it 'detects modified staged files' do
            modified_staged_file_path = File.join(dir_with_test_data, 'modified_staged_file.md')
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal []
            File.write(modified_staged_file_path, "#{ rand(1000) }")
            `git add #{ modified_staged_file_path }` # stage the file
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal [modified_staged_file_path]
          end

          it 'detects modified unstaged files' do
            modified_unstaged_file_path = File.join(dir_with_test_data, 'modified_unstaged_file.md')
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal []
            File.write(modified_unstaged_file_path, "#{ rand(1000) }")
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal [modified_unstaged_file_path]
          end

          it 'detects new staged files' do
            new_staged_file_path = File.join(dir_with_test_data, 'new_staged_file.md')
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal []
            File.write(new_staged_file_path, "#{ rand(1000) }")
            `git add #{ new_staged_file_path }` # stage the file
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal [new_staged_file_path]
          end

          it 'detects new unstaged files' do
            new_unstaged_file_path = File.join(dir_with_test_data, 'new_unstaged_file.md')
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal []
            File.write(new_unstaged_file_path, "#{ rand(1000) }")
            mod.compute_list_of_changed_files(true, dir_with_test_data).must_equal [new_unstaged_file_path]
          end

          # it 'does not detect deleted staged files' do
          # end

          # it 'does not detect deleted unstaged files' do
          # end

          # it 'detects all files when in a sub-directory' do
          # end

        end

      end

    end
  end
end
