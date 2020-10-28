require "net/http"
require "multi_json"
require "uri"

module Coconut
  class Error < RuntimeError; end

  COCONUT_URL = ENV["COCONUT_URL"] || "https://api.coconut.co"
  USER_AGENT = "Coconut/2.4.0 (Ruby)"

  API_KEY = ENV["COCONUT_API_KEY"] unless const_defined?(:COCONUT_API_KEY)

  def self.submit(config_content, api_key=nil)
    api_key ||= API_KEY
    uri = URI("#{COCONUT_URL}/v1/job")
    post(uri.path, config_content, api_key)
  end

  def self.submit!(config_content, opts={})
    result = submit(config_content, opts)
    if (result.has_key?("error") && !result["error"].empty?) || unsuccessful_status(response['status_code'])
      raise Error, "#{result["message"]} (#{result["error_code"]})"
    else
      return result
    end
  end

  def self.unsuccessful_status(status)
    !status.between?(200, 299)
  end

  def self.get(path, api_key=nil)
    api_key ||= API_KEY
    uri = URI("#{COCONUT_URL}#{path}")
    req = Net::HTTP::Get.new(uri.path, default_headers)
    req.basic_auth(api_key, '')
    call(uri, req)
  end

  def self.default_headers 
    headers = {"User-Agent" => USER_AGENT, "Content-Type" => "text/plain", "Accept" => "application/json"}
  end 

  def self.post(path, config_content, api_key=nil)
    api_key ||= API_KEY
    uri = URI("#{COCONUT_URL}#{path}")
    req = Net::HTTP::Post.new(uri.path, default_headers)
    req.basic_auth(api_key, '')
    req.body = config_content
    call(uri, req)
  end

  def self.parse_response(response)
    response_code = response.code.to_i 
    begin 
      json = MultiJson.decode(response.body)
      not_successful_response = (json['status'] == "error" || !response_code.between?(200, 299))
      if not_successful_response
        {"status" => response.code, "error" => json["message"], 
          "error_code" => json["error_code"],
          "status_code" => response_code
        }
      else
        json.merge({"status_code" => response_code})
      end
    rescue => e 
      {"status" => response.code, "error" => e.to_s, "status_code" => response_code}
    end
  end

  def self.call(uri, req)
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme.include?("https")) do |http|
      http.request(req)
    end
    parse_response(response)
  end


  def self.config(options={})
    if options[:conf]
      raise Error, "Config file `#{options[:conf]}' not found" if !File.exists?(options[:conf])
      conf = File.read(options[:conf]).strip.split("\n")
    else
      conf = []
    end
      conf = add_vars_to_conf(options, conf)
      conf = add_source_to_conf(options, conf)
      conf = add_webhook_to_conf(options, conf)
      conf = add_api_version_to_conf(options, conf) 
      conf = add_outputs_to_conf(options, conf)
      conf = sort_conf(conf)
  end

  def self.sort_conf(conf)
    new_conf = []
    new_conf.concat conf.select{|l| l.start_with?("var")}.sort
    new_conf << ""
    new_conf.concat conf.select{|l| l.start_with?("set")}.sort
    new_conf << ""
    new_conf.concat conf.select{|l| l.start_with?("->")}.sort
    new_conf.join("\n")
  end

  def self.hash_params_to_string(params)
    params.map do |k,v|
      if k.to_s == "url"
        "#{v}"
      else
        "#{k}=#{v}"
      end
    end.join(", ")
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

  private 
    def self.add_vars_to_conf(options, conf)
      return conf if !options[:vars]
      vars = options[:vars]
      vars.each do |name,value|
        conf << "var #{name} = #{value}"
      end
      conf 
    end

    def self.add_source_to_conf(options, conf)
      return conf if !options[:source]
      if options[:source]
        conf << "set source = #{options[:source]}"
      end
      conf 
    end

    def self.add_webhook_to_conf(options, conf)
      return conf if !options[:webhook]
      webhook_copy = options[:webhook]
      if webhook_copy
        if webhook_copy.is_a?(Hash)
          webhook_copy = hash_params_to_string(webhook_copy)
        end
        conf << "set webhook = #{webhook_copy}"
      end
      conf
    end

    def self.add_api_version_to_conf(options, conf)
      return conf if !options[:api_version]
      if options[:api_version]
        conf << "set api_version = #{options[:api_version]}"
      end
      conf
    end

    def self.add_outputs_to_conf(options, conf)
      return conf if !options[:outputs]
      if options[:outputs]
        options[:outputs].each do |format, cdn|
          if cdn.is_a?(Hash)
            cdn = hash_params_to_string(cdn)
          end
          conf << "-> #{format} = #{cdn}"
        end
      end
      conf
    end
end