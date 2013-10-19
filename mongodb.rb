namespace :mongodb do
  desc "Install latest stable release of MongoDB, as described on http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/"
  task :install, roles: :web do
    run "#{sudo} apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10"
    run "echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | #{sudo} tee -a /etc/apt/sources.list.d/10gen.list"
    run "#{sudo} apt-get update"
    run "#{sudo} apt-get install mongodb-10gen"
  end
  after "deploy:install", "mongodb:install"

  desc "Setup MongoDB configuration for this application"
  task :setup, roles: :db do
    #TODO
  end
  after "deploy:setup", "mongodb:setup"

  %w[start stop restart].each do |command|
    desc "#{command} MongoDB"
    task command, roles: :web do
      run "#{sudo} service mongodb #{command}"
    end
  end
end