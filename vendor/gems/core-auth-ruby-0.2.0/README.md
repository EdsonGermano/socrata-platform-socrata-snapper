# Core::Auth

Ruby API wrapper for Core Authentication.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'core-auth-ruby', '~> 0.2.0', git: 'git@github.com:socrata/core-auth-ruby.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem build ./core-auth.gemspec
    $ gem install ./core-auth-ruby-0.2.0.gem

## Usage

```ruby
require 'core/auth/client'

auth = Core::Auth::Client.new(domain, email: 'myemail@socrata.com', password: 'mypassword')
fail('Authentication failed') unless auth.logged_in?
puts auth.cookie
```

## Options

Core::Auth::Client can be initialized with some parameters

Options available:

    email: String
    password: String
    cookie: String Existing cookie, to skip login step
    verify_ssl_cert: Boolean (verify SSL cert, set to false on localhost)

## Localhost

It's likely you'll need to skip SSL verification on localhost

```ruby
Core::Auth::Client.new(domain, cookie: existing_cookie, verify_ssl_cert: false)
```

## Contributing

1. Fork it ( https://github.com/socrata/core-auth-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
