# encoding: utf-8
module Mutx
  module API

    class Task

      def self.info(task_id)
        response = {
          "project_name" => Dir.pwd.split("/").last,
          "task" => nil,
          "message" => nil
        }
        task = Mutx::Tasks::Task.get(task_id)
        Mutx::Support::Log.debug "Task info for '#{task_id}'"
        if task.nil?
          response["message"] = "Task not found"
        else
          response["task"] = task.api_response
        end
        response
      end

      def self.info_for_name task_name
        Mutx::Support::Log.debug "Asked info for '#{task_name}'"
        task_id = Mutx::Tasks.task_id_for(task_name)
        self.info(task_id)
      end


      def self.status task_id
        Mutx::Support::Log.debug "Task status for '#{task_i}'"
        response = info(task_id)

        output = if response["message"]
          {
            "task_id" => nil,
            "message" => response["message"]
          }
        else
          {
            "task_id" => response["task"]["_id"],
            "status" => response["task"]["status"]
          }
        end
        output
      end
    end
  end
end

