# encoding: utf-8
require "cuba"
#include Basica

Cuba.plugin Basica

include Mote::Helpers

# Mutx::Support::Log.start
Mutx::Support::Configuration.get

Mutx::Database::MongoConnector.new Mutx::Support::Configuration.db_connection_data

Cuba.define do

  $tasks_counter = 0

  request = Mutx::Support::Request.new(req)

  Mutx::Support::Log.debug "REQUEST '#{request.request}" if Mutx::Support::Log

  begin

# ========================================================================
# COMMON INIT
#
#
    on post do

      on "admin/config/reload" do
        on true do
          # Guarda el nuevo archivo de configuración si es válido
          Mutx::Support::Configuration.get
        end
      end

      on "admin/config/save" do
        on true do
          data = req.params.dup
          # Validar la data recibida
          # Insertar un nuevo registro y deshabilitar el resto
        end
      end

      on "admin/delete-custom-param" do
        on true do
          data = req.params.dup
          response = Mutx::API::CustomParams.set data # Creates or update

          path = "/admin/custom/params"
          path += "?msg=#{response[:message]}" if response[:message]

          res.redirect path
        end

      end

      # TO EDIT OR CREATE CUSTOM PARAM
      on "admin/custom-param" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "data is => #{data}"

          response = Mutx::API::CustomParams.set data # Creates or update

          path = "/admin/custom/params"

          # Si success es true
          Mutx::Support::Log.debug "#{response}"

          unless response[:success]

            path += "/#{data['_id']}" if data["_id"]
            path += "/#{data['action']}"
          end
          path += "?msg=#{response[:message]}"

          path += "&name=#{data['name']}&action=#{data['action']}&type=#{data['type']}&value=#{data['value']}&options=#{data['options']}&required=data['required']&clean=false" unless response[:success]

          res.redirect path

        end

      end


      on "admin/tasks/add-edit" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "#{data['action']} Task - Recieved data => #{data}"

          # Extracts custom params
          custom_params = data.keys.select do |field|
            field.start_with? "custom_param_" and data.delete(field)
          end.inject([]) do |res, value|
            res<<value.gsub("custom_param_",""); res
          end

          data["custom_params"] = custom_params

          Mutx::Support::Log.debug "DATA SENT TO Task.set is => #{data}"

          response = Mutx::API::Tasks.set data # Creates or update

          Mutx::Support::Log.debug "response => []#{response}"
          
          path = "/admin/tasks"

          Mutx::Support::Log.debug "#{response}"

          unless response[:success]

            path += "/#{data['_id']}" if data["_id"]
            path += "/#{data['action']}"
          else
            path+= "/list"
          end
          path += "?msg=#{response[:message]}"

          path += "&name=#{data['name']}&action=#{data['action']}&type=#{data['type']}&value=#{data['value']}&options=#{data['options']}&required=data['required']&clean=false" unless response[:success]

          res.redirect path

        end
      end

      on "admin/tasks/delete" do

        on true do

          data = req.params.dup

          Mutx::Support::Log.debug "DATA SENT TO Task.delete is => #{data}"

          result = Mutx::Tasks.delete! data["task_id"]
          path = "/admin/tasks/list"

          path += "?msg=#{result[:message]}"

          res.redirect path
        end
      end

      on "api/input/:id" do |id|
        $result = basic_auth(env) do |user, pass|
         user == "inputs" && pass == "InputsAdmin"
        end
        if $result.eql? true
          Mutx::Support::Log.debug "REFERENCE IS => #{id}"
          data = req.params.dup
          data.store("reference", "#{id}")
          Mutx::Support::Log.debug "DATA TO INPUT IS => #{data}"
          response = Mutx::API::Input.validate_and_create data
          Mutx::Support::Log.debug "RESPONSE => #{response}"
          (res.status = 201
          res.write "status 201") if response.to_s.include? "success=>true"
          (res.status = 404
          res.write "status 404") if response.to_s.include? "success=>false"
          Mutx::Support::Log.debug "STATUS CODE => #{res.status}"
        else
         on default do
           res.status = 401
           res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
           res.write "status 401"
           res.write "Access Denied, Mutx don't let you POST without authorization"
         end
        end
      end

    end




    on get do

      on "api/input/:id" do |id|
        query_string = Mutx::Support::QueryString.new req
        output = Mutx::API::Input.get_data(id, query_string.raw)        
        res.write output.to_json
      end

      on "pull" do
        #Check for updates on the branch and make a pull if its outdated
        Mutx::Support::Git.pull unless Mutx::Support::Git.up_to_date?
        res.redirect "/tasks"
      end

      on "logout" do
        $result = nil
        $result = false
        if env["SERVER_NAME"].eql? "localhost"
          $result = false
          a = env["HTTP_REFERER"] || env["REQUEST_URI"]
          logout = a.match(/\D{4,5}:\/\//).to_s+"user:pass@"+env["SERVER_NAME"].to_s+":"+env["SERVER_PORT"].to_s
          res.redirect "#{logout}/"
        else
          $result = false
          res.redirect "http://user@mutx.garba.ninja/"
        end
      end

# ========================================================================
# HELP
#
#
      on "help/:page" do |page|
        args ={page:page}
        template = Mote.parse(File.read("#{Mutx::View.path}/help.mote"),self, [:args])
        res.write template.call(:args => args)
      end

      on "help" do
        res.redirect "/help/main"
      end


# ========================================================================
# VIEW ROUTES
#
#
#
      # INVERTIR /log con  /:result_id

      on "results/:result_id/log" do |result_id|
        template = Mote.parse(File.read("#{Mutx::View.path}/results/console.mote"),self, [:result_id])
        res.write template.call(result_id:result_id)
      end


      # INVERTIR /log con  /:result_id
      on "results/report/:result_id" do |result_id|
        result = Mutx::Results::Result.get(result_id)
        res.redirect "/404/There%20is%20no%20result%20for%20id=#{result_id}" if result.nil?
        result.mark_as_saw! if (result.finished? or result.stopped?)
        if result.finished? and !result.stopped? and result.html_report.size > 0
          template = Mote.parse(File.read("#{Mutx::View.path}/results/report.mote"),self, [:result])
          res.write template.call(result:result)
        #else
        #  res.redirect "results/#{result_id}/log"
        end
      end

      on "results/:result_id/reset" do |result_id|
        task_name = Mutx::Results::Result.get result_id
        task = Mutx::Tasks::Task.get_task_with task_name.task["name"]
        if task.blocked_stop.eql? "on"
          $result = basic_auth(env) do |user, pass|
           user == "mutx" && pass == "mutxAdmin"
          end
          if $result.eql? true
            #begin
              value = Mutx::API::Execution.reset(result_id)
              res.redirect "/results?msg=#{value['message']}"
            #rescue
            #  retry if !value["message"].include? "Stopped"
            #end
          else
           on default do
             res.status = 401
             res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
             res.write "Access Denied, Mutx don't let you stop this execution without authorization"
           end
          end
        else
          #begin
            value = Mutx::API::Execution.reset(result_id)
            res.redirect "/results?msg=#{value['message']}"
          #rescue
          #  retry if !value["message"].include? "Stopped"
          #end
        end
      end

      # Will be modified with api/tasks/:task/results
      on "results/task/:task_name" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        args = {task_name:task_name, query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

      on "results/all" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"All Results", args:args)
      end

      on "results" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

## ========================================================================
# TASKS CRUD
#
#
#

      on "admin/tasks/new" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, action:"new"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Add Task", args:args)
      end

      on "admin/tasks/:task_id/edit" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id, action:"edit"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Task", args:args)
      end

      on "admin/tasks/:task_id/delete" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Delete Task", args:args)
      end

      on "admin/tasks/:task_id/view" do |task_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, task_id:task_id, action:"view"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"View Task", args:args)
      end

      on "admin/tasks" do
         $result = basic_auth(env) do |user, pass|
           user == "mutx" && pass == "mutxAdmin"
         end
         if $result.eql? true
          template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
          res.write template.call(section:"Edit Tasks", args:{:query_string => Mutx::Support::QueryString.new(req)})
         else
           on default do
             res.status = 401
             res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
             res.write "Access Denied, Mutx don't let you go to that place without authorization"
           end
         end
      end

      on "admin/custom/params/new" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, action:"new"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"New Custom Param", args:args)
      end

      on "admin/custom/params/:custom_id/edit" do |custom_param_id|
        query_string = Mutx::Support::QueryString.new req
        res.redirect "/admin/custom/params?msg=Could not find Custom Parameter" unless Mutx::Tasks::Custom::Params.exist? custom_param_id
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"edit"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Custom Param", args:args)
      end

      on "admin/custom/params/:custom_id/delete" do |custom_param_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"delete"}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Delete Custom Param", args:args)
      end

      on "admin/custom/params" do
        $result = basic_auth(env) do |user, pass|
         user == "mutx" && pass == "mutxAdmin"
        end
        if $result.eql? true
          query_string = Mutx::Support::QueryString.new req
          args = {query_string:query_string}
          template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
          res.write template.call(section:"Custom Params", args:args)
        else
         on default do
           res.status = 401
           res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
           res.write "Access Denied, Mutx don't let you go to that place without authorization"
         end
        end
      end

      on "admin/config" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"View Configuration", args:args)
      end

      on "admin/config/edit" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Configuration", args:args)
      end




