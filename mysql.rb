set_default(:mysql_host, "localhost")
set_default(:mysql_user, "root")
set_default(:mysql_password) { Capistrano::CLI.password_prompt "MySQL Password: " }
set_default(:mysql_database) { "#{application}_production" }
set_default(:mysql_pid) { "/var/run/mysqld/mysqld.pid" }

namespace :mysql do
  desc "Install the latest stable release of MySQL."
  task :install, :roles => :db, :only => {:primary => true} do
    # Uncomment only if you plan to use sqlite
    # run "#{sudo} apt-get -y install sqlite3 libsqlite3-dev"
    run "#{sudo} apt-get -y install mysql-server libmysql-ruby libmysql-ruby1.8 libmysqlclient15-dev" do |channel, stream, data|
    # prompts for mysql root password (when blue screen appears)
    channel.send_data("#{mysql_password}\n\r") if data =~ /password/
    channel.send_data("#{mysql_password}\n\r") if data =~ /password/
end
  end
  after "deploy:install", "mysql:install"

  desc "Create a database for this application."
  task :create_database, :roles => :db, :only => {:primary => true} do
    run %Q{#{sudo} mysql -u#{mysql_user} -p#{mysql_password} -e \"CREATE DATABASE #{mysql_database};\"}
    # run %Q{#{sudo} mysql -u#{mysql_user} -p#{mysql_password} -e "GRANT ALL PRIVILEGES ON #{application}.* TO #{mysql_user}@localhost IDENTIFIED BY '#{mysql_password}';"}
  end
  after "deploy:setup", "mysql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "mysql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "mysql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "mysql:symlink"
end