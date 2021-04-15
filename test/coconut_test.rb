$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), "..", "lib"))

require "test/unit"
require "coconut"

class CoconutTest < Test::Unit::TestCase
  INPUT_URL = "https://s3-eu-west-1.amazonaws.com/files.coconut.co/bbb_800k.mp4"

  def setup
    Coconut.api_key = ENV["COCONUT_API_KEY"]
    Coconut.endpoint = ENV["COCONUT_ENDPOINT"]

    Coconut.storage = {
      service: "s3",
      region: ENV["AWS_REGION"],
      credentials: { access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"] },
      bucket: ENV["AWS_BUCKET"],
      path: "/coconutrb/tests/"
    }

    Coconut.notification = {
      type: "http",
      url: ENV["COCONUT_WEBHOOK_URL"]
    }
  end

  def create_job(j={}, options={})
    Coconut::Job.create({
      input: { url: INPUT_URL },
      outputs: {
        mp4: { path: "/test_create_job.mp4", duration: 1 }
      }
    }.merge(j), options)
  end

  def test_coconut_api_key
    Coconut.api_key = "apikey"
    assert "apikey", Coconut.api_key
  end

  def test_coconut_region
    Coconut.region = "us-east-1"
    assert "us-east-1", Coconut.region
  end

  def test_coconut_default_endpoint
    assert "https://api.coconut.co/v2", Coconut.endpoint
  end

  def test_coconut_endpoint_by_region
    Coconut.region = "us-west-2"
    assert "https://api-us-west-2.coconut.co/v2", Coconut.endpoint
  end

  def test_overwrite_endpoint
    myendpoint = "https://coconut-private/v2"
    Coconut.endpoint = myendpoint

    assert myendpoint, Coconut.endpoint
  end

  def test_create_job
    job = create_job
    assert job.is_a?(Coconut::Job)
    assert_not_nil job.id
    assert_equal "job.starting", job.status
  end

  def test_retrieve_job
    job = Coconut::Job.retrieve(create_job.id)
    assert job.is_a?(Coconut::Job)
    assert_not_nil job.id
    assert_equal "job.starting", job.status
  end

  def test_create_job_error
    create_job(input: {url: "notvalidurl"})
  rescue => e
    assert_equal e.class, Coconut::Error
  end

  def test_retrieve_metadata
    job = create_job
    sleep 10

    md = Coconut::Metadata.retrieve(job.id)
    assert md.is_a?(Hash)
    assert_not_nil md["metadata"]["input"]
  end
end