set_default(:resque_pid) { "#{shared_path}/pids/#{(Time.now.to_f*100).to_i}-resque.pid" }
set_default(:resque_pid_lookup) { "#{shared_path}/pids/*-resque.pid" }
set_default(:alternative_resque_pid) { "#{current_path}/tmp/pids/resque-pool.pid" }
set_default(:resque_log) { "#{shared_path}/log/resque.log" }

namespace :resque do

  desc "Start resque workers"
  task :start, :roles => :app do
    run "cd #{current_path} && bundle exec resque-pool --daemon --environment #{environment} --pidfile #{resque_pid} --stdout #{resque_log} --stderr #{resque_log}"
  end

  after "deploy:start", "resque:start"

  desc "Stop resque workers"
  task :stop, :roles => :app do
    run "if [ -e #{resque_pid_lookup} ]; then cd #{current_path} && kill -s INT `cat #{resque_pid_lookup}` && rm -f #{resque_pid_lookup}; fi"
    run "if [ -e #{alternative_resque_pid} ]; then cd #{current_path} && kill -s INT `cat #{alternative_resque_pid}` && rm -f #{alternative_resque_pid}; fi"
  end

  after "deploy:stop", "resque:stop"

  desc "Restart resque workers"
  task :restart, :roles => :app do
    stop
    start
  end

  after "deploy:restart", "resque:restart"
end