module Coconut
  def self.default_client
    Client.new({
      api_key: Coconut.api_key,
      region: Coconut.region,
      endpoint: Coconut.endpoint
    })
  end

  class Client
    attr_accessor :api_key, :endpoint, :region

    def initialize(options={})
      @api_key = options[:api_key]
      @region = options[:region]
      @endpoint = options[:endpoint]
    end

    def endpoint
      # if endpoint set, we return it
      if @endpoint
        return @endpoint
      end
      # if no endpoint but region is given, we
      # build the endpoint following https://api-region.coconut.co/v2
      if @region
        return "https://api-#{@region}.coconut.co/v2"
      end

      # by default:
      return Coconut::ENDPOINT
    end
  end
end