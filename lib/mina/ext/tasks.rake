require 'mina/bundler'
require 'mina/rails'

#LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid"
#SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

require 'yaml'
require 'erb' #to calculate database.yml

figaro_gem_config = "#{Dir.getwd}/config/application.yml"
database_config = "#{Dir.getwd}/config/database.yml"

#for later psych versions
if YAML.respond_to?(:unsafe_load)
  db_config = YAML.unsafe_load(File.read(database_config))
  #figaro gem app config
  app_config = (YAML.unsafe_load(File.read(figaro_gem_config)) rescue {})
  #just to make ERB calculation in database.yml work
else
  db_config = YAML.load_file(database_config)
  app_config = (YAML.load_file(figaro_gem_config) rescue {})
end

ENV.merge!(app_config) 

if fetch(:database).nil?
  prod_database = ERB.new(db_config["production"]["database"]).result
  set :database, prod_database
end

if fetch(:database_dev).nil?
  set :database_dev, ERB.new(db_config["development"]["database"]).result
end

#restoring ENV, to avoid warnings when figaro will load it's vars
app_config.keys.each { |key| ENV.delete(key) }


desc 'zip on remote server'
task "db:sql_zip" do
  command 'cd /tmp'
  puts "dumping data remotely, db:#{fetch(:database)}"
  command "pg_dump #{fetch(:database)}>/tmp/#{fetch(:database)}_dump.sql"
  command "rm #{fetch(:database)}_dump.zip; zip #{fetch(:database)}_dump #{fetch(:database)}_dump.sql; rm #{fetch(:database)}_dump.sql"
end

desc 'download data dump'
task "db:sql_download" do
  puts "downloading"
  system "mkdir -p ~/tmp"
  system "scp #{fetch(:user)}@#{fetch(:domain)}:/tmp/#{fetch(:database)}_dump.zip ~/tmp/"
  system "rm ~/tmp/#{fetch(:database)}_dump.sql; unzip ~/tmp/#{fetch(:database)}_dump.zip -d ~/tmp"
  puts "data placed in ~/tmp/#{fetch(:database)}_dump.sql"
end

desc 'import downloaded dump to local database'
task "db:sql_import" do
  puts "importing data to local database, db:#{fetch(:database_dev)}"
  system "psql -d #{fetch(:database_dev)} -c 'DROP SCHEMA public CASCADE;CREATE SCHEMA public;'"
  system "psql -d #{fetch(:database_dev)}< ~/tmp/#{fetch(:database)}_dump.sql"
  system "rake db:migrate" if !ENV['NOMIGRATE']
end

#all three tasks
task "db:sql_pull" do
  system 'mina db:zip' #system because should wait till zipped
  invoke 'db:sql_download'
  invoke 'db:sql_import'
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
  command_line = "rsync -azP root@#{fetch(:domain)}:#{fetch(:deploy_to)}/shared/public/system/ ./public/system --delete"
  puts "syncing PaperClip: #{command_line}"
  system command_line

  command_line = "rsync -azP root@#{fetch(:domain)}:#{fetch(:deploy_to)}/current/storage/ ./storage --delete"
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
  system "echo ' 🔓 logging into shell on server'"
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
  puts "dumping data remotely, db:#{fetch(:database)}"
  #command "pg_dump #{fetch(:database)} -Fc --exclude-table-data 'messenger_messages' --exclude-table-data 'versions' --exclude-table-data 'delayed_jobs' --exclude-table-data 'telegram_queues'>/media/extra/#{fetch(:database)}_dump.dump"
  #command "pg_dump #{fetch(:database)} -Fc --exclude-table-data 'delayed_jobs' --exclude-table-data 'telegram_queues'>/media/extra/#{fetch(:database)}_dump.dump"
  command "pg_dump #{fetch(:database)} -Fc >/tmp/#{fetch(:database)}_dump.dump"
end

task "db:download" do
  system "mkdir -p ~/tmp"
  system "scp #{fetch(:user)}@#{fetch(:domain)}:/tmp/#{fetch(:database)}_dump.dump ~/tmp/"
  puts "data placed in ~/tmp/#{fetch(:database)}_dump.dump"
end

task "db:import" do
  system "psql -d #{fetch(:database_dev)} -c 'DROP SCHEMA public CASCADE;CREATE SCHEMA public;'"
  system "pg_restore -d #{fetch(:database_dev)} ~/tmp/#{fetch(:database)}_dump.dump"
  system "rake db:migrate" if !ENV['NOMIGRATE']
end

#all three tasks
task "db:pull" do
  system 'mina db:dump' #такой вызов чтобы дамп закончился
  invoke 'db:download'
  invoke 'db:import'
end

#push and deploy
task "pd" do
  invoke 'push'
  invoke 'deploy'
end


#put file on remote server (to update without git push for example)
task :put do
  file = ARGV[1]
  cmd = "scp -Cr #{file} root@#{fetch(:domain)}:#{fetch(:deploy_to)}/current/#{file}"
  puts cmd
  system cmd  
end

#get file from remote server
task :get do
  file = ARGV[1]

  # Ensure destination folder exists
  dest_dir = File.dirname(file)
  cmd = "mkdir -p #{dest_dir}"
  puts "> #{cmd}"
  system cmd
  
  # Copy the file from remote
  cmd = "scp -Cr root@#{fetch(:domain)}:#{fetch(:deploy_to)}/current/#{file} #{file}"
  puts "> #{cmd}"
  system cmd
  
end