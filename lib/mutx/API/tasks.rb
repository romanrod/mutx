# enconding: utf-8
module Mutx
  module API
    module Tasks

      def self.set data

        data = self.sanitize data

        response = case data["action"]
        when "new"
          Mutx::Tasks::Task.validate_and_create(data)
        when "edit"
          Mutx::Tasks::Task.validate_and_update(data)
        when "delete"
          Mutx::Tasks::Task.delete_this(data)
        end
        response
      end

      def self.cron_update data
        data = self.sanitize data
        res = Mutx::Tasks::Task.validate_and_update(data)
      end

      def self.sanitize data
        data["max_execs"] = data["max_execs"].to_i if data["max_execs"].respond_to? :to_i
        data["cucumber_report"] = data["cucumber"]
        data["information"] = nil if data["information"].size.zero?
        data["last_exec_time"] = Time.now.utc
        data
      end

      # @param [hash] options = {:running, :active, :type}
      def self.list(options ={})

        type = options[:type]

        start = Time.now.to_f

        response = {
          "project_name" => Dir.pwd.split("/").last,
          "size" => 0,
          "type" => type,
          "tasks" => [],
          "message" => nil
        }
        tasks = if options[:running]
          type = options[:type]
          response["request"] = "Running #{type.capitalize}"
          if type == "task"
            Mutx::Tasks.running_tasks
          else
            Mutx::Tasks.running_tests
          end
        else
          response["request"] = options[:type] ? "#{options[:type].capitalize} Tasks" : "Tasks"
          Mutx::Tasks.tasks options[:type]
        end


        if tasks.size.zero?
          response["message"] = options[:running] ? "Running tasks not found" : "Tasks not found"
        else

          tasks = tasks.map do |task|
            results_for_task = Mutx::Results.results_ids_for task["_id"]
            task["results"]={
              "size" => results_for_task.size,
              "ids" => results_for_task
            }
            task
          end

          response["tasks"] = tasks
          Mutx::Support::Log.debug "#{tasks.size} retrieved in (#{Time.now.to_f - start} s)" if Mutx::Support::Log

          response["size"] = tasks.size
        end
        response
      end

    end
  end
end
