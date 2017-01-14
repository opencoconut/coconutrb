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
    assert_equal "ok", job["status"]
    assert job["id"] > 0
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
    assert_equal "error", job["status"]
    assert_equal "authentication_failed", job["error_code"]
  end

  def test_submit_bad_config_should_not_raise
    conf = Coconut.config(
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )

    job = Coconut.submit(conf)
    assert_equal "error", job["status"]
    assert_equal "config_not_valid", job["error_code"]
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

    assert_equal generated, config
  end

  def test_generate_config_with_no_file_and_multiple_same_typed_outputs
    base_conf = {
      :vars => {
        :vid => 1234,
        :user => 5098,
        :s3 => "s3://a:s@bucket"
      },
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :webhook => "http://mysite.com/webhook?vid=$vid&user=$user",
    }

    output_without_prefix =  { :outputs => {
      "hls" => "$s3/playlist.m3u8, variants=hls:240p,hls:360p",
    } }

    outputs_with_num_prefix =  { :outputs => {
      "2@hls" => "$s3/playlist.m3u8, variants=hls:480p,hls:720p, if=$source_height > 300",
      "1@hls" => "$s3/playlist.m3u8, variants=hls:240p,hls:360p, if=$source_height < 300",
    } }

    outputs_with_az_prefix =  { :outputs => {
      "cd@hls" => "$s3/playlist.m3u8, variants=hls:480p,hls:720p, if=$source_height > 300",
      "ad@hls" => "$s3/playlist.m3u8, variants=hls:240p,hls:360p, if=$source_height < 300",
    } }

    config_no_prefix = Coconut.config(base_conf.merge(output_without_prefix))
    config_num = Coconut.config(base_conf.merge(outputs_with_num_prefix))
    config_az = Coconut.config(base_conf.merge(outputs_with_az_prefix))

    generated_base = [
      "var s3 = s3://a:s@bucket",
      "var user = 5098",
      "var vid = 1234",
      "",
      "set source = https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      "set webhook = http://mysite.com/webhook?vid=$vid&user=$user",
      "",
    ]

    generated_no_prefix = generated_base.dup.push("-> hls = $s3/playlist.m3u8, variants=hls:240p,hls:360p").join("\n")

    generated_with_prefix = generated_base.dup.push("-> hls = $s3/playlist.m3u8, variants=hls:240p,hls:360p, if=$source_height < 300",
                                            "-> hls = $s3/playlist.m3u8, variants=hls:480p,hls:720p, if=$source_height > 300").join("\n")

    assert_equal generated_no_prefix, config_no_prefix
    assert_equal generated_with_prefix, config_num
    assert_equal generated_with_prefix, config_az

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

    assert_equal generated, config

    File.delete("coconut.conf")
  end

  def test_submit_file
    File.open("coconut.conf", "w") {|f| f.write("set webhook = http://mysite.com/webhook?vid=$vid&user=$user\n-> mp4 = s3://a:s@bucket/video/$vid.mp4")}

    job = Coconut::Job.create(
      :conf => "coconut.conf",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
      :vars => {:vid => 1234, :user => 5098}
    )
    assert_equal "ok", job["status"]
    assert job["id"] > 0

    File.delete("coconut.conf")
  end

  def test_set_api_key_in_job_options
    job = Coconut::Job.create(
      :api_key => "k-4d204a7fd1fc67fc00e87d3c326d9b75",
      :source => "https://s3-eu-west-1.amazonaws.com/files.coconut.co/test.mp4",
    )

    assert_equal "error", job["status"]
    assert_equal "authentication_failed", job["error_code"]
  end
end