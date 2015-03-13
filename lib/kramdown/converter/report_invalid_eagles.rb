# Returns a list of eagles that are in an invalid position, or that are missing.
module Kramdown
  module Converter

    # Returns report of any of the following issues:
    # * No eagle at the beginning of the second record.
    # * No eagle at the end of the last record (before id page if it exists).
    # * Eagle in any record other than the second or last.
    # Allows exemption of records from the above rules.
    # NOTE: Expects id page to be removed before parsing kramdown document.
    class ReportInvalidEagles < Base

      # Instantiate converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @current_record_number = 0
        @records_with_eagles = {}
        @second_record_id = nil
        @last_record_id = nil
      end

      # @param[Kramdown::Element] el
      # @return[Array] all invalid eagles:
      # [
      #   { record_id: 123, issue: :starting_eagle_missing },
      #   { record_id: 123, issue: :starting_eagle_in_unexpected_location },
      #   { record_id: 124, issue: :unexpected_eagle },
      #   { record_id: 125, issue: :ending_eagle_missing },
      #   { record_id: 125, issue: :ending_eagle_in_unexpected_location },
      # ]
      def convert(el)
        if :record_mark == el.type
          @current_record_number += 1
          record_id = el.attr['id']
          plain_text = el.to_plain_text.strip
          @second_record_id = record_id  if 2 == @current_record_number
          @last_record_id = record_id
          if (idx = plain_text.index(''))
            eagle_pos = case
            when plain_text =~ /\A/
              :first
            when plain_text =~ /\z/
              :last
            else
              "#{ idx } of #{ plain_text.length }"
            end
            @records_with_eagles[@current_record_number] ||= {
              record_number: @current_record_number,
              record_id: record_id,
              eagle_position: eagle_pos
            }
          else
            # no eagle, nothing to record
          end
        end

        # walk the tree
        el.children.each { |e| convert(e) }

        if :root == el.type
          return check_for_invalid_eagles(
            @records_with_eagles,
            @current_record_number,
            @second_record_id,
            @last_record_id
          )
        end
      end

    protected

      # Finds any invalid eagles and returns array with issue details
      # @param records_with_eagles [Hash] with record numbers as keys
      #   {
      #     2 => { record_number: 2, record_id: 123, eagle_position: :first },
      #   }
      # @param number_of_records [Integer] total number of records in document
      # @return [Array] see #convert
      def check_for_invalid_eagles(records_with_eagles, number_of_records, second_record_id, last_record_id)
        rwe = records_with_eagles.dup
        r = []
        if !(se = rwe.delete(2))
          r << { record_id: second_record_id, issue: :starting_eagle_missing }
        elsif :first != se[:eagle_position]
          r << { record_id: se[:record_id], issue: :starting_eagle_in_unexpected_location }
        end
        if !(ee = rwe.delete(number_of_records))
          r << { record_id: last_record_id, issue: :ending_eagle_missing }
        elsif :last != ee[:eagle_position]
          r << { record_id: ee[:record_id], issue: :ending_eagle_in_unexpected_location }
        end
        if rwe.any?
          r += rwe.map { |record_number, eagle_attrs|
            { record_id: eagle_attrs[:record_id], issue: :unexpected_eagle }
          }
        end
        r
      end

    end
  end
end

# Verify presence of eagles in correct places for all files:

# * Verify that second record in every file starts with eagle (except %@).
# * Verify that last record before id (or last record if no id present) ends with an eagle.

# Verify absence of eagles in incorrect places:

# * Find any records that are not the second record which contain an eagle.
# * Find any records that are not the last (before id) which contain an eagle

# Ability to exempt records from both rules:

# * based on file name and record_id `{ ‘eng63-0315’ => [‘’] }`
