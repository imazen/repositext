class Repositext
  class Services

    # This service connects to the ERP API
    #
    # Usage:
    #    Repositext::Services::ErpApi.call(:get_titles, { languageids: %w[eng] })
    class ErpApi

      class ErpRequestError < StandardError; end;

      def self.call(protocol_and_host, appid, nameguid, api_method_key, params)
        new(protocol_and_host, appid, nameguid, api_method_key, params).call
      end

      # Validates ERP data:
      # * An entry exists for every product_identity_id requested.
      # * No duplicate entries exist for any product_identity_id.
      # @param erp_data [Hash]
      # @param requested_pi_ids [Array<Integer>]
      def self.validate_product_identity_ids(erp_data, requested_pi_ids)
        lc_dc_counts = Hash.new(0)
        erp_pi_ids = []
        erp_data.each { |e|
          key = [e['languageid'], e['productid']].join
          lc_dc_counts[key] += 1
          erp_pi_ids << e['productidentityid']
        }
        # Collect validation errors
        errors = []
        duplicate_lc_dcs = lc_dc_counts.find_all { |k,v| v > 1 }
        if duplicate_lc_dcs.any?
          errors << [
            "ERP Data contained duplicate entries for the following date codes: ",
            duplicate_lc_dcs.map(&:first).sort.join(', '),
          ].join
        end
        missing_pi_ids = requested_pi_ids - erp_pi_ids
        if missing_pi_ids.any?
          errors << [
            "ERP Data is missing data for the following product_identity_ids: ",
            missing_pi_ids.sort.join(', '),
          ].join
        end

        extra_pi_ids = erp_pi_ids - requested_pi_ids
        if extra_pi_ids.any?
          errors << [
            "ERP Data has extra data for the following product_identity_ids: ",
            extra_pi_ids.sort.join(', '),
          ].join
        end

        # Raise exception with all errors
        if errors.any?
          raise(["\n\n", errors.join("\n"), "\n"].join.color(:red))
        end
        true
      end

      # @param protocol_and_host [String]
      # @param api_method_key [Symbol] the API method to call
      # @param params [Hash]
      def initialize(protocol_and_host, appid, nameguid, api_method_key, params)
        @protocol_and_host = protocol_and_host
        @appid = appid
        @nameguid = nameguid
        @api_method_key = api_method_key
        @params = params
      end

      def api_methods
        {
          get_titles: [:get, "/path/to/get_titles"]
        }
      end

      # Returns ERP API response as Hash with symbolized keys.
      def call
        http_method, api_path = api_methods[@api_method_key]
        puts "Requesting ERP data from #{ api_path }"
        raw_response = case http_method
        when :get
          perform_get(api_path, @params)
        when :post
          perform_post(api_path, @params)
        else
          raise "Handle this: #{ http_method.inspect }"
        end
        parsed_response = raw_response.parsed_response
        handle_erp_errors(raw_response, parsed_response)
        puts " * Response code: #{ raw_response.code }"
        parsed_response['data']
      end

    private

      # @param api_path [String]
      # @param params [Hash]
      def perform_get(api_path, params)
        HTTParty.get(
          [@protocol_and_host, api_path].join,
          query: URI.encode_www_form(params),
          headers: {
            appid: @appid,
            nameguid: @nameguid,
          },
          timeout: 20,
          # debug_output: $stdout
        )
      end

      # @param api_path [String]
      # @param params [Hash]
      def perform_post(api_path, params)
        HTTParty.post(
          [@protocol_and_host, api_path].join,
          body: params.to_json,
          headers: {
            appid: @appid,
            nameguid: @nameguid,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
          },
          timeout: 20,
          debug_output: $stdout
        )
      end

      # @param raw_response [HTTParty::Response]
      # @param parsed_response [Hash {String => Object}]
      def handle_erp_errors(raw_response, parsed_response)
        if 200 != raw_response.code
          raise ErpRequestError.new([
            "\n\n",
            "Status ",
            raw_response.code,
            "\n",
            parsed_response['Message'],
            "\n",
            parsed_response['MessageDetail'],
            "\n",
          ].join.color(:red))
        end

        if(
          parsed_response.is_a?(Hash) &&
          (status = parsed_response['status']) &&
          200 != status
        )
          raise ErpRequestError.new([
            "\n\n",
            "Status ",
            status,
            ' ',
            parsed_response['status_text'],
            ":\n",
            parsed_response['data'],
            "\n",
          ].join.color(:red))
        end
        true
      end

    end
  end
end
