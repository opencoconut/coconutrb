# Ruby client Library for encoding Videos with Coconut

## Install

In a Rails application, add this line to `Gemfile`:

``` language-ruby
gem 'coconutrb', '~> 2.2.0'
```

And then, type in your terminal:

``` language-console
bundle install
```

You can also install it via rubygems:

``` language-console
sudo gem install coconutrb
```

## Submitting the job

Use the [API Request Builder](https://app.coconut.co/job/new) to generate a config file that match your specific workflow.

Example of `coconut.conf`:

``` language-hw
var s3 = s3://accesskey:secretkey@mybucket

set webhook = http://mysite.com/webhook/coconut?videoId=$vid

-> mp4  = $s3/videos/video_$vid.mp4
-> webm = $s3/videos/video_$vid.webm
-> jpg_300x = $s3/previews/thumbs_#num#.jpg, number=3
```

Here is the ruby code to submit the config file:

``` language-ruby
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

``` language-ruby
vid = 1234
s3 = "s3://accesskey:secretkey@mybucket"

job = Coconut::Job.create(
  :api_key => "k-api-key",
  :source  => "http://yoursite.com/media/video.mp4",
  :webhook => "http://mysite.com/webhook/coconut?videoId=#{vid}",
  :outputs => {
    "mp4" => "#{s3}/videos/video_#{vid}.mp4",
    "webm" => "#{s3}/videos/video_#{vid}.webm",
    "jpg_300x" => "#{s3}/previews/thumbs_#num#.jpg, number=3"
  }
)
```

Note that you can use the environment variable `COCONUT_API_KEY` to set your API key.

*Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).*
---

* Coconut website: http://coconut.co
* API documentation: http://coconut.co/docs
* Github: http://github.com/opencoconut/coconut.rb
* Contact: [support@coconut.co](mailto:support@coconut.co)
* Twitter: [@OpenCoconut](http://twitter.com/opencoconut)