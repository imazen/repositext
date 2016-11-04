require_relative '../../../helper'

class Repositext
  class Process
    class Report
      describe QuoteOfTheDayDiscrepancies do

        let(:report){ QuoteOfTheDayDiscrepancies.new([], _, Language::English.new) }

        describe "#sanitize_qotd_content" do
          [
            [
              "doesn't change simple string",
              "word word",
              "word word",
            ],
            [
              "replaces three periods with elipsis",
              "word ...word",
              "word …word",
            ],
            [
              "replaces <br /> tag with newline",
              "word<br />word",
              "word\nword",
            ],
            [
              "replaces two spaces with newline",
              "word  word",
              "word\nword",
            ],
            [
              "replaces two hyphens with emdash",
              "word--word",
              "word—word",
            ],
            [
              "strips surrounding whitespace",
              " word word ",
              "word word",
            ],
          ].each do |desc, test_string, xpect|
            it desc do
              report.send(
                :sanitize_qotd_content,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe "#sanitize_content_at_plain_text" do
          [
            [
              "doesn't change simple string",
              "word word",
              "word word",
            ],
            [
              "replaces typographic double quotes with straight ones",
              "word “word” word",
              'word "word" word',
            ],
            [
              "replaces typographic single quotes with straight ones",
              "word ‘word’ word",
              "word 'word' word",
            ],
            [
              "removes paragraph numbers",
              "123 word word",
              "word word",
            ],
            [
              "strips surrounding whitespace",
              " word word ",
              "word word",
            ],
          ].each do |desc, test_string, xpect|
            it desc do
              report.send(
                :sanitize_content_at_plain_text,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe "#find_diffs_between_qotd_and_content_at" do
          [
            [
              "finds no diffs for identical strings",
              "word word",
              "word word",
              [],
            ],
            [
              "finds diff for different strings",
              "word1 word",
              "word word2",
              [
                {
                  :qotd_content=>"word\e[30m\e[41m1\e[0m word",
                  :content_at_content=>"word word\e[30m\e[42m2\e[0m"
                }
              ],
            ],
          ].each do |desc, qotd, content_at, xpect|
            it desc do
              coll = []
              report.send(
                :find_diffs_between_qotd_and_content_at,
                'date_code',
                'posting_date_time',
                qotd,
                content_at,
                coll
              )
              coll.must_equal(
                xpect.map { |e|
                  e.merge(
                    {
                      date_code: 'date_code',
                      posting_date_time: 'posting_date_time'
                    }
                  )
                }
              )
            end
          end
        end

        describe "#find_matching_content_at_fragment" do
          [
            [
              "finds perfect match",
              "word1 word2\nword3 word4\nword5 word6\nword7 word8",
              "word3 word4\nword5 word6",
              "word3 word4\nword5 word6",
            ],
          ].each do |desc, qotd, content_at, xpect|
            it desc do
              report.send(
                :find_matching_content_at_fragment,
                qotd,
                content_at
              ).must_equal(xpect)
            end
          end
        end

        describe "#compute_diffs" do
          [
            [
              "handles identical strings",
              "word3 word4\nword5 word6",
              "word3 word4\nword5 word6",
              ['', ''],
            ],
            [
              "handles insert",
              "word1 word2",
              "word1 word2 word3",
              ["word1 word2", "word1 word2\e[30m\e[42m word3\e[0m"],
            ],
            [
              "handles delete",
              "word1 word2 word3",
              "word1 word2",
              ["word1 word2\e[30m\e[41m word3\e[0m", "word1 word2"],
            ],
            [
              "handles insert and delete",
                    "word2 word3 word4",
              "word1 word2 word3",
              [
                "word\e[30m\e[41m2\e[0m word\e[30m\e[41m3\e[0m word\e[30m\e[41m4\e[0m",
                "word\e[30m\e[42m1\e[0m word\e[30m\e[42m2\e[0m word\e[30m\e[42m3\e[0m"
              ],
            ],
          ].each do |desc, qotd, content_at, xpect|
            it desc do
              report.send(
                :compute_diffs,
                qotd,
                content_at
              ).must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
