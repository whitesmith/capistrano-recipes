def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

namespace :deploy do
  desc "Install everything onto the server"
  task :install do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install python-software-properties libxslt-dev libxml2-dev"
  end

  task :symlink_uploads do
    run "rm -rf #{release_path}/public/upload"
    run "ln -nfs #{shared_path}/upload #{release_path}/public/upload"
  end
  after 'deploy:update_code', 'deploy:symlink_uploads'
end