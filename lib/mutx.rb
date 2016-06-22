require "mutx/version"
require "thor"
require 'json'
require 'colorize'
require 'github/markup'
require 'redis'
require 'sidekiq'
require 'mote'
require 'base64'
require 'require_all'

require_rel 'mutx'
require_rel 'generators'


module Mutx


  # if Dir.exist? "#{Dir.pwd}/mutx/logs"

  #   # Creates mutx_log if it does not exist
  #   File.open("#{Dir.pwd}/mutx/logs/mutx.log","a+"){} unless File.exist? "#{Dir.pwd}/mutx/logs/mutx.log"

  #   # Set global conf
  #   #Mutx::Support::Log.start
  #   Mutx::Support::Configuration.get
  #   $NOTIF ||= Support::Notification.new("#{Dir.pwd.split("/").last}", "#{Mutx::Support::IfConfig.ip}:#{Mutx::Support::Configuration.port}")

  # end


  class Base < Thor

    desc "help","If you cannot start mutx"
    def help
      Mutx::Commands.help
    end

    desc "install","Install Mutx on your project"
    def install
      Mutx::Commands.install
    end

    desc "start", "Starts a service waiting for get requests to run tasks you've defined"
    option :nodemon, :required =>false, :type => :boolean, :desc => "Add this flag to no demon use."
    def start
      if Dir.exist? "#{Dir.pwd}/mutx"
        Mutx::Support::Log.start
        Mutx::Commands.start(options["nodemon"])
      else
        puts "

Could not find mutx folder on root project folder. You can use `mutx install`

".red
      end
    end

    desc "stop", "Stop mutx service"
    def stop
      Mutx::Commands.stop
    end

    desc "restart", "Restart Mutx"
    def restart
      Mutx::Commands.restart
    end

    desc "reset","Purges all db registers"
    def reset
      if yes? "Are you sure to reset all register? (yes/no)"
        Mutx::Commands.reset
      end
    end

    desc "reset_tasks","Reset all tasks registers. This command is to purge all tasks from db"
    def reset_tasks
      Mutx::Commands.reset_tasks
    end

    desc "Say bye to mutx", ""
    def bye
      if yes? "Are you sure to say bye to Mutx? (yes/no)"
        Mutx::Commands.bye
      end
    end
  end
end
