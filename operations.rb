namespace :operations do
  desc "script/console on a remote server"
  task :console do
    rails_env = fetch(:rails_env, "production")
    server = find_servers(:roles => [:app]).first
    run_with_tty server, %W( bundle exec rails console #{rails_env} )
  end

  set :rake_cmd do
    rails_env = fetch(:rails_env, "production")
    "cd #{current_path} && bundle exec rake RAILS_ENV=#{rails_env}"
  end

  # FIXME run on only one server?
  desc "Runs a given rake task on the server. Usage: cap operations:rake task='db:seed'"
  task :rake, :roles => [:app] do
    if ENV['task']
      run "#{rake_cmd} #{ENV['task']}"
    else
      # FIXME use logger instead of warn?
      warn "USAGE: cap operations:rake task=..."
    end
  end

  desc "View htop"
  task :htop do
    hostname = find_servers_for_task(current_task).first
    exec "ssh -t #{user}@#{hostname} 'htop'"
  end

  def run_with_tty server, cmd
    # looks like total pizdets
    command = []
    command += %W( ssh -t #{gateway} -l #{self[:gateway_user] || self[:user]} ) if self[:gateway]
    command += %W( ssh -t )
    command += %W( -p #{server.port}) if server.port
    command += %W( -l #{user} #{server.host} )
    command += %W( cd #{current_path} )
    # have to escape this once if running via double ssh
    command += [self[:gateway] ? '\&\&' : '&&']
    command += Array(cmd)
    system *command
  end
end