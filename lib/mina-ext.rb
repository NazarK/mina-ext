#set :database, "profres_prod"
#set :database_dev, "profres_dev"
#LAUNCH_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin start -p 8080 -d --threaded --threadpool-size 2 --pid #{fetch(:deploy_to)}/shared/thin.pid"
#SHUTDOWN_CMD="cd #{fetch(:deploy_to)}/current; RAILS_ENV=production bundle exec thin stop --pid #{fetch(:deploy_to)}/shared/thin.pid || true"

task :db_zip do
  command 'cd /tmp'
  puts "dumping data remotely"
  command "pg_dump #{fetch(:database)}>/tmp/#{fetch(:database)}_dump.sql"
  command "rm #{fetch(:database)}_dump.zip; zip #{fetch(:database)}_dump #{fetch(:database)}_dump.sql; rm #{fetch(:database)}_dump.sql"
end

#dev database name should match production database name
task :db_pull do
  system 'mina db_zip'
  system "scp #{fetch(:user)}@#{fetch(:domain)}:/tmp/#{fetch(:database)}_dump.zip ~/tmp/"
  system "rm ~/tmp/#{fetch(:database)}_dump.sql; unzip ~/tmp/#{fetch(:database)}_dump.zip -d ~/tmp"
  puts "data placed in ~/tmp/#{fetch(:database)}_dump.sql"

  system 'mina db_import'
end

task :db_import do
  puts "importing data to local database"
  system "psql -d #{fetch(:database_dev)} -c 'DROP SCHEMA public CASCADE;CREATE SCHEMA public;'"
  system "psql -d #{fetch(:database_dev)}< ~/tmp/#{fetch(:database)}_dump.sql"
  system "rake db:migrate" if !ENV['NOMIGRATE']
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

task :files_pull do
  command_line = "rsync -azP root@#{fetch(:domain)}:#{fetch(:deploy_to)}/shared/public/system/ ./public/system"
  puts "running rsync: #{command_line}"
  system command_line
end

task :backup do
  system 'mina db_pull'
  system 'mina files_pull'
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
