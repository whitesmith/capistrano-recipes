namespace :unicorn do
  desc 'Start application'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "service", "unicorn_#{fetch(:application)}", "start"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "service", "unicorn_#{fetch(:application)}", "stop"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "service", "unicorn_#{fetch(:application)}", "restart"
    end
  end

  after 'deploy:publishing', :restart
end
