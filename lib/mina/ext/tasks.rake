require 'mina/bundler'
require 'mina/rails'

#LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid"
#SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

require 'yaml'
db_config = YAML.load_file("#{Dir.getwd}/config/database.yml")

if fetch(:database).nil?
  set :database, db_config["production"]["database"]
end  

if fetch(:database_dev).nil?
  set :database_dev, db_config["development"]["database"]
end


desc 'zip on remote server'
task "db:zip" do
  command 'cd /tmp'
  puts "dumping data remotely"
  command "pg_dump #{fetch(:database)}>/tmp/#{fetch(:database)}_dump.sql"
  command "rm #{fetch(:database)}_dump.zip; zip #{fetch(:database)}_dump #{fetch(:database)}_dump.sql; rm #{fetch(:database)}_dump.sql"
end

desc 'download data dump'
task "db:download" do
  puts "downloading"
  system "mkdir ~/tmp 2>/dev/null"
  system "scp #{fetch(:user)}@#{fetch(:domain)}:/tmp/#{fetch(:database)}_dump.zip ~/tmp/"
  system "rm ~/tmp/#{fetch(:database)}_dump.sql; unzip ~/tmp/#{fetch(:database)}_dump.zip -d ~/tmp"
  puts "data placed in ~/tmp/#{fetch(:database)}_dump.sql"
end

desc 'import downloaded dump to local database'
task "db:import" do
  puts "importing data to local database"
  system "psql -d #{fetch(:database_dev)} -c 'DROP SCHEMA public CASCADE;CREATE SCHEMA public;'"
  system "psql -d #{fetch(:database_dev)}< ~/tmp/#{fetch(:database)}_dump.sql"
  system "rake db:migrate" if !ENV['NOMIGRATE']
end

#all three tasks
task "db:pull" do
  system 'mina db:zip'
  system 'mina db:download'
  system 'mina db:import'
end

#backup current database, so it can be restored with db:import
task "db:backup" do
  puts "saving backup to ~/tmp/#{fetch(:database)}_dump.sql"
  system "pg_dump #{fetch(:database)}>~/tmp/#{fetch(:database)}_dump.sql"
end


task :push do
  #env var (when using "system 'mina push'" in deploy hook for example)
  if !ENV["NOCOMMIT"] && !ENV["NOCOM"]
    comment = ENV['m'] || '-'
    puts "using commit comment: #{comment}"
    system "git add ."
    system "git commit -am \"#{comment}\""
    system "git push origin #{fetch(:branch)}"
  end
end

task "files:pull" do
  command_line = "rsync -azP root@#{fetch(:domain)}:#{fetch(:deploy_to)}/shared/public/system/ ./public/system"
  puts "running rsync: #{command_line}"
  system command_line
end

task "data:pull" do
  system 'mina db:pull'
  system 'mina files:pull'
  puts "DONE: #{Time.now}"  
end

task :backup do
  system 'mina db:pull'
  system 'mina files:pull'
  puts "DONE: #{Time.now}"
end

task :shell do
  system "echo 'logging into shell on server'"
  system "ssh #{fetch(:user)}@#{fetch(:domain)} -t \"cd #{fetch(:deploy_to)}/current; bash --login\""
end  

task :launch do
  puts LAUNCH_CMD
  system SHUTDOWN_CMD
  system LAUNCH_CMD
end

task :shutdown do
  system SHUTDOWN_CMD
end

#edit Last Migration
task :lm do
  system "vi `ls -Art ./db/migrate/*.rb | tail -n 1`"
end