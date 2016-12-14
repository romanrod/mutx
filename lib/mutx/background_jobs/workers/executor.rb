# encoding: utf-8
require 'mutx'
require 'socket'
require 'pty'
require 'colorize'
#require 'sidekiq/testing/inline'
#require 'byebug'

module Mutx
  module Workers
    class Executor
      include Sidekiq::Worker

      sidekiq_options :retry => false

        def perform(result_id)

          @output = ""

          Mutx::Support::Configuration.get
          Mutx::Database::MongoConnector.new Mutx::Support::Configuration.db_connection_data

          Mutx::Support::ChangeInspector.is_there_a_change?

          result = Mutx::Results::Result.get(result_id)
          task = Mutx::Tasks::Task.get(result.task_id)

          result.mutx_report_file_name= "mutx_report_#{result_id}.html"

          if result.is_ruby_platform?
            if Mutx::Platforms::Ruby.using_bundler?
              bundle_output = Mutx::Support::Console.execute "bundle install"
              bundle_output.slice! "fatal: Not a git repository (or any of the parent directories): .git"
            end
            if bundle_output
              result.append_output bundle_output if bundle_output.include? "Installing"
              if bundle_output.include? "Could not find"
                result.finish!
                raise "An error ocurred installing gem while executing bundler"
              else
                result.append_output "All GEMS are installed and running!\nEXECUTION OUTPUT:\n\n--"                
              end
            end
          end

          Dir.mkdir "#{Dir.pwd}/mutx/temp" unless Dir.exist? "#{Dir.pwd}/mutx/temp"

          efective_command = []
          efective_command << Mutx::Support::Configuration.headless? if result.gui_task?
          efective_command << result.command
          efective_command << "-f pretty -f html -o mutx/temp/#{result.mutx_report_file_name}" if result.is_cucumber?
          efective_command << result.custom_params_values
          efective_command << "_id=#{result.id}" # to use inside execution the possibility to add information to the result

          result.mutx_command= efective_command.join(" ")

          attach_folder = "#{Dir.pwd}/mutx/out/#{result.id}/attachment"

          # To Be Deleted on prod
          Mutx::Support::Log.debug "[result:#{result.id}] #{efective_command.join(' ')}" if Mutx::Support::Log

          result.running!

          Mutx::Support::Log.debug "[result:#{result.id}] setted as running" if Mutx::Support::Log

          @output = ""

          #################
          # POPEN3 ref
          # http://blog.honeybadger.io/capturing-stdout-stderr-from-shell-commands-via-ruby/?utm_source=rubyweekly&utm_medium=email
          ##################
          @count = 0

          # Update repo if changes are found
          ##if Mutx::Support::Configuration.use_git?
          ##  Mutx::Support::Git.pull unless Mutx::Support::Git.up_to_date?
          ##end # PULL COMMENTED

          ## Belgranos's VM ##
          if Mutx::Support::Configuration.specific_vm.eql? true #"10.0.60.36"
            Mutx::Support::Console.execute Mutx::Support::Configuration.proxy_one
            Mutx::Support::Console.execute Mutx::Support::Configuration.proxy_two
          end

          Mutx::Support::TimeHelper.start # Sets timestamp before start process
          Mutx::Support::Log.debug "[result:#{result.id}] Creating process" if Mutx::Support::Log

          #USE 'PTY' GEM INSTEAD POPEN TO READ OUTPUT IN REAL TIME
          @uname = Mutx::Support::Console.execute "uname"
          @start_time = Time.now
          begin
            PTY.spawn("#{result.mutx_command}") do |stdout, stdin, pid|
              result.pid ="#{`ps -fea | grep #{Process.pid} | grep -v grep | awk '$2!=#{Process.pid} && $8!~/awk/ && $3==#{Process.pid}{print $2}'`}"
              result.save!
              begin
                stdout.each { |line|
                  Mutx::Support::Console.execute "sudo sysctl -w vm.drop_caches=3" if @uname.include? "Linux" #Free memo only Linux
                  @output += line
                  @output.slice! "fatal: Not a git repository (or any of the parent directories): .git"
                  #if Mutx::Support::TimeHelper.elapsed_from_last_check_greater_than? 5
                    result.append_output @output.gsub(/(\[\d{1,2}\m)/, "")
                    @output = ""
                  #end
                  if result.seconds_without_changes > Mutx::Support::Configuration.execution_time_to_live
                    result.finished_by_timeout! and break
                  end
                }
                result.append_output @output unless @output.empty?
                result.append_output "=========================\n"
              rescue Errno::EIO, Errno::ENOENT => e
              end
            end
          rescue PTY::ChildExited, Errno::ENOENT => e
            cmd = result.mutx_command.match(/(\D*)\_/)[0].delete"_"
            @output = "EXCEPTION: #{e.message} for the command requested for you: #{cmd.upcase}"
            result.append_output @output unless @output.empty?
            result.append_output "\n\n=========================\n"
          end

          result.ensure_finished!

          puts result.summary

          task = Mutx::Database::MongoConnector.task_data_for result.task[:id]
          subject = if ((task[:subject].empty?) || (task[:subject].nil?))
            task[:name]
          else
            task[:subject]
          end

          email = task[:mail]
          type = task[:type]
          name = task[:name]
          id = task[:_id]
          cucumber = task[:cucumber]
          notify_on = task[:notify_on]
          
          if ( (task["notifications"]) && (!result.regex.empty?) && (result.console_output.to_s.include? "#{result.regex.to_s}") )
            Mutx::Database::MongoConnector.mark_notified (result_id)
            Mutx::Workers::EmailSender.perform_async(result_id, subject, email, name, id, type, cucumber, notify_on, attach_folder) if ((task[:notifications].eql? "on") && (!email.empty?))
          elsif ( (task["notifications"]) && (!result.regex.empty?) && (!result.console_output.to_s.include? "#{result.regex.to_s}") )
            puts "****Result not to being notified, because regex #{result.regex.to_s} not included on output****"
          elsif ( (task["notifications"]) && (result.regex.empty?) )
            #task[:notifications] = "on" #Workaround until solve regex problem
            Mutx::Database::MongoConnector.mark_notified (result_id)
            Mutx::Workers::EmailSender.perform_async(result_id, subject, email, name, id, type, cucumber, notify_on, attach_folder) if ((task[:notifications].eql? "on") && (!email.empty?))
          end

          Mutx::Support::Log.debug "[result:#{result.id}]| command => #{result.mutx_command} | result as => #{result.status}" if Mutx::Support::Log
          
          ###Mutx::Database::MongoConnector.force_close
        end
    end
  end
end