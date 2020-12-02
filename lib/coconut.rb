require "coconut/api"
require "coconut/error"
require "coconut/client"
require "coconut/job"
require "coconut/metadata"
require "coconut/version"

module Coconut
  ENDPOINT = "https://api.coconut.co/v2"

  def self.api_key=(key)
    @api_key = key
  end

  def self.api_key
    @api_key
  end

  def self.region=(region)
    @region = region
  end

  def self.region
    @region
  end

  def self.endpoint=(endpoint)
    @endpoint = endpoint
  end

  def self.endpoint
    @endpoint
  end

  def self.webhook_url=(url)
    @webhook_url = url
  end

  def self.webhook_url
    @webhook_url
  end

  def self.storage=(storage)
    @storage = storage
  end

  def self.storage
    @storage
  end
end