## ===============================================
# TASKS
#
#

      on "tasks/:task/run" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        result = Mutx::API::Execution.start task_name, query_string.values
        Mutx::Support::Log.debug "result => #{result}"
        path = if result["execution_id"]
         "/message/task/#{result['execution_id']}"
        else
          "/error?msg=#{result['message']}"
        end
        res.redirect path
      end


      on "message/task/:result_id" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, result_id:result_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Task Message", args:args)
      end


      on "tasks/:task_name" do |task_name|
        task = Mutx::Tasks::Task.get_task_with task_name.gsub(/%20/, " ")
        if task.blocked.eql? "on"
          $result = basic_auth(env) do |user, pass|
           user == "mutx" && pass == "mutxAdmin"
          end
          if $result.eql? true
            query_string = Mutx::Support::QueryString.new req
            task_name.gsub!("%20"," ")
            args = {query_string:query_string, task_name:task_name}
            template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
            res.write template.call(section:"Tasks", args:args)
          else
           on default do
             res.status = 401
             res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
             res.write "Access Denied, Mutx don't let you run this execution without authorization"
           end
          end
        else
          query_string = Mutx::Support::QueryString.new req
          task_name.gsub!("%20"," ")
          args = {query_string:query_string, task_name:task_name}
          template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
          res.write template.call(section:"Tasks", args:args)
        end
      end

      on "tasks" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tasks", args:args)
      end

