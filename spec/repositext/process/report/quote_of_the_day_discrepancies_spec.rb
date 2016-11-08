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
              "removes surrounding <p> tags",
              "<p>word <p>word</p>",
              "word <p>word",
            ],
            [
              "replaces html entities",
              "&ldquo; &rdquo; &lsquo; &rsquo; &hellip; &nbsp; &mdash;",
              "“ ” ‘ ’ …   —",
            ],
            [
              "removes <em> tags",
              "word <em>word</em> word",
              "word word word",
            ],
            [
              "replaces <br /> tag with newline",
              "word<br />word",
              "word\nword",
            ],
            [
              "removes leading elipsis",
              "…word word",
              "word word",
            ],
            [
              "removes trailing elipsis",
              "word word…",
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
              "@word word",
              "@word word",
            ],
            [
              "removes paragraph numbers",
              "123 word word",
              "word word",
            ],
            [
              "removes paragraph numbers with subtitle marks",
              "@123 word word",
              "@word word",
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
              "word1 word2 word3 word4",
              "word1 word3 word2 word4",
              [
                {
                  :qotd_content=>"word1 word\e[30m\e[41m2\e[0m word\e[30m\e[41m3\e[0m word4",
                  :content_at_content=>"word1 word\e[30m\e[42m3\e[0m word\e[30m\e[42m2\e[0m word4",
                  :diff_tokens=>["2", "3"],
                }
              ]
            ],
            [
              "ignores isolated insertion at beginning of qotd",
                      "word2 word3 word4",
              "@word1 @word2 word3 word4",
              [],
            ],
            [
              "ignores isolated insertion at end of qotd",
              "word1 word2 word3",
              "word1 word2 word3 @word4",
              [],
            ],
            [
              "captures connected insertion at end of qotd",
              "word1 word2",
              "word1 abcx",
              [
                {
                  :qotd_content=>"word1 \e[30m\e[41mword2\e[0m",
                  :content_at_content=>"word1 \e[30m\e[42mabcx\e[0m",
                  :diff_tokens=>["2", "a", "b", "c", "d", "o", "r", "w", "x"],
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
              ['', '', []],
            ],
            [
              "handles insert",
              "word1 word2 word2b word3",
              "word1 word2 word3",
              [
                "word1 word2 word\e[30m\e[41m2b word\e[0m3",
                "word1 word2 word3",
                [" ", "2", "b", "d", "o", "r", "w"],
              ],
            ],
            [
              "handles delete",
              "word1 word2 word3",
              "word1 word2",
              [
                "word1 word2\e[30m\e[41m word3\e[0m",
                "word1 word2",
                [" ", "3", "d", "o", "r", "w"],
              ],
            ],
            [
              "handles insert and delete",
              "word1 word1b word2 word3 word4",
              "word1 word2 word3 word3b word4",
              [
                "word1 word\e[30m\e[41m1b\e[0m word\e[30m\e[41m2\e[0m word3 word4",
                "word1 word\e[30m\e[42m2\e[0m word\e[30m\e[42m3\e[0m word3\e[30m\e[42mb\e[0m word4",
                ["1", "2", "3", "b"],
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

        describe "#assign_discrepancy_types" do
          language = Language::English.new
          style_tokens = [
            language.chars[:d_quote_open],
            language.chars[:d_quote_close],
            language.chars[:s_quote_open],
            language.chars[:s_quote_close],
            '"',
            "'",
            "…",
            "...",
            "--",
            "—",
          ]
          [
            [
              "handles all style tokens",
              style_tokens,
              :style,
            ],
            [
              "handles single non-style token",
              style_tokens + ['a'],
              :content,
            ],
            [
              "handles subtitle token",
              ['@'],
              :subtitle,
            ],
          ].each do |desc, diff_tokens, xpect|
            it desc do
              r = { diff_tokens: diff_tokens }
              report.send(
                :assign_discrepancy_types,
                [r]
              )
              r[:type].must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
