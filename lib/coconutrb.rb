require "net/http"
require "multi_json"
require "uri"

module Coconut
  class Error < RuntimeError; end

  COCONUT_URL = ENV["COCONUT_URL"] || "https://api.coconut.co"
  USER_AGENT = "Coconut/2.2.0 (Ruby)"

  API_KEY = ENV["COCONUT_API_KEY"] unless const_defined?(:COCONUT_API_KEY)

  def self.submit(config_content, api_key=nil)
    api_key ||= API_KEY
    uri = URI("#{COCONUT_URL}/v1/job")
    headers = {"User-Agent" => USER_AGENT, "Content-Type" => "text/plain", "Accept" => "application/json"}

    req = Net::HTTP::Post.new(uri.path, headers)
    req.basic_auth api_key, ''
    req.body = config_content

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme.include?("https")) do |http|
      http.request(req)
    end

    return MultiJson.decode(response.body)
  end

  def self.submit!(config_content, opts={})
    result = submit(config_content, opts)
    if result["status"] == "error"
      raise Error, "#{result["message"]} (#{result["error_code"]})"
    else
      return result
    end
  end

  def self.get(path, api_key=nil)
    api_key ||= API_KEY
    uri = URI("#{COCONUT_URL}#{path}")
    headers = {"User-Agent" => USER_AGENT, "Content-Type" => "text/plain", "Accept" => "application/json"}

    req = Net::HTTP::Get.new(uri.path, headers)
    req.basic_auth api_key, ''

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme.include?("https")) do |http|
      http.request(req)
    end

    if response.code.to_i != 200
      return nil
    else
      return MultiJson.decode(response.body)
    end
  end

  def self.config(options={})
    if conf_file = options[:conf]
      raise Error, "Config file `#{conf_file}' not found" if ! File.exists?(conf_file)
      conf = File.read(conf_file).strip.split("\n")
    else
      conf = []
    end

    if vars = options[:vars]
      vars.each do |name,value|
        conf << "var #{name} = #{value}"
      end
    end

    if source = options[:source]
      conf << "set source = #{source}"
    end

    if webhook = options[:webhook]
      conf << "set webhook = #{webhook}"
    end

    if api_version = options[:api_version]
      conf << "set api_version = #{api_version}"
    end

    if outputs = options[:outputs]
      outputs.each do |format, cdn|
        conf << "-> #{format} = #{cdn}"
      end
    end

    new_conf = []

    new_conf.concat conf.select{|l| l.start_with?("var")}.sort
    new_conf << ""
    new_conf.concat conf.select{|l| l.start_with?("set")}.sort
    new_conf << ""
    new_conf.concat conf.select{|l| l.start_with?("->")}.sort

    return new_conf.join("\n")
  end

  class Job
    def self.create(options={})
      Coconut.submit(Coconut.config(options), options[:api_key])
    end

    def self.get(jid, api_key=nil)
      Coconut.get("/v1/jobs/#{jid}", api_key)
    end

    def self.get_all_metadata(jid, api_key=nil)
      Coconut.get("/v1/metadata/jobs/#{jid}", api_key)
    end

    def self.get_metadata_for(jid, source_or_output, api_key=nil)
      Coconut.get("/v1/metadata/jobs/#{jid}/#{source_or_output}", api_key)
    end
  end
end