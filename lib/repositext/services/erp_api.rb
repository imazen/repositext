class Repositext
  class Services

    # This service connects to the ERP API
    #
    # Usage:
    #    Repositext::Services::ErpApi.call(:get_titles, { languageids: %w[eng] })
    class ErpApi

      def self.call(protocol_and_host, appid, nameguid, api_method_key, params)
        new(protocol_and_host, appid, nameguid, api_method_key, params).call
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
        case http_method
        when :get
          perform_get(api_path, @params)
        when :post
          perform_post(api_path, @params)
        else
          raise "Handle this: #{ http_method.inspect }"
        end
      end

      # @param api_path [String]
      # @param params [Hash]
      def perform_get(api_path, params)
        response = HTTParty.get(
          [@protocol_and_host, api_path].join,
          query: URI.encode_www_form(params),
          headers: {
            appid: @appid,
            nameguid: @nameguid,
          },
          timeout: 20,
          # debug_output: $stdout
        )
        response.parsed_response['data']
      end

      # @param api_path [String]
      # @param params [Hash]
      def perform_post(api_path, params)
        response = HTTParty.post(
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
        response.parsed_response['data']
      end

    end
  end
end
