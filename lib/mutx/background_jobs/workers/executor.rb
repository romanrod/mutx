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
              result.append_output bundle_output
              if bundle_output.include? "Could not find"
                result.finish!
                raise "An error ocurred installing gem while executing bundler"
              end
            end
          end

          Dir.mkdir "#{Dir.pwd}/mutx/temp" unless Dir.exist? "#{Dir.pwd}/mutx/temp"
          cucumber_report_command = result.is_cucumber? ? "-f pretty -f html -o mutx/temp/#{result.mutx_report_file_name}" : ""

          # Adding _id=result.id to use inside execution the posiibility to add information to the result
          result.mutx_command= "#{Mutx::Support::Configuration.headless?} #{result.command} #{cucumber_report_command} #{result.custom_params_values} _id=#{result.id} "

          Mutx::Support::Log.debug "[result:#{result.id}] Creating process" if Mutx::Support::Log

          result.running!

          Mutx::Support::Log.debug "[result:#{result.id}] setted as running" if Mutx::Support::Log

          @output = ""

          #################
          # POPEN3 ref
          #
          # http://blog.honeybadger.io/capturing-stdout-stderr-from-shell-commands-via-ruby/?utm_source=rubyweekly&utm_medium=email
          #
          #
          ##################
          @count = 0
          IO.popen("#{result.mutx_command}") do |data|
            result.pid ="#{`ps -fea | grep #{Process.pid} | grep -v grep | awk '$2!=#{Process.pid} && $8!~/awk/ && $3==#{Process.pid}{print $2}'`}"
            result.save!
            while line = data.gets
              @count += 1
              @output += line
              if @count == 10
                result.append_output @output
                @output = ""
                @count = 0
              end
              if result.seconds_without_changes > Mutx::Support::Configuration.execution_time_to_live
                result.finished_by_timeout! and break
              end
            end
            result.append_output @output unless @output.empty?
          end

          result.ensure_finished!

          Mutx::Support::Log.debug "[result:#{result.id}]| command => #{result.mutx_command} | result as => #{result.status}" if Mutx::Support::Log

        end
    end
  end
end