## ========================================================================
# TESTS
#
#
#

      on "tests/:task/run" do |task_name|
        query_string = Mutx::Support::QueryString.new req
        task_name.gsub!("%20"," ")
        result = Mutx::API::Execution.start task_name, query_string.values, "test"
        Mutx::Support::Log.debug "result => #{result}"
        path = if result["execution_id"]
         "/message/test/#{result['execution_id']}"
        else
          "/error?msg=#{result['message']}"
        end
        res.redirect path
      end

      on "message/test/:result_id" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, result_id:result_id}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Test Message", args:args)
      end

      on "tests/:task_name" do |task_name|
        task = Mutx::Tasks::Task.get_task_with task_name.gsub(/%20/, " ")
        if task.blocked.eql? "on"
          $result = basic_auth(env) do |user, pass|
           user == "mutx" && pass == "mutxAdmin"
          end
          if $result.eql? true
            query_string = Mutx::Support::QueryString.new req
            Mutx::Support::Log.debug "task_name => #{task_name}"
            task_name.gsub!("%20"," ")
            args = {query_string:query_string, task_name:task_name}
            template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
            res.write template.call(section:"Tests", args:args)
          else
           on default do
             res.status = 401
             res.headers["WWW-Authenticate"] = 'Basic realm="MyApp"'
             res.write "Access Denied, Mutx don't let you run this execution without authorization"
           end
          end
        else
          query_string = Mutx::Support::QueryString.new req
          Mutx::Support::Log.debug "task_name => #{task_name}"
          task_name.gsub!("%20"," ")
          args = {query_string:query_string, task_name:task_name}
          template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
          res.write template.call(section:"Tests", args:args)
        end
      end

      on "tests" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Tests", args:args)
      end



## ========================================================================
# LOGS
#
#



      on "logs/:log_name" do |log_name|
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string, log_name:log_name}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Log", args:args)
      end

      on "logs" do
        query_string = Mutx::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Mutx::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Logs", args:args)
      end





# ========================================================================
# SCREENSHOTS
#
#

      on "screenshot/:file_name" do |file_name|
        template = Mote.parse(File.read("#{Mutx::View.path}/screenshot.mote"),self, [:file_name])
        res.write template.call(file_name:file_name)
      end

