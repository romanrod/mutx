# encoding: utf-8
require 'mutx'
require 'socket'
require 'sidetiq'
require 'chronic'

module Mutx
  module Workers
    class MutxCron
      include Sidekiq::Worker
      include Sidetiq::Schedulable

      recurrence { minutely(1) }

        def perform
          running_task = []
          running_task = Mutx::Database::MongoConnector.running_now

          puts "######### STARTING CRON ##########"

          if running_task.eql? []

            @days = [:mo,:tu,:we,:th,:fr,:sa,:su]
            @today = day_name #name of today

            #BEGIN# Select only cronned tasks that last_exec_time is OK to run
            cron_tasks = []
            cron_tasks_list = Mutx::Database::MongoConnector.cron_tasks

            puts "#{cron_tasks_list.size} cronned task searched"

            cron_tasks_list.select{|line| cron_tasks << line if (((Time.now.utc - line[:last_exec_time].utc) + 1) >= (line[:cron_time].to_i * 60))}
            cron_tasks_list = []
            cron_tasks_list = cron_tasks
            puts "#{cron_tasks_list.size} POSSIBLE cronned task on time to run"
            #END# Select only cronned tasks that last_exec_time is OK to run

            #BEGIN# REMOVING POSSIBLE DUPLICATED TASKS
            cron_tasks_list_aux = []
            cron_tasks_list_aux = cron_tasks_list
            cron_tasks_list = []
            cron_tasks_list = cron_tasks_list_aux.uniq { |line| [line[:name]].join(":") }

            puts
            puts "REMOVING DUPLICATED TASKS WITH SAME NAME" if !cron_tasks_list_aux.size.eql? cron_tasks_list.size
            puts "#{cron_tasks_list.size} cronned task after removing possible duplicated tasks"
            #END# REMOVING POSSIBLE DUPLICATED TASKS

            #BEGIN#Check if task is running or started
            cron_tasks = []
            cron_tasks_list.select{|line| cron_tasks << line if ((Mutx::Database::MongoConnector.running_for_task line[:name]) && (Mutx::Database::MongoConnector.only_started_for_task line[:name]) && (Mutx::Database::MongoConnector.only_running_for_task line[:name])).eql? []}
            cron_tasks_list = []
            cron_tasks_list = cron_tasks
            puts "#{cron_tasks_list.size} cronned task ready to run (not running or started)"
            #END#Check if task is running or started

            # TASK must be right on time to run and unique
            cron_tasks_list.each do |task|
              @@now_time = Time.now.hour.to_s+":"+Time.now.min.to_s
              @@now_time = ("0" + @@now_time.match(/\d*/).to_s + ":" + @@now_time.match(/\:(\d*)/)[1].to_s) if @@now_time.match(/(\d*)/)[1].size.eql? 1
              @@now_time = (@@now_time.match(/\d*/).to_s + ":0" + @@now_time.match(/\:(\d*)/)[1].to_s) if @@now_time.match(/\:(\d*)/)[1].size.eql? 1
              @@last_exec_time = nil
              @@last_exec_time = task[:last_exec_time]
              # Update last_exec_time before to run (because this task is OK to run)
              Mutx::API::Tasks.cron_update task if (((Time.now.utc - @@last_exec_time.utc) + 1) >= (task[:cron_time].to_i * 60))        
              @none_day = true

                sleep 1
                validate_and_execute task

            end#cron_task

            Mutx::Database::MongoConnector.force_close
            puts "######### ENDING CRON ##########"
          else ## si hay algo corriendo deja pasar toda la ejecucion hasta que finalice
            puts
            puts "HAY EJECUCIONES EN RUNNING O STARTED, SE ESPERA A QUE TERMINEN..."
            puts
            puts "######### ENDING CRON ##########"
          end

        end #perform


        def day_name()
          num = Chronic.parse("today").wday
          return "mo" if num.eql? 1
          return "tu" if num.eql? 2
          return "we" if num.eql? 3
          return "th" if num.eql? 4
          return "fr" if num.eql? 5
          return "sa" if num.eql? 6
          return "su" if num.eql? 0
        end

        def execute task
          query_string = {}
          query_string = {"execution_name"=>"CRONNED-#{task[:cron_time]}-min"}
          task_name = task[:name]
          task_name.gsub!("%20"," ")
          puts
          puts "EXECUTING: #{task_name} right now"
          puts
          #puts Mutx::API::Tasks.cron_update task
          Mutx::API::Execution.start task_name, query_string
        end

        def check_range_time task
          init_hour = task[:start_time].match(/(\d*)/)[0]
          stop_hour = task[:stop_time].match(/(\d*)/)[0]
          @valid_hours_init = nil
          @valid_hours_stop = nil
          @valid = nil

          @valid_hours_init = [init_hour.to_i]
          (24-init_hour.to_i).times do
            if @valid_hours_init.last.eql? 23
              @valid_hours_init << 00
            else
              @valid_hours_init << @valid_hours_init.last + 1
            end
          end

          @valid_hours_stop = [stop_hour.to_i] 
          (stop_hour.to_i-1).times do
            @valid_hours_stop << @valid_hours_stop.last - 1
          end

          @valid = @valid_hours_init + @valid_hours_stop.reverse
          @valid.pop

          if @valid.include? @@now_time.match(/(\d*)/)[0].to_i
            puts
            puts @valid
            puts @@now_time
            execute task
          else
            puts
            puts @valid
            puts "Actual time: #{@@now_time}"
            puts "ACTUAL TIME IS OUT OF RANGE FOR: #{task[:name]}"
          end
        end

        def validate_and_execute task

        @days.detect{|day| @none_day = "task_with_day" if task[:"#{day}"]}

        # If no day execution is seted, works as always
        if (((!task[:cron_time].eql? "") && (!task[:cron_time].eql? "0")) && (((Time.now.utc - @@last_exec_time.utc) + 1) >= (task[:cron_time].to_i * 60)) && (@none_day.eql? true))
          execute task
        # If there is a day seted, and that day is today, and no execution time is seted
        elsif (((!task[:cron_time].eql? "") && (!task[:cron_time].eql? "0")) && (((Time.now.utc - @@last_exec_time.utc) + 1) >= (task[:cron_time].to_i * 60)) && (@none_day.eql? "task_with_day") && (task[:"#{@today}"].eql? "on") && (task[:start_time].empty?) && (task[:stop_time].empty?))
          execute task
        # If there is a day seted, and that day is today, and execution range time is seted
        elsif (((!task[:cron_time].eql? "") && (!task[:cron_time].eql? "0")) && (((Time.now.utc - @@last_exec_time.utc) + 1) >= (task[:cron_time].to_i * 60)) && (@none_day.eql? "task_with_day") && (task[:"#{@today}"].eql? "on") && (!task[:start_time].nil?) && (!task[:stop_time].nil?) )
          if task[:start_time] > task[:stop_time] #initial time is greater than stop time
            check_range_time task
          elsif (@@now_time.between? task[:start_time], task[:stop_time]) #stop time is greater than initial time
            execute task
          else
            puts "Out of date range for: #{task[:name]}"
          end
        end#if

        end#validate

        def delete_started started_task
          started_task.each do |task|
            Mutx::Database::MongoConnector.delete_started_result task["_id"]
          end
        end#delete_started


    end
  end
end