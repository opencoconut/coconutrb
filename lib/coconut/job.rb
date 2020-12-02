module Coconut
  class Job < API
    attr_reader :id, :created_at, :completed_at, :status, :progress, :errors, :output_urls

    def initialize(attrs={})
      @id = attrs["id"]
      @created_at = attrs["created_at"]
      @completed_at = attrs["completed_at"]
      @status = attrs["status"]
      @progress = attrs["progress"]
      @errors = attrs["errors"]
      @output_urls = attrs["output_urls"]
    end

    def self.retrieve(job_id, options={})
      resp = API.request(:get, "/jobs/#{job_id}", options)
      return Job.new(resp)
    end

    def self.create(job, options={})
      resp = API.request(:post, "/jobs", options.merge({
        json: apply_settings(job)
      }))

      return Job.new(resp)
    end

    def self.apply_settings(job)
      if url = Coconut.webhook_url
        job[:webhook] ||= {}
        job[:webhook][:url] = url
      end

      if storage = Coconut.storage
        job[:storage] ||= {}
        job[:storage].merge!(storage)
      end

      return job
    end
  end
end