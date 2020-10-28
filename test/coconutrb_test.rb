require "test/unit"
require "rubygems"
require_relative File.join(File.dirname(__FILE__), "..", "..", "lib/coconutrb")

if ENV["COCONUT_API_KEY"].nil?
  puts "You must set your API KEY via the environment variable 'COCONUT_API_KEY' to run this test."
  puts "COCONUT_API_KEY=k-your-api-key ruby #{__FILE__}"
  exit 1
end

class CoconutTest < Test::Unit::TestCase
  def test_submit_job
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook",
      :outputs => {:mp4 => "s3://a:s@bucket/video.mp4"}
    )

    job = Coconut.submit(conf)
    assert_equal("processing", job["status"])
    assert(job["id"] > 0)
  end

  def test_submit_bad_config_should_raise
    conf = Coconut.config(
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )

    assert_raise(Coconut::Error) {
      Coconut.submit!(conf)
    }
  end

  def test_submit_config_with_api_key
    conf = Coconut.config(
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )

    job = Coconut.submit(conf, "k-4d204a7fd1fc67fc00e87d3c326d9b75")
    assert_equal("Authentication failed, check your API key", job["error"])
    assert_equal("authentication_failed", job["error_code"])
  end

  def test_submit_bad_config_should_not_raise
    conf = Coconut.config(
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )

    job = Coconut.submit(conf)
    assert_equal("400", job['status'])
    assert_equal("The config file must specify the `source' video location, a `webhook` URL and at least 1 output", job["error"])
    assert_equal("config_not_valid", job["error_code"])
  end

  def test_generate_full_config_with_no_file
    config = Coconut.config({
      :vars => {
        :vid => 1234,
        :user => 5098,
        :s3 => "s3://a:s@bucket"
      },
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook?vid=$vid&user=$user",
      :outputs => {
        "mp4" => "$s3/vid.mp4",
        "jpg_200x" => "$s3/thumb.jpg",
        "webm" => "$s3/vid.webm"
      }
    })

    generated = [
      "var s3 = s3://a:s@bucket",
      "var user = 5098",
      "var vid = 1234",
      "",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user",
      "",
      "-> jpg_200x = $s3/thumb.jpg",
      "-> mp4 = $s3/vid.mp4",
      "-> webm = $s3/vid.webm"
    ].join("\n")

    assert_equal(generated, config)
  end

  def test_generate_config_with_file
    File.open("coconut.conf", "w") {|f| f.write("var s3 = s3://a:s@bucket/video\nset webhook = http://mysite.com/webhook?vid=$vid&user=$user\n-> mp4 = $s3/$vid.mp4")}

    config = Coconut.config({
      :conf => "coconut.conf",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :vars => {:vid => 1234, :user => 5098}
    })

    generated = [
      "var s3 = s3://a:s@bucket/video",
      "var user = 5098",
      "var vid = 1234",
      "",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user",
      "",
      "-> mp4 = $s3/$vid.mp4",
    ].join("\n")

    assert_equal(generated, config)

    File.delete("coconut.conf")
  end

  def test_submit_file
    File.open("coconut.conf", "w") {|f| f.write("set webhook = http://mysite.com/webhook?vid=$vid&user=$user\n-> mp4 = s3://a:s@bucket/video/$vid.mp4")}

    job = Coconut::Job.create(
      :conf => "coconut.conf",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :vars => {:vid => 1234, :user => 5098}
    )
    assert_equal("processing", job["status"])
    assert(job["id"] > 0)

    File.delete("coconut.conf")
  end

  def test_set_api_key_in_job_options
    job = Coconut::Job.create(
      :api_key => "k-4d204a7fd1fc67fc00e87d3c326d9b75",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )
    assert_equal("401", job["status"])
    assert_equal("Authentication failed, check your API key", job["error"])
    assert_equal("authentication_failed", job["error_code"])
  end

  def test_get_job_info
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook",
      :outputs => {:mp4 => "s3://a:s@bucket/video.mp4"}
    )

    job = Coconut.submit(conf)

    info = Coconut::Job.get(job["id"])
    assert_equal(info["id"], job["id"])
  end

  def test_get_not_found_job_returns_nil
    job = Coconut::Job.get(1000)
    assert_equal('404', job['status'])
    assert_equal('compile error', job['error'])
  end

  def test_set_api_version
    config = Coconut.config({
      :api_version => "beta",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook?vid=$vid&user=$user",
      :outputs => {"mp4" => "$s3/vid.mp4"}
    })

    generated = [
      "",
      "set api_version = beta",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user",
      "",
      "-> mp4 = $s3/vid.mp4",
    ].join("\n")

    assert_equal(generated, config)
  end

  def test_get_all_metadata
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook",
      :outputs => {:mp4 => "s3://a:s@bucket/video.mp4"}
    )

    job = Coconut.submit(conf)
    sleep 4

    metadata = Coconut::Job.get_all_metadata(job["id"])
    assert_not_nil(metadata)
  end

  def test_get_metadata_for_source
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook",
      :outputs => {:mp4 => "s3://a:s@bucket/video.mp4"}
    )

    job = Coconut.submit(conf)
    sleep 4

    metadata = Coconut::Job.get_metadata_for(job["id"], :source)
    assert_not_nil(metadata)
  end

  def test_cdn_parameters_as_hash
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook",
      :outputs => {:"jpg:300x" => {:url => "s3://a:s@bucket/thumbs_#num#.jpg", :number => 10} }
    )

    generated = [
      "",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user",
      "",
      "-> jpg:300x = s3://a:s@bucket/thumbs_#num#.jpg, number=10"
    ].join("\n")
  end

  def test_webhook_parameters_as_hash
    conf = Coconut.config(
      :source  => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => {:url => "http://mysite.com/webhook", :metadata => true},
      :outputs => {:mp4 => "s3://a:s@bucket/video.mp4"}
    )

    generated = [
      "",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user, metadata=true",
      "",
      "-> mp4 = s3://a:s@bucket/video.mp4"
    ].join("\n")
  end
end