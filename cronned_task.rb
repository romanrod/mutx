require 'rufus/scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  current_directory = Dir.pwd
  system("cd #{current_directory}" && "bundle exec ruby cron.rb")
end
scheduler.join