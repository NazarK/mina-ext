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
  system 'mina db:zip' #system because should wait till zipped
  invoke 'db:download'
  invoke 'db:import'
end

#backup current database, so it can be restored with db:import
task "db:backup" do
  puts "saving backup to ~/tmp/#{fetch(:database)}_dump.sql"
  system "pg_dump #{fetch(:database)}>~/tmp/#{fetch(:database)}_dump.sql"
end


task :push do
  #env var (when using "invoke 'push'" in deploy hook for example)
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
  puts "syncing PaperClip: #{command_line}"
  system command_line

  command_line = "rsync -azP root@#{fetch(:domain)}:#{fetch(:deploy_to)}/current/storage/ ./storage"
  puts "syncing ActiveStorage: #{command_line}"
  system command_line
end

task "data:pull" do
  invoke 'db:pull'
  invoke 'files:pull'
  puts "DONE: #{Time.now}"
end

task :backup do
  invoke 'db:pull'
  invoke 'files:pull'
  puts "DONE: #{Time.now}"
end

task :shell do
  system "echo 'logging into shell on server'"
  system "ssh #{fetch(:user)}@#{fetch(:domain)} -t \"cd #{fetch(:deploy_to)}/current; bash --login\""
end

=begin
task :launch do
  puts LAUNCH_CMD
  system SHUTDOWN_CMD
  system LAUNCH_CMD
end

task :shutdown do
  system SHUTDOWN_CMD
end
=end

#edit Last Migration
task :lm do
  system "vi `ls -Art ./db/migrate/*.rb | tail -n 1`"
end




task "db:dump" do
  puts "dumping data remotely"
  #command "pg_dump #{fetch(:database)} -Fc --exclude-table-data 'messenger_messages' --exclude-table-data 'versions' --exclude-table-data 'delayed_jobs' --exclude-table-data 'telegram_queues'>/media/extra/#{fetch(:database)}_dump.dump"
  #command "pg_dump #{fetch(:database)} -Fc --exclude-table-data 'delayed_jobs' --exclude-table-data 'telegram_queues'>/media/extra/#{fetch(:database)}_dump.dump"
  command "pg_dump #{fetch(:database)} -Fc >/tmp/#{fetch(:database)}_dump.dump"
end

task "db:dump_download" do
  system "scp #{fetch(:user)}@#{fetch(:domain)}:/tmp/#{fetch(:database)}_dump.dump ~/tmp/"
  puts "data placed in ~/tmp/#{fetch(:database)}_dump.dump"
end

task "db:dump_import" do
  system "psql -d #{fetch(:database_dev)} -c 'DROP SCHEMA public CASCADE;CREATE SCHEMA public;'"
  system "pg_restore -d #{fetch(:database_dev)} ~/tmp/#{fetch(:database)}_dump.dump"
  system "rake db:migrate" if !ENV['NOMIGRATE']
end

#all three tasks
task "db:dump_pull" do
  system 'mina db:dump' #такой вызов чтобы дамп закончился
  invoke 'db:dump_download'
  invoke 'db:dump_import'
end

#push and deploy
task "pd" do
  invoke 'push'
  invoke 'deploy'
end
