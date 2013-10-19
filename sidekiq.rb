set_default(:sidekiq_namespace) { "sidekiq_#{application}" }
set_default(:sidekiq_pid) { "#{shared_path}/pids/sidekiq.pid" }
set_default(:sidekiq_log) { "#{shared_path}/log/sidekiq.log" }
set_default(:sidekiq_concurrency, 4)
set_default(:sidekiq_timeout, 10)

namespace :sidekiq do
  desc "Generate the sidekiq.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "sidekiq.yml.erb", "#{shared_path}/config/sidekiq.yml"
  end
  after "deploy:setup", "sidekiq:setup"

  desc "Symlink the sidekiq.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/sidekiq.yml #{release_path}/config/sidekiq.yml"
  end
  after "deploy:finalize_update", "sidekiq:symlink"

  desc "Start sidekiq workers"
  task :start, :roles => :app do
    run "cd #{current_path} ; bundle exec sidekiq -d -e production -C #{shared_path}/config/sidekiq.yml -P #{sidekiq_pid} -L #{shared_path}/log/sidekiq.log"
  end

  after "deploy:start", "sidekiq:start"

  desc "Stop sidekiq workers"
  task :stop, :roles => :app do
    run "if [ -d #{current_path} ] && [ -f #{sidekiq_pid} ] && kill -0 `cat #{sidekiq_pid}`> /dev/null 2>&1; then cd #{current_path} && bundle exec sidekiqctl stop #{sidekiq_pid} #{sidekiq_timeout} ; else echo 'Sidekiq is not running'; fi"
  end

  after "deploy:stop", "sidekiq:stop"

  desc "Restart sidekiq workers"
  task :restart, :roles => :app do
    stop
    start
  end

  after "deploy:restart", "sidekiq:restart"
end