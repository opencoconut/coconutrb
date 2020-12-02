require "http"

module Coconut
  # Coconut::API is responsible for making API requests.
  # It takes a Coconut::Client to send api_key, endpoint and region.
  class API
    def self.headers(cli)
      if cli.api_key.nil?
        raise Coconut::Error, "You must specify an API key with Coconut.api_key="
      end

      HTTP.basic_auth(user: cli.api_key, pass: "").
        headers(:user_agent => "Coconut/v2 RubyBindings/#{Coconut::VERSION}")
    end

    def self.request(verb, path, options={})
      cli = options[:client] || Coconut.default_client

      case verb
      when :get
        resp = headers(cli).get("#{cli.endpoint}#{path}")
      when :post
        resp = headers(cli).post("#{cli.endpoint}#{path}", json: options[:json])
      end

      if resp.code > 399
        # if response is 400 or 401, we return the error message and error code
        if resp.code.between?(400, 401)
          raise Coconut::Error, "#{resp.parse["message"]} (code=#{resp.parse["error_code"]})"
        else
          raise Coconut::Error, "Server returned HTTP status #{resp.code}."
        end
      end

      return resp.parse
    end
  end
end