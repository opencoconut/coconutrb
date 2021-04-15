module Coconut
  class Metadata
    def self.retrieve(job_id, options={})
      API.request(:get, "/metadata/jobs/#{job_id}/#{options.delete(:key)}", options)
    end
  end
end