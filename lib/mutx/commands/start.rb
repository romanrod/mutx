# encoding: utf-8
module Mutx
  module Commands
    def self.start nodemon=false

        # Check if mutx is already running, proceed to start if not    
        pids = (Mutx::Support::Processes.sidekiq_pids).concat(Mutx::Support::Processes.mutx_pids)
        
        if pids.size > 0
            puts "It seems that MuTX is already running"
            puts "Please, run `mutx stop` command before starting MuTX"
        else
          Mutx::Support::Log.start

          Mutx::Support::Log.debug "Starting Mutx" if Mutx::Support::Log
          begin

            Mutx::Support::Configuration.new

            Mutx::Support::Log.debug "Starting...\n\n#{Mutx::Support::Logo.logo}" if Mutx::Support::Log

            Mutx::Support::Log.debug "Checking config.ru file existance" if Mutx::Support::Log
            raise "ERROR --- mutx/config.ru file was not found. Try with `mutx prepare` command before `mutx start`" unless File.exist?("#{Dir.pwd}/mutx/config.ru")

            Mutx::Support::Log.debug "Checking unicorn.rb file existance" if Mutx::Support::Log
            raise "ERROR --- mutx/unicorn.rb file was not found. Try with `mutx prepare` command before `mutx start`" unless File.exist?("#{Dir.pwd}/mutx/unicorn.rb")

            Mutx::Support::Logo.show

            Mutx::Support::Configuration.show_configuration_values


            Mutx::Support::Log.debug "Connecting to database" if Mutx::Support::Log
            Mutx::Database::MongoConnector.new(Mutx::Support::Configuration.db_connection_data)


            Mutx::Support::Log.debug "Loading doc" if Mutx::Support::Log
            Mutx::Support::Documentation.load_documentation

            if Mutx::Support::Configuration.headless?
              Mutx::Support::Log.debug "Headless mode: ON - Checking xvfb existance" if Mutx::Support::Log
              begin
                res = Mutx::Support::Console.execute "xvfb-run"
                if res.include? "sudo apt-get install xvfb"
                  puts "You have configured headless mode but xvfb package is not installed on your system.
        Please, install xvfb package if you want to run browsers in headless mode
        or set headless active value as false if you do not use browser in your tests."  
                  return 
                end
              rescue
                # if mac, show option
                puts "Not Ubuntu OS :(\n xvfb will not work"
              end
            end

            puts "\n"
            Mutx::Support::Log.debug "Cleanning old mutx report files" if Mutx::Support::Log
            Mutx::Support::FilesCleanner.delete_mutx_reports()
            Mutx::Support::Log.debug "Old mutx report files cleanned" if Mutx::Support::Log


            Mutx::Support::Log.debug "Cleanning old mutx console files" if Mutx::Support::Log
            Mutx::Support::FilesCleanner.delete_console_outputs_files()
            Mutx::Support::Log.debug "Old mutx console files cleanned" if Mutx::Support::Log

            Mutx::Support::Log.debug "Clearing mutx log file" if Mutx::Support::Log
            Mutx::Support::FilesCleanner.clear_mutx_log
            Mutx::Support::Log.debug "Mutx log file cleanned" if Mutx::Support::Log


            Mutx::Support::Log.debug "Clearing sidekiq log file" if Mutx::Support::Log
            Mutx::Support::FilesCleanner.clear_sidekiq_log
            Mutx::Support::Log.debug "Sidekiq log file cleanned" if Mutx::Support::Log


            # Force results to reset or finished status
            Mutx::Support::Log.debug "Reseting defunct executions" if Mutx::Support::Log
            Mutx::Results.reset!
            Mutx::Support::Log.debug "Defunct execution reseted" if Mutx::Support::Log
            puts "\n* Results: Reseted".green

            mutx_arg = "-D" unless nodemon

            Mutx::Support::Log.debug "Starting Sidekiq" if Mutx::Support::Log
            Mutx::BackgroundJobs::Sidekiq.start
            Mutx::Support::Log.debug "Sidekiq Started" if Mutx::Support::Log

            # Start mutx app
            Mutx::Support::Log.debug "Starting Mutx" if Mutx::Support::Log
            Mutx::Support::Console.execute "unicorn -c #{Dir.pwd}/mutx/unicorn.rb -p #{Mutx::Support::Configuration.port} #{mutx_arg} mutx/config.ru"
            #Mutx::Support::Console.execute "rackup mutx/config.ru"
            Mutx::Support::Log.debug "Mutx started" if Mutx::Support::Log

            # Save all mutx pids
            Mutx::Support::Log.debug "Saving PIDs for Mutx" if Mutx::Support::Log
            File.open("#{Dir.pwd}/mutx/mutx_pids", "a"){ |f| f.write Mutx::Support::Processes.mutx_pids.join("\n")}
            Mutx::Support::Log.debug "Mutx PIDs saved" if Mutx::Support::Log

            puts "\n\n* Mutx is succesfully Started!\n".green
            if $IP_ADDRESS
                puts "\n\n You can go now to http://#{$IP_ADDRESS}:#{Mutx::Support::Configuration.port}/mutx\n\n"
                Mutx::Support::Log.debug "You can go now to http://#{$IP_ADDRESS}:#{Mutx::Support::Configuration.port}/mutx" if Mutx::Support::Log
            end
            
            Mutx::Database::MongoConnector.force_close

          rescue => e
            Mutx::Support::Log.error "Error starting Mutx: #{e}#{e.backtrace}" if Mutx::Support::Log
            puts "An error ocurred while starting Mutx. See mutx log for more information.#{e} #{e.backtrace}".red
            Mutx::Database::MongoConnector.force_close
          end
      end
    end
  end
end
