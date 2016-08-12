# encoding: utf-8
module Mutx
  module API
    class Execution
      def self.start task_name, query_string, type = nil
        Mutx::Support::Log.debug "Starting task #{task_name}" if Mutx::Support::Log

        git_log = Mutx::Support::Configuration.use_git? ? Mutx::Support::Git.log_last_commit : ""


        unless query_string.empty?

          execution_name = query_string.delete("execution_name") if query_string.has_key? "execution_name"
          query_string.each_pair do |param, value|
            query_string.delete(param) if (value =~ /Enter/ or value.nil? or value == "")
          end
          custom_params = query_string || {}

        else
          execution_name =  nil
          custom_params = {}
        end

        error = false

        if Mutx::Tasks.is_there_task_with? task_name, type
          Mutx::Support::Log.debug "Starting working with task #{task_name}" if Mutx::Support::Log

          task = Mutx::Tasks::Task.get_task_with(task_name)

          task_id = task.id

          type = task.type

          if Mutx::Tasks.number_of_running_executions_for_task(task_name) < task.max_execs

            Mutx::Support::Log.debug "#{task.type.capitalize} #{task_name} is ready to run" if Mutx::Support::Log

            execution_request_data = {
              "platform"        => task.platform,
              "task"            => {"id" => task.id, "name" => task.name, "type" => task.type, "cucumber" => task.cucumber, "platform" => task.platform},
              "execution_name"  => execution_name,
              "custom_params"   => custom_params,
              "git_log"         => git_log,
              "started_message" => "#{task.type.capitalize} #{task.name} started"
            }

            execution_id = Mutx::Execution.run!(execution_request_data)

            task.push_exec execution_id

            task.set_running!

            task.save!

            Mutx::Support::Log.debug "Task #{task_name} setted as running" if Mutx::Support::Log

            started = true
            message = "#{task.type.capitalize} #{task.name} started"
            status = 200
            Mutx::Support::Log.debug "#{task.type.capitalize} #{task.name} started" if Mutx::Support::Log

          else

            execution_id = nil
            started = false
            status = 423
            message = "Max number of concurrent execution reached.
            Cannot run more than #{task.max_execs} executions simultaneously.
            Please wait until one is finalized"
            Mutx::Support::Log.error "Cannot run more than #{task.max_execs} executions simultaneously" if Mutx::Support::Log
          end

        else # No task for  task_name
          Mutx::Support::Log.error "Task not found for name #{task_name}" if Mutx::Support::Log
          started = false
          execution_id = task_id = nil
          status = 404
          error = true
          message = "Task #{task_name} not found"
        end
          {
            "task" => {
              "name" => task_name,
              "id" => task_id,
              "started" => started,
              "type" => type
              },
            "execution_id" => execution_id,
            "message" => message,
            "error" => error,
            "status" => status
          }
      end

      # RESET EXECUTION
      #
      # Kill associated process to the running execution
      # Sets as finished the result and associated task as READY
      #
      def self.reset(result_id)

        Mutx::Support::Log.debug "Reset execution request for #{result_id}"

        result = Mutx::Results::Result.get(result_id)

        task = Mutx::Tasks::Task.get(result.task_id)
        # if is the owner
          if result.process_running? or !result.finished? or !result.stopped?
            begin
              if result.pid
                Mutx::Support::Processes.kill_p(result.pid)
                killed = true
                task.set_ready!
                Mutx::Support::Log.debug "Execution (id=#{result.id}) killed"
              end
            rescue => e
              Mutx::Support::Log.error "#{e}#{e.backtrace}"
            end

            begin
              Mutx::Support::FilesCleanner.delete_report_which_has(result.id)
              Mutx::Support::Log.debug "Execution files(id=#{result.id}) cleanned"
              cleanned = true
            rescue
            end

            result.save_report
            result.reset!("forced"); Mutx::Support::Log.debug "Execution stopped! Mutx restarted"
            result.show_as = "pending"
            result.save!

            # task.set_ready! if Mutx::Results.is_there_running_executions_for? task.name
            if killed 
              message = "Execution: Stopped (forced) "
              message += " Files: Cleanned" if cleanned
            else
              message = "Could not stop execution. Process killing: #{killed}. Files cleanned: #{cleanned}"
              
            end
              
          end
        # else
        #   {"message" => "You are not the owner of this execution"}
        # end
        {"message" => message}
      end

    end
  end
end