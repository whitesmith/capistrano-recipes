set_default(:virtualenv_dir, "/www/sentry")
set_default(:sentry_pidfile) { "/var/run/sentry.pid" }
set_default(:sentry_config) { "/etc/sentry.conf.py" }
set_default(:sentry_database_user) { "sentry" }
set_default(:sentry_database) { "sentry" }

set_default(:sentry_superuser) { "admin" }
set_default(:sentry_superuser_email) { "admin@me.com" }
set_default(:sentry_superuser_password) { "password" }

set_default(:sentry_password) { Capistrano::CLI.password_prompt "Sentry DB Password: " }
set_default(:sentry_workers, 3)

namespace :sentry do

  desc "Install Sentry"
  task :install do
    run "#{sudo} apt-get -y install python2.7-dev"
    run "#{sudo} apt-get -y install python-setuptools"
    run "#{sudo} easy_install -UZ virtualenv"
    run "#{sudo} virtualenv /www/sentry/"
    run "source /www/sentry/bin/activate"
    run "#{sudo} easy_install -UZ sentry[postgres]"
    run "#{sudo} easy_install django_bcrypt"

    # Create sentry user and database
    run %Q{#{sudo} -u postgres psql -c "create user #{sentry_database_user} with password '#{sentry_password}';"}
    run %Q{#{sudo} -u postgres psql -c "create database #{sentry_database} owner #{sentry_database_user};"}
    #

    run "#{sudo} sentry init #{sentry_config}"
    # Obtain Sentry random key
    key = capture("grep '^SENTRY_KEY = ' /etc/sentry.conf.py  | cut -d' ' -f3")
    puts "KEY: #{key}"
    set_default(:sentry_key) {key}
    run "#{sudo} rm -rf #{sentry_config}"
    template "sentry.conf.py.erb", "/tmp/sentry.conf.py"
    run "#{sudo} mv /tmp/sentry.conf.py #{sentry_config}"
    run "#{sudo} sentry --config=#{sentry_config} upgrade --noinput"

    # Create superuser
    run "#{sudo} sentry --config=#{sentry_config} createsuperuser" do |channel, stream, data|
      channel.send_data("#{sentry_superuser}\r") if data =~ /Username/
      channel.send_data("#{sentry_superuser_email}\r") if data =~ /E-mail/
      channel.send_data("#{sentry_superuser_password}\r") if data =~ /Password/
      channel.send_data("#{sentry_superuser_password}\r") if data =~ /again/
      puts data
    end
  end

  after "deploy:install", "sentry:install"

  desc "Setup all sentry configuration"
  task :setup do
    template "sentry_spawner.erb", "/tmp/sentry_spawner"
    run "chmod +x /tmp/sentry_spawner"
    run "#{sudo} mv /tmp/sentry_spawner #{ virtualenv_dir }/bin/sentry_spawner"

    template "sentry_init.erb", "/tmp/sentry_init"
    run "chmod +x /tmp/sentry_init"
    run "#{sudo} mv /tmp/sentry_init /etc/init.d/sentry_init"
    run "#{sudo} update-rc.d -f sentry_init defaults"
  end
  after "deploy:setup", "sentry:setup"

  %w[start stop restart].each do |command|
    desc "#{command} sentry"
    task command, :roles => :app do
      run "service sentry_init #{command}"
    end
  end
  after "deploy:start", "sentry:start"
end
