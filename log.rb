set_default(:rotation_period) { "7" } # Rotation period (in days)
set_default(:max_size) { "5M" } # Max log file size

namespace :log do
  desc "Tail all application log files"
  task :tail, :roles => :app do
    run "tail -f #{shared_path}/log/*.log" do |channel, stream, data|
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

  desc "Install log rotation script; optional args: days=7, size=5M, group (defaults to same value as :user)"
  task :rotate, :roles => :app do
    template "logrotate.erb", "#{shared_path}/logrotate_script"
    run "#{sudo} cp #{shared_path}/logrotate_script /etc/logrotate.d/#{application}"
    run "#{sudo} rm #{shared_path}/logrotate_script"
  end
end