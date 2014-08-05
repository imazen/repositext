require_relative '../../helper'

describe Repositext::Utils::StringComparer do

  describe 'test cases' do

    [
      [
        'identical_strings',
        'identical_strings',
        []
      ],
      [
        'word word word word word word',
        'word word word added word word word',
        [[1, "added ", "line 0", "word word word word word word"]]
      ],
      [
        'word word word deleted word word word',
        'word word word word word word',
        [[-1, "deleted ", "line 0", "word word word deleted word word word"]]
      ],
      [
        'word word word xxxx word word word',
        'word word word yyyy word word word',
        [
          [-1, "xxxx", "line 0", "word word word xxxx word word word"],
          [1,  "yyyy", "line 0", "word word word xxxx word word word"]
        ]
      ],
      [
        "line1\nline2\nline3\nline4\nline5\nline6",
        "line1\nline2\nline3\nline4 added\nline5\nline6",
        [[1, " added", "line 4", "e1\nline2\nline3\nline4\nline5\nline6"]]
      ],
    ].each do |(string_1, string_2, xpect)|
      it "handles #{ string_1.inspect } -> #{ string_2.inspect }" do
        Repositext::Utils::StringComparer.compare(string_1, string_2).must_equal(xpect)
      end
    end
  end

end
