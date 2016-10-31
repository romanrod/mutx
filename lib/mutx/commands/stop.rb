# encoding: utf-8
module Mutx
  module Commands
    def self.stop

      Mutx::Support::Log.debug "#{self}:#{__method__}" if Mutx::Support::Log

      Mutx::Support::Configuration.get

      # Get pids from saved file on start process
      if File.exist? "#{Dir.pwd}/mutx/mutx_pids"

        mutx_pids = IO.read("#{Dir.pwd}/mutx/mutx_pids").split("\n")
        # Kill all pids specified on file

        begin
          Mutx::Support::Processes.kill_all_these mutx_pids
        rescue
        end

        # Delete pid file
        File.delete("#{Dir.pwd}/mutx/mutx_pids")
      end

      if File.exist? "#{Dir.pwd}/mutx/sidekiq_pid"

        sidekiq_pid = IO.read("#{Dir.pwd}/mutx/sidekiq_pid").split("\n")

        begin
          Mutx::Support::Processes.kill_all_these sidekiq_pid
        rescue
        end


        File.delete("#{Dir.pwd}/mutx/sidekiq_pid")
      end

      if File.exist? "#{Dir.pwd}/mutx/sidekiq_cron_pid"

        sidekiq_cron_pid = IO.read("#{Dir.pwd}/mutx/sidekiq_cron_pid").split("\n")

        begin
          Mutx::Support::Processes.kill_all_these sidekiq_cron_pid
        rescue
        end


        File.delete("#{Dir.pwd}/mutx/sidekiq_cron_pid")
      end

      if File.exist? "#{Dir.pwd}/mutx/sidekiq_update_started_pid"
        sidekiq_update_started_pid = IO.read("#{Dir.pwd}/mutx/sidekiq_update_started_pid").split("\n")
        begin
          Mutx::Support::Processes.kill_all_these sidekiq_update_started_pid
        rescue
        end
        File.delete("#{Dir.pwd}/mutx/sidekiq_update_started_pid")
      end

      # Evaluates if any pid could not be killed (retry)
      Mutx::Support::Processes.kill_all_these(Mutx::Support::Processes.mutx_pids)

      if Mutx::Support::Processes.mutx_pids.empty?

        puts "
Mutx stopped!"

      else
        puts "
Could not stop Mutx.
If Mutx is still running please type `mutx help` to get some help"
      end
    end
  end
end

