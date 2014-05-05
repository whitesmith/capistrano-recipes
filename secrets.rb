namespace :secrets do
  desc "SCP transfer secrets.yml configuration file to the shared folder"
  task :setup do
    transfer :up, "config/secrets.yml", "#{shared_path}/secrets.yml", :via => :scp
  end

  desc "Symlink application.yml to the release path"
  task :symlink do
    run "ln -sf #{shared_path}/secrets.yml #{release_path}/config/secrets.yml"
  end

  desc "Check if secrets.yml file exists on the server"
  task :check do
    begin
        run "test -f #{shared_path}/secrets.yml"
      rescue Capistrano::CommandError
        unless fetch(:force, false)
          logger.important 'application.yml file does not exist on the server "shared/application.yml"'
          exit
        end
    end
  end

  after "deploy:setup", "secrets:setup"
  after "deploy:finalize_update", "secrets:symlink"
end