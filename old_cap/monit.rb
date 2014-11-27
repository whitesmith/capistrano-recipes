namespace :monit do
  desc "Install Monit"
  task :install do
    run "#{sudo} apt-get -y install monit"
  end
  after "deploy:install", "monit:install"

  desc "Setup all Monit configuration"
  task :setup do
    monit_config "monitrc", "/etc/monit/monitrc"
    # nginx
    # postgresql
    # unicorn
    # redis
    # sidekiq
    # tcp_proxy
    # sentry
    # faye
    # ... and other dependencies you may be using ...
    syntax
    reload
  end
  after "deploy:setup", "monit:setup"

  # task(:nginx, roles: :web) { monit_config "nginx" }
  # task(:postgresql, roles: :db) { monit_config "postgresql" }
  # task(:unicorn, roles: :app) { monit_config "unicorn" }
  # task(:redis, roles: :app) { monit_config "redis" }
  # task(:sidekiq, roles: :app) { monit_config "sidekiq" }
  # task(:tcp_proxy, roles: :app) { monit_config "tcp_proxy" }
  # task(:sentry, roles: :app) { monit_config "sentry" }
  # task(:faye, roles: :app) { monit_config "faye" }
  # ... and other dependencies you may be using ...

  %w[start stop restart syntax reload].each do |command|
    desc "Run Monit #{command} script"
    task command do
      run "#{sudo} service monit #{command}"
    end
  end
end

def monit_config(name, destination = nil)
  destination ||= "/etc/monit/conf.d/#{name}.conf"
  template "monit/#{name}.erb", "/tmp/monit_#{name}"
  run "#{sudo} mv /tmp/monit_#{name} #{destination}"
  run "#{sudo} chown root #{destination}"
  run "#{sudo} chmod 600 #{destination}"
end