namespace :log do
  desc "Tail all application log files"
  task :tail do
    on roles(:app) do
      execute :tail, "-f", "#{shared_path}/log/*.log" do |channel, stream, data|
        puts "#{channel[:host]}: #{data}"
        break if stream == :err
      end
    end
  end
end