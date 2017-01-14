# Ruby client Library for encoding Videos with Coconut

## Install

In a Rails application, add this line to `Gemfile`:

```ruby
gem 'coconutrb', '~> 2.2.0'
```

And then, type in your terminal:

```console
bundle install
```

You can also install it via rubygems:

```console
sudo gem install coconutrb
```

## Submitting the job

Use the [API Request Builder](https://app.coconut.co/job/new) to generate a config file that match your specific workflow.

Example of `coconut.conf`:

```ini
var s3 = s3://accesskey:secretkey@mybucket

set webhook = http://mysite.com/webhook/coconut?videoId=$vid

-> mp4  = $s3/videos/video_$vid.mp4
-> webm = $s3/videos/video_$vid.webm
-> jpg:300x = $s3/previews/thumbs_#num#.jpg, number=3
```

Here is the ruby code to submit the config file:

```ruby
# We specify the config file, set the source of the video to convert and
# create a variable "vid" that will be used in the custom webhook URL and output URLs
job = Coconut::Job.create(
  :api_key => "k-api-key",
  :conf    => "coconut.conf",
  :source  => "http://yoursite.com/media/video.mp4",
  :vars    => {:vid => 1234}
)

if job["status"] == "ok"
  puts job["id"]
else
  puts job["error_code"]
  puts job["error_message"]
end
```

You can also create a job without a config file. To do that you will need to give every settings in the method parameters. Here is the exact same job but without a config file:

```ruby
vid = 1234
s3 = "s3://accesskey:secretkey@mybucket"

job = Coconut::Job.create(
  :api_key => "k-api-key",
  :source  => "http://yoursite.com/media/video.mp4",
  :webhook => "http://mysite.com/webhook/coconut?videoId=#{vid}",
  :outputs => {
    "mp4" => "#{s3}/videos/video_#{vid}.mp4",
    "webm" => "#{s3}/videos/video_#{vid}.webm",
    "jpg:300x" => "#{s3}/previews/thumbs_#num#.jpg, number=3"
  }
)
```

A job without config file can contain outputs with same key (like hls). Since the Hash instance can't have duplicate keys, you have to prefix them:

```ruby
vid = 1234
s3 = "s3://accesskey:secretkey@mybucket"

job = Coconut::Job.create(
  :api_key => "k-api-key",
  :source  => "http://yoursite.com/media/video.mp4",
  :webhook => "http://mysite.com/webhook/coconut?videoId=#{vid}",
  :outputs => {
    "2@hls" => "#{s3}/videos/playlist.m3u8, variants=hls:360p, if=$source_height > 300",
    "1@hls" => "#{s3}/videos/playlist.m3u8, variants=hls:240p, if=$source_height < 300",
  }
)
```

The output config file will contain 2 hls outputs, sorted by prefix:

```ini
var s3 = s3://accesskey:secretkey@mybucket

set webhook = http://mysite.com/webhook/coconut?videoId=$vid

-> hls = $s3/videos/playlist.m3u8, variants=hls:240p, if=$source_height < 300
-> hls = $s3/videos/playlist.m3u8, variants=hls:360p, if=$source_height > 300
```

The prefix can be any digital or a-zA-Z char.


Note that you can use the environment variable `COCONUT_API_KEY` to set your API key.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


*Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).*
---

* Coconut website: http://coconut.co
* API documentation: http://coconut.co/docs
* Contact: [support@coconut.co](mailto:support@coconut.co)
* Twitter: [@OpenCoconut](http://twitter.com/opencoconut)
