set_default(:faye_user) { user }
set_default(:faye_pid) { "#{shared_path}/pids/faye.pid" }

namespace :faye do
  desc "Setup Faye initializer"
  task :setup, roles: :app do
    template "faye_init", "/tmp/faye_init"
    run "chmod +x /tmp/faye_init"
    run "#{sudo} mv /tmp/faye_init /etc/init.d/faye_#{application}"
    run "#{sudo} update-rc.d -f faye_#{application} defaults"
  end
  after "deploy:setup", "faye:setup"

  %w[start stop restart].each do |command|
    desc "#{command} faye"
    task command, roles: :app do
      run "service faye_#{application} #{command}"
    end
    after "deploy:#{command}", "faye:#{command}"
  end
end