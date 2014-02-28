require 'repositext/cli'
require_relative '../../helper'

include FakeFS

describe Repositext::Cli::Utils do

  let(:mod) { Repositext::Cli::Utils }

  describe '.change_files_in_place' do
    it 'responds' do
      out = capture_subprocess_io { mod.change_files_in_place('', '', '') { '' } }.join
      out.must_match /Finished processing 0 of 0 files/
    end
    # TODO: flesh out specs
  end

  describe '.convert_files' do
    it 'responds' do
      out = capture_subprocess_io { mod.convert_files('', '', '') { '' } }.join
      out.must_match /Finished processing 0 of 0 files/
    end
    # TODO: flesh out specs
  end

  describe '.export_files' do
    it 'responds' do
      out = capture_subprocess_io { mod.export_files('', '', '', '') { '' } }.join
      out.must_match /Finished processing 0 of 0 files/
    end
    # TODO: flesh out specs
  end

    end

  describe '.process_files' do
    it 'responds' do
      out = capture_subprocess_io { mod.process_files('', '', '', '') { '' } }.join
      out.must_match /Finished processing 0 of 0 files/
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

    end
    # TODO: flesh out specs
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

    before do
      FakeFS.activate!
      FileSystem.clear
    end

    after do
      FakeFS.deactivate!
    end

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
