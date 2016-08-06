# encoding: utf-8
module Mutx
  module BackgroundJobs
    class Sidekiq
      def self.start

        workers_dir = workers_dir = __FILE__.split("/")[0..-2].join("/")+ "/workers"

        Mutx::Support::Console.execute "sidekiq -r #{workers_dir}/executor.rb -d -L mutx/logs/sidekiq.log -P mutx/sidekiq_pid"

        print "\n* Sidekiq:"
        raise "Could not start Sidekiq correctly. Read mutx/logs/sidekiq.log file for more information" if not started?

        print " Started!\n"
      end

      # Existance of pid file means that sidekiq was started
      def self.started?
        begin
          sec = 0
          begin
            print "."
            return true if IO.read("#{Dir.pwd}/mutx/logs/sidekiq.log") =~ /INFO: Booting Sidekiq \d+.\d+.\d+ with redis options {/
            sec += sleep 1
          end until sec == 10

          puts "Sidekiq not started"
          false

        rescue
          false
        end
      end
    end
  end
end