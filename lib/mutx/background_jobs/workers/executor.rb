# encoding: utf-8
require 'mutx'
require 'socket'

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

          result.mutx_report_file_name= "mutx_report_#{result_id}.html"

          if result.is_ruby_platform?
            if Mutx::Platforms::Ruby.using_bundler?
              bundle_output = Mutx::Support::Console.execute "bundle install"
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
          efective_command << "_id=#{result.id}" # to use inside execution the posiibility to add information to the result
                    
          result.mutx_command= efective_command.join(" ")

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
          if Mutx::Support::Configuration.use_git?
            Mutx::Support::Git.pull unless Mutx::Support::Git.up_to_date?
          end

          Mutx::Support::Log.debug "[result:#{result.id}] Creating process" if Mutx::Support::Log
          IO.popen("#{result.mutx_command}") do |data|
            result.pid ="#{`ps -fea | grep #{Process.pid} | grep -v grep | awk '$2!=#{Process.pid} && $8!~/awk/ && $3==#{Process.pid}{print $2}'`}"
            result.save!

            while line = data.gets
              @count += 1
              @output += line
              if @count == 30
                result.append_output @output
                @output = ""
                @count = 0
              end
              if result.seconds_without_changes > Mutx::Support::Configuration.execution_time_to_live
                result.finished_by_timeout! and break
              end
            end

            result.append_output @output unless @output.empty?
            result.append_output "=========================\n"
          end

          result.ensure_finished!
          task = Mutx::Tasks::Task.get(result.task_id)

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
          
          Mutx::Workers::EmailSender.perform_async(result_id, subject, email, name, id, type, cucumber) if ((task[:notifications].eql? "on") && (!email.empty?))

          Mutx::Support::Log.debug "[result:#{result.id}]| command => #{result.mutx_command} | result as => #{result.status}" if Mutx::Support::Log

        end
    end
  end
end