require 'repositext/cli'
require_relative '../../helper'

describe Repositext::Cli::Utils do

  let(:mod) { Repositext::Cli::Utils }
  let(:in_cont) { 'Input file content'}
  let(:out_cont) { 'Output file content'}
  let(:in_file_pattern) { '/directory_1/*.in' }
  let(:in_file_filter) { /\.in\z/ }
  let(:in_file_names) { Dir.glob(in_file_pattern).dup }
  let(:desc) { '[description of operation, e.g., export_files]' }

  before do
    # Activate FakeFS
    FakeFS.activate!
    FileSystem.clear
    # Redirect console output for clean test logs
    # NOTE: use STDOUT.puts if you want to print something to the test output
    @stderr = $stderr = StringIO.new
    @stdout = $stdout = StringIO.new
  end

  after do
    FakeFS.deactivate!
  end

  describe 'File operation helper methods' do

    before do
      # Create test input files
      FileUtils.mkdir('/directory_1')
      %w[test1 test2].each { |e|
        File.open("/directory_1/#{ e }.in", 'w') { |f| f.write(in_cont) }
      }
    end

    describe '.change_files_in_place' do

      before do
        # Execute method under test
        mod.change_files_in_place(in_file_pattern, in_file_filter, desc) do |contents, filename|
          [Outcome.new(true, { :contents => out_cont, :extension => '_ignored' }, ['msg'])]
        end
      end

      it 'leaves existing files intact' do
        Dir.glob(in_file_pattern).must_equal in_file_names
      end

      it 'updates existing files with new content' do
        Dir.glob(in_file_pattern).each { |e| File.read(e).must_equal out_cont }
      end

      it 'does not create any new files' do
        Dir.glob('/directory_1/*').must_equal in_file_names
      end
    end

    describe '.convert_files' do

      let(:out_file_pattern) { '/directory_1/*.out' }

      before do
        # Execute method under test
        mod.convert_files(in_file_pattern, in_file_filter, desc) do |contents, filename|
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
        Dir.glob(out_file_pattern).each { |e| File.read(e).must_equal out_cont }
      end
    end

    describe '.export_files' do

      let(:out_dir) { '/directory2' }
      let(:out_file_pattern) { "#{ out_dir }/*.out" }

      before do
        # Execute method under test
        mod.export_files(in_file_pattern, out_dir, in_file_filter, desc) do |contents, filename|
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
        Dir.glob(out_file_pattern).each { |e| File.read(e).must_equal out_cont }
      end

    end

    describe '.dry_run_process' do

      let(:out_dir) { '/directory2' }

      it 'does not write any new files' do
        mod.dry_run_process(in_file_pattern, out_dir, in_file_filter, desc) do |contents, filename|
          [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
        end
        File.directory?(out_dir).must_equal false
        Dir.glob(in_file_pattern).must_equal in_file_names
      end

      it 'prints console output' do
        out, err = capture_io {
          mod.dry_run_process(in_file_pattern, out_dir, in_file_filter, desc) do |contents, filename|
            [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
          end
        }
        err.must_match /\n  - Skip writing/
      end
    end

    describe '.process_files' do

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
        out, err = capture_io { mod.process_files('', '', '', output_path_lambda) { '' } }
        err.must_match /Finished processing 0 of 0 files/
      end

      it "skips input files that don't match the file_filter" do
        in_file_filter = /test2/
        out, err = capture_io {
          mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
            [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
          end
        }
        err.must_match /\n - Skipping .*test1\.in/
      end

      it "creates new output files if they don't exist yet" do
        out, err = capture_io {
          mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
            [Outcome.new(true, { :contents => out_cont, :extension => 'out' }, ['msg'])]
          end
        }
        err.must_match /\n  \* Create: .*test1\.out/
      end

      it "updates output files that exist if new content is different" do
        # First create existing output files with old content
        old_content = 'Old content'
        new_content = 'New content'
        mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
          [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
        end
        out, err = capture_io {
          mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
            [Outcome.new(true, { :contents => new_content, :extension => 'out' }, ['msg'])]
          end
        }
        err.must_match /\n  \* Update: .*test1\.out/
      end

      it "leaves as is output files that exist if new content is same as existing" do
        # First create existing output files with old content
        old_content = 'Old content'
        new_content = 'New content'
        mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
          [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
        end
        out, err = capture_io {
          mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
            [Outcome.new(true, { :contents => old_content, :extension => 'out' }, ['msg'])]
          end
        }
        err.must_match /\n    Leave as is: .*test1\.out/
      end

      it "prints an error message if processing is not successful" do
        out, err = capture_io {
          mod.process_files(in_file_pattern, in_file_filter, desc, output_path_lambda) do |contents, filename|
            [Outcome.new(false, {}, ['msg'])]
          end
        }
        err.must_match /\n  x  Error:/
      end
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
