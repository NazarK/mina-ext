# mina-ext

Using this in a bunch of my projects. 
Adds commands to mina. Supposed to work with postgresql.

mina db:pull - backup data (from production on server to local dev database)

mina db:import - restore data from latest pull operation

mina files:pull - backup public/system folder

mina backup - backup db and files

mina push m='comment' - push to repo with comment specified by 'm' parameter

mina launch - start (restart server) in production

mina shell - login into current folder (instead of ssh logging into folder containing current)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mina-ext', github: "NazarK/mina-ext"
```

## Usage

You ssh public key (id_rsa.pub) supposed to be added as authorized key to production server.

zip should be installed on production server.

Add at top of mina config/deploy.rb.


```ruby

require 'mina/ext'

LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid || true"
SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

set :database, "production_database_name"
set :database_dev, "development_database_name"

```

