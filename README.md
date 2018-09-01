# mina-ext

Adds commands to mina. Supposed to work with postgresql.

mina db_pull - backup data (from production on server to local dev database)

mina files_pull - backup public/system folder

mina backup - backup db and files

mina push m='comment' - push to repo with comment specified by 'm' parameter

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mina-ext', github: "NazarK/mina-ext"
```

## Usage

You ssh public key (id_rsa.pub) supposed to be added as authorized key to production server.

Add to the end of your mina config/deploy.rb.


```ruby

LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid"
SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

set :database, "production_database_name"
set :database_dev, "development_database_name"

require 'mina-ext.rb'
```

