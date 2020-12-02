# Coconut Ruby Library

The Coconut Ruby library provides access to the Coconut API for encoding videos, packaging media files into HLS and MPEG-Dash, generating thumbnails and GIF animation.

This library is only compatible with the Coconut API v2.

## Documentation

See the [full documentation](https://docs.coconut.co).

## Installation

You can install it via rubygems:

```console
gem install coconutrb
```

### Bundler

In Gemfile:

```ruby
gem 'coconutrb', '~> 3.0.0'
```

And then, type in your terminal:

```console
bundle install
```

## Usage

The library needs you to set your API key which can be found in your [dashboard](https://app.coconut.co/api). Webhook URL and storage settings are optional but are very convenient because you set them only once.

```ruby
Coconut.api_key = 'k-api-key'
Coconut.webhook_url = "https://yoursite/api/coconut/webhook"

Coconut.storage = {
  service: "s3",
  bucket: "my-bucket",
  credentials: {
    access_key_id: "access-key",
      secret_access_key: "secret-key"
  }
}
```

## Creating a job

```ruby
Coconut::Job.create(
  input: { url: "https://mysite/path/file.mp4" },
  outputs: {
    "jpg:300x": { path: "/image.jpg" },
    "mp4:1080p": { path: "/1080p.mp4" },
    "httpstream": {
      hls: { path: "hls/" }
    }
  }
)
```

## Getting information about a job

```ruby
Coconut::Job.retrieve("OolQXaiU86NFki")
```

## Retrieving metadata

```ruby
Coconut::Metadata.retrieve("OolQXaiU86NFki")

# Retrieve metadata for a specific output
Coconut::Metadata.retrieve("OolQXaiU86NFki", "mp4:1080p")
```

## Per-request configuration

```ruby
cli = Coconut::Client.new(api_key: "k-api-key-prod")
Coconut::Job.create(job, client: cli)
```

*Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).*