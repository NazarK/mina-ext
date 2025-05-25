# mina-ext

Adds commands to mina. Inspired by Heroku.

Using these command in all my projects.

mina db:pull - backup data (from production on server to local dev database)

mina db:import - restore data from latest pull operation

mina files:pull - backup public/system folder

mina backup - backup db and files (db:import and files:pull)

mina push m='comment' - push to repo with comment specified by 'm' parameter

mina push - git commit all changes with empty comment (using '-' as comment)

mina shell - login to current folder (instead of ssh logging into folder containing current)

mina put app/file/path - put file from app structure on remote server in same place

mina get app/file/path - get file from remote server and place it in app structure in same place

## Notes
Database functions work with postgresql only. Database names are taken from config/database.yml.

## Requirements
You ssh public key (id_rsa.pub) supposed to be added as authorized key to production server.
zip should be installed on production server.

## Installation

Add this to Gemfile:

```ruby
gem 'mina-ext', github: "NazarK/mina-ext"
```

Add at top of mina config/deploy.rb.

```ruby
require 'mina/ext'
```

## Profit

You should have 'mina db:pull' and other commands working. 