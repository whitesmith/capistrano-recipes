set_default(:postgresql_host, "localhost")
set_default(:postgresql_user) { application }
set_default(:postgresql_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
set_default(:postgresql_database) { "#{application}_production" }
set_default(:postgresql_pid) { "/var/run/postgresql/9.1-main.pid" }

namespace :postgresql do
  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} add-apt-repository -y ppa:pitti/postgresql"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install postgresql libpq-dev"
    # To enable modules such as HStore
    run "#{sudo} apt-get -y install postgresql-contrib"
  end
  after "deploy:install", "postgresql:install"

  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
    run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
    # Create HStore extension
    run %Q{#{sudo} -u postgres psql #{postgresql_database} -c "CREATE EXTENSION IF NOT EXISTS hstore;"}
  end
  after "deploy:setup", "postgresql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "postgresql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "postgresql:symlink"

  task :backup_name, :roles => :db, :only => { :primary => true } do
    run "mkdir -p #{shared_path}/backups"
    set :backup_file, "#{shared_path}/backups/#{postgresql_database}-#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.sql"
  end

  desc "Backup the production database and download the script"
  task :backup, :roles => :db do
    backup_name
    file = capture "cat #{shared_path}/config/database.yml"
    password = YAML.load(file)[rails_env.to_s]["password"]
    run "cd #{shared_path}; pg_dump -W -Fc --no-acl --no-owner -h #{postgresql_host} -U #{postgresql_user} #{postgresql_database} | bzip2 -c > #{backup_file}.bz2" do |ch, stream, out|
      ch.send_data "#{password}\n" if out =~ /^Password:/
    end
  end

  desc "Restore the production database into development"
  task :restore, :roles => :db do
    backup_name
    development_info = YAML.load_file("config/database.yml")['development']
    system("bunzip2 #{application}.sql.bz2")
    system("pg_restore --verbose --clean --no-acl --no-owner -h localhost -U #{development_info['username']} -d #{development_info['database']} #{application}.sql")
    system("rm -rf #{application}.sql")
  end

  desc "Sync your production database to your local workstation"
  task :sync do
    backup
    get "#{backup_file}.bz2", "#{application}.sql.bz2"
    restore
  end
end