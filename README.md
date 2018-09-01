# Mina::Ext


Adds commands to mina. Supposed to work with postgresql.

db_pull - backup data (from production on server to local dev database)
files_pull - backup public/system folder
backup - backup db and files
push - push to repo with comment specified by 'm' parameter

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mina-ext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mina-ext

## Usage

Add to the end of your mina config/deploy.rb.


```ruby

LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid"
SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

set :database, "production_database_name"
set :database_dev, "development_database_name"

require 'mina-ext.rb'
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mina-ext. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mina::Ext project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mina-ext/blob/master/CODE_OF_CONDUCT.md).