# ========================================================================
# FEATURE SHOW
#
#
      on "features/file" do
        template = Mote.parse(File.read("#{Mutx::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Mutx::Support::QueryString.new(req))
      end

# ========================================================================
# FEATURES / LIST
#
#
      on "features" do
        template = Mote.parse(File.read("#{Mutx::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Mutx::Support::QueryString.new(req))
      end


# ========================================================================
# API ROUTES
#
#
#
      on "api/version" do
        output = { "version" => Mutx::VERSION}
        res.write output.to_json
      end

      on "api/results/:id/data" do |result_id|
        query_string = Mutx::Support::QueryString.new req
        output = Mutx::API::Result.data(result_id, query_string.raw)
        res.write output.to_json
      end

      on "api/results/:id/status" do |result_id|
        output = Mutx::API::Result.status(result_id)
        res.write output.to_json
      end

      on "api/results/:id/output" do |result_id|
        output = Mutx::API::Result.output(result_id)
        res.write output.to_json
      end

      on "api/results/:id" do |result_id|
        res.write(Mutx::API::Result.info(result_id).to_json)
      end

      on "api/results/:id/reset" do |result_id|
        result = Mutx::API::Execution.reset(result_id)
        res.write result.to_json
      end

      on "api/tasks/:id/results" do |task_id|
        result = Mutx::API::Results.for_task_id(task_id)
        res.write result.to_json
      end

      on "api/tasks/:task/run" do |task_name|
        task_name.gsub!("%20"," ")
        query_string = Mutx::Support::QueryString.new req
        result = Mutx::API::Execution.start task_name, query_string.values
        res.write result.to_json
      end

      on "api/tests/:task/run" do |task_name|
        task_name.gsub!("%20"," ")
        query_string = Mutx::Support::QueryString.new req
        result = Mutx::API::Execution.start task_name, query_string.values
        res.write result.to_json
      end

      on "api/tasks/:id/status" do |task_id|
        output = Mutx::API::Task.status(task_id)
        res.write output.to_json
      end

      on "api/tests/:id/status" do |task_id|
        output = Mutx::API::Task.status(task_id)
        res.write output.to_json
      end

      on "api/tasks/running" do
        output = Mutx::API::Tasks.list({running:true, type:"task"})
        res.write output.to_json
      end

      on "api/tests/running" do
        output = Mutx::API::Tasks.list({running:true, type:"task"})
        res.write output.to_json
      end

      on "api/tasks/:id" do |task_id|
        output = Mutx::API::Task.info(task_id)
        res.write output.to_json
      end

      on "api/tests/:id" do |task_id|
        output = Mutx::API::Task.info(task_id)
        res.write output.to_json
      end

      on "api/tasks" do
        output = Mutx::API::Tasks.list({type:"task"})
        res.write output.to_json
      end

      on "api/tests" do
        output = Mutx::API::Tasks.list({type:"test"})
        res.write output.to_json
      end

      on "api/results" do
        output = Mutx::API::Results.show()
        res.write output.to_json
      end

      on "api/custom/params/:name/value" do |name|
        output = {}
        param = Mutx::API::CustomParams.get(name)
        output["app"] = Mutx::Support::Configuration.project_name
        output["request"] = "Custom Parameter value"
        output["custom_param_name"] = param["name"]
        output["value"] = param["value"]
        res.write output.to_json
      end

      on "api/custom/params/:name" do |name|
        output = {}
        param = Mutx::API::CustomParams.get(name)
        output["custom_param"] = param
        output["app"] = Mutx::Support::Configuration.project_name
        res.write output.to_json
      end

      on "api/custom/params" do
        output ={}
        output["custom_params"] = Mutx::API::CustomParams.list()
        output["request"]="Custom Params"
        output["app"]=Mutx::Support::Configuration.project_name
        res.write output.to_json
      end


      on "api/error" do
        query_string = Mutx::Support::QueryString.new req
        output = Mutx::API::Error.show(query_string)
        res.write output.to_json
      end

      on "api" do
        response = {"message" => "Please, refer to /help/api for more information"}
        res.write response.to_json
      end

      on "error" do
        args= {query_string:Mutx::Support::QueryString.new(req), exception:nil}
        template = Mote.parse(File.read("#{Mutx::View.path}/error_handler.mote"),self, [:args])
        res.write template.call(args:args)
      end


# ========================================================================
# CLEAN
#
#
      on "clean" do
        Mutx::Support::Clean.start
        res.redirect "/tasks?msg=Tasks and results cleanned"
      end

# ========================================================================
# REDIRECTS
#
      on "help" do
        res.redirect "/help/main"
      end

      on "404" do
        template = Mote.parse(File.read("#{Mutx::View.path}/not_found.mote"),self, [])
        res.write template.call()
      end

      on "version" do
        res.redirect "api/version"
      end

      on ":any" do
          res.redirect("/tests")
      end

      on "favicon" do
        res.write ""
      end
     
      on root do
        res.redirect "/tasks"
      end

    end

  ##Mutx::Database::MongoConnector.force_close

  rescue => e
    Mutx::Support::Log.error "Cuba: #{e} #{e.backtrace}" if Mutx::Support::Log
    args= {query_string:Mutx::Support::QueryString.new(req), exception:e}
    template = Mote.parse(File.read("#{Mutx::View.path}/error_handler.mote"),self, [:args])
    res.write template.call(args:args)
  end
end