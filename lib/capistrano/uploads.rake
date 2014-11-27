namespace :uploads do
  desc "Symlink uploads folder"
  task :symlink do
    on roles(:app), in: :sequence, wait: 5 do
      execute "mkdir -p #{shared_path}/public/uploads"
      execute "ln -nfs #{shared_path}/upload #{release_path}/public/upload"
    end
  end

  after 'deploy:updated', :symlink
end