require_relative '../../helper'

describe Repositext::Merge::AcceptedCorrectionsIntoContentAt do

  describe 'compute_first_para_num' do
    [
      ["\n*1*{: .pn}", '1'],
      ["\n*2*{: .pn}", '1'],
      ["\n@*3*{: .pn}", '2'],
      ["\n%*4*{: .pn}", '3'],
      ["\n@%*5*{: .pn}", '4'],
    ].each do |test_string, xpect|
      it "handles #{ test_string.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :compute_first_para_num, test_string
        ).must_equal(xpect)
      end
    end
  end

  describe 'compute_fuzzy_after_matches_count' do
    [
      [{ :after => 'word1 word2' }, 'word1x word2', 0],
      [{ :after => 'word1 word2' }, 'word1 word2', 1],
      [{ :after => 'word1 word2' }, 'word1 %word2', 1],
      [{ :after => '%word1 word2' }, 'word1 word2', 1],
      [{ :after => '%word1 %word2' }, 'word1 word2 @word1 %word2 %word1 @word2 @word1 @word2', 4],
    ].each do |correction, test_string, xpect|
      it "handles #{ correction.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :compute_fuzzy_after_matches_count, correction, test_string
        ).must_equal(xpect)
      end
    end
  end

  describe 'compute_line_number_from_paragraph_number' do
    [
      [3, "line 1\nline 2\nline 3\n*3*{: .pn} line 4", 4], # paragraph_number as integer
      ['3', "line 1\nline 2\nline 3\n*3*{: .pn} line 4", 4], # paragraph_number as string
      ['1', "line 1\nline 2\nline 3\n*1*{: .pn} line 4", 1], # first paragraph starts on line one
      ['3', "line 1\nline 2\nline 3\n@*3*{: .pn} line 4", 4], # paragraph_number with subtitle_mark
    ].each do |paragraph_number, test_string, xpect|
      it "handles #{ test_string.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :compute_line_number_from_paragraph_number, paragraph_number, test_string
        ).must_equal(xpect)
      end
    end
  end

  describe 'compute_merge_action' do
    [
      [
        :auto,
        { :before => 'word1 word2', :after => 'no match' },
        "before word1 word2 after",
        [:apply_automatically],
      ],
      [
        :auto,
        { :before => 'no match', :after => 'no match' },
        "before word1 word2 after",
        [:do_nothing],
      ],
      [
        :manual,
        { :before => 'no match', :after => 'word1 word2' },
        "before word1 word2 after",
        [:report_already_applied, 'Exact'],
      ],
      [
        :manual,
        { :before => 'no match', :after => '%word1 @word2' },
        "before word1 word2 after",
        [:report_already_applied, 'Fuzzy'],
      ],
      [
        :manual,
        { :before => 'no match', :after => 'no match' },
        "before word1 word2 after",
        [:apply_manually, :no_match_found],
      ],
      [
        :manual,
        { :before => 'word', :after => 'no match' },
        "before word1 word2 after",
        [:apply_manually, :multiple_matches_found],
      ],
    ].each do |strategy, correction, relevant_paragraphs, xpect|
      it "handles #{ correction.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :compute_merge_action, strategy, correction, relevant_paragraphs
        ).must_equal(xpect)
      end
    end
  end

  describe 'dynamic_paragraph_number_regex' do
    [
      [1, "line 1\n\n*2*{: .pn}\n\n*3*{: .pn}", /\A/], # first paragraph
      [2, "line 1\n\n*2*{: .pn}\n\n*3*{: .pn}", /\n[@%]{0,2}\*2\*\{\:\s\.pn\}/], # subsequent paragraph
    ].each do |paragraph_number, test_string, xpect|
      it "handles #{ test_string.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :dynamic_paragraph_number_regex, paragraph_number, test_string
        ).must_equal(xpect)
      end
    end
  end

  describe 'extract_corrections' do

    let(:corrections_to_extract){
      %(
1. Page 7, Paragraph 47, Line 4
Reads: word1 word2 word3 word4 word5
Becomes: word1 (word2) word3 word4 word5

2. Page 8, Paragraphs 54-57, Line 7
Reads: word1 word2 word3
Becomes: word1 word2modified word3

3. Page 27, Paragraph 177, Lines 6-7
Reads: word1 word2 word3
Becomes: word1 word2 word4added word3
      )
    }
    let(:corrections_attrs){
      [
        { correction_number: '1', paragraph_number: '47', line_number: '4', before: "word1 word2 word3 word4 word5", after: "word1 (word2) word3 word4 word5" },
        { correction_number: '2', paragraph_number: '54', line_number: '7', before: "word1 word2 word3", after: "word1 word2modified word3" },
        { correction_number: '3', paragraph_number: '177', line_number: '6-7', before: "word1 word2 word3", after: "word1 word2 word4added word3" },
      ]
    }

    it "extracts corrections" do
      Repositext::Merge::AcceptedCorrectionsIntoContentAt.extract_corrections(
        corrections_to_extract
      ).must_equal(corrections_attrs)
    end

  end

  describe 'extract_relevant_paragraphs' do
    [
      [
        "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
        { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
        "\n*2*{: .pn} second paragraph\n"
      ],
      [
        "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
        { paragraph_number: '2', after: "some text\n\n*2*{: .pn} with one pararaph number" },
        "\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph "
      ],
      [
        "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n\n*4*{: .pn} fourth paragraph",
        { paragraph_number: '2', after: "some text\n\n*2*{: .pn} with one pararaph number" },
        "\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n"
      ],
      [
        "# Header\n\nFirst paragraph without a number\n\n@*2*{: .pn} second paragraph with subtitle_mark\n\n*3*{: .pn} third paragraph \n\n",
        { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
        "\n@*2*{: .pn} second paragraph with subtitle_mark\n"
      ],
      [
        "# Header\n\nFirst paragraph without a number\n\n%*2*{: .pn} second paragraph with gap_mark\n\n*3*{: .pn} third paragraph \n\n",
        { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
        "\n%*2*{: .pn} second paragraph with gap_mark\n"
      ],
      [
        "# Header\n\nFirst paragraph without a number\n\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n\n*3*{: .pn} third paragraph \n\n",
        { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
        "\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n"
      ],
    ].each do |txt, correction, xpect|
      it "handles #{ txt.inspect }" do
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :extract_relevant_paragraphs, txt, correction
        ).must_equal(xpect)
      end
    end
  end

  describe 'merge_auto' do
    # NOTE: Integration method, no test
  end

  describe 'merge_corrections_into_content_at' do
    # NOTE: Integration method, no test
  end

  describe 'merge_manually' do
    # NOTE: Integration method, no test
  end

  describe 'open_in_sublime' do
    # NOTE: Integration method, no test
  end

  describe 'replace_perfect_match!' do

    let(:corrected_at){
      [
        '# Header',
        'First paragraph without a number',
        '*2*{: .pn} second paragraph',
        '@*3*{: .pn} third paragraph ',
        '',
      ].join("\n\n")
    }

    [
      [
        {
          paragraph_number: '2',
          before: 'second paragraph',
          after: 'second paragraph added',
        },
        "\n*2*{: .pn} second paragraph\n",
        [
          '# Header',
          'First paragraph without a number',
          '*2*{: .pn} second paragraph added',
          '@*3*{: .pn} third paragraph ',
          '',
        ].join("\n\n")
      ], # regular case
      [
        {
          paragraph_number: '3',
          before: 'third paragraph',
          after: 'third paragraph added',
        },
        "\n@*3*{: .pn} third paragraph ",
        [
          '# Header',
          'First paragraph without a number',
          '*2*{: .pn} second paragraph',
          '@*3*{: .pn} third paragraph added ',
          '',
        ].join("\n\n")
      ], # paragraph is preceded with subtitle_mark
    ].each do |correction, relevant_paragraphs, xpect|
      it "handles #{ correction.inspect }" do
        report_lines = []
        Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
          :replace_perfect_match!, correction, corrected_at, relevant_paragraphs, report_lines
        )
        corrected_at.must_equal(xpect)
      end
    end
  end

  describe 'manually_edit_correction!' do
    # NOTE: Integration method, no test
  end

  describe 'validate_accepted_corrections_file' do
    [
      ['valid file', false],
      ['valid file with straight double quote inside IAL ^^^ {: .rid #rid-65040039 kpn="003"}', false],
      ['invalid file with EN DASH: –', true],
      ['invalid file with straight double quote: "', true],
      ['invalid file with straight single quote: \'', true],
    ].each do |test_string, xpect_exception|
      it "handles #{ test_string.inspect }" do
        if xpect_exception
          lambda {
            Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
              :validate_accepted_corrections_file, test_string
            )
          }.must_raise Repositext::Merge::AcceptedCorrectionsIntoContentAt::InvalidAcceptedCorrectionsFile
        else
          # Call method and expect it not to raise an exception
          Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
            :validate_accepted_corrections_file, test_string
          )
          1.must_equal 1
        end
      end
    end
  end

  describe 'validate_corrections' do
    [
      [
        [{}],
        Repositext::Merge::AcceptedCorrectionsIntoContentAt::InvalidCorrectionAttributes,
      ],
      [
        [{ :correction_number => 'value', :paragraph_number => 'value', :line_number => 'value', :before => 'value', :after => 'value' }],
        nil,
      ],
      [
        [
          { :correction_number => '1', :paragraph_number => 'v', :line_number => 'v', :before => 'v', :after => 'v' },
          { :correction_number => '2', :paragraph_number => 'v', :line_number => 'v', :before => 'v', :after => 'v' },
        ],
        nil,
      ],
      [
        [
          { :correction_number => '1', :paragraph_number => 'v', :line_number => 'v', :before => 'v', :after => 'v' },
          { :correction_number => '3', :paragraph_number => 'v', :line_number => 'v', :before => 'v', :after => 'v' },
        ],
        Repositext::Merge::AcceptedCorrectionsIntoContentAt::InvalidCorrectionNumber,
      ],
    ].each do |corrections, xpected_exception|
      it "handles #{ corrections.inspect }" do
        if xpected_exception
          lambda {
            Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
              :validate_corrections, corrections
            )
          }.must_raise xpected_exception
        else
          # Call method and expect it not to raise an exception
          Repositext::Merge::AcceptedCorrectionsIntoContentAt.send(
            :validate_corrections, corrections
          )
          1.must_equal 1
        end
      end
    end
  end

end


