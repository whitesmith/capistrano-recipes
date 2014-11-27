set_default(:fnordmetric_pid) { "#{current_path}/tmp/pids/fnordmetric.pid" }
set_default(:fnordmetric_script) { "YOUR_FNORDMETRIC_SCRIPT.RB" }

namespace :fnordmetric do
  desc "Starts Fnordmetric server"
  task :start do
      run "cd #{current_path} && (nohup bundle exec ruby #{fnordmetric_script} RAILS_ENV=production > #{shared_path}/log/fnordmetric.log >/dev/null 2>&1 &) && sleep 1", :pty => true
  end

  desc "Stop Fnordmetric server"
  task :stop do
      run "/bin/kill -QUIT `cat #{fnordmetric_pid}`"
  end

  desc "Restart Fnordmetric server"
  task :restart do
  	stop
  	start
  end
  after "deploy:restart", "fnordmetric:restart"
end