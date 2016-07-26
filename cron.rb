require 'mutx'

module Cron
	class Tasks

		def self.cron_jobs
		  cron_tasks_list = Mutx::Database::MongoConnector.cron_tasks

		  cron_tasks_list.each do |task|
		  	if (((!task[:cron_time].eql? "") && (!task[:cron_time].eql? "0")) && (((Time.now.utc - task[:last_exec_time].utc) + 1) >= (task[:cron_time].to_i * 60)))
		  		  query_string = {}
		  		  query_string = {"execution_name"=>"CRONNED-#{task[:cron_time]}-min"}
		  		  task_name = task[:name]
		        task_name.gsub!("%20"," ")
		        puts Mutx::API::Tasks.cron_update task
		        Mutx::API::Execution.start task_name, query_string
		    end
		  end
		end
	end#class
end#module

Cron::Tasks.cron_jobs