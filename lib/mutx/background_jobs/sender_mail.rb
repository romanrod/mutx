# require 'mutx'
# require 'mail'
# require 'erb'
# require 'ostruct'

# module Mutx
#   module BackgroundJobs
#     class Mailer
#       def sender(result_id, subject, email, name, id, type, cucumber, notify_on)

#         if Mutx::Support::Configuration.email_configured?
#           Mail.defaults do
#             delivery_method :smtp, {
#             address:              Mutx::Support::Configuration.smtp_address,
#             port:                 Mutx::Support::Configuration.smtp_port,
#             domain:               Mutx::Support::Configuration.smtp_domain,
#             user_name:            Mutx::Support::Configuration.smtp_user,
#             password:             Mutx::Support::Configuration.smtp_password,
#             authentication:       Mutx::Support::Configuration.smtp_autentication,
#             enable_starttls_auto: Mutx::Support::Configuration.smtp_enable_start_tls_auto
#             }
#           end

#           result = Mutx::Results::Result.get(result_id)

#           if notify_on == "any" or result.result_value == notify_on

#             template_path = (`pwd`+"/mutx/templates/mutx_template.html.erb").delete"\n"
#             template_body_path = (`pwd`+"/mutx/templates/mutx_body_template.html.erb").delete"\n"

#             output = result.console_output
#             status = result.status    

#             info = "Only for TEST executions"
#             (info = output.match(/\d+\sscenarios?\s+([^\/]+)\d\D/)
#             info_1 = info.to_s.delete"=========================" 
#             info = info_1
#             ) if type.to_s.downcase.eql? "test"

#             #sets template
#             mail = Mail.new
#             mail.content_type "multipart/mixed;"
#             mail.from 'Mutx <your@email.sender.org>'
#             mail.to "#{email}"
#             mail.subject = "[MuTX] ==> #{subject}"

#             data = OpenStruct.new(output: output, task_name: name, id: id, time: result.elapsed_time, status: status, info: info)
            
#             if !cucumber.eql? "on"
#               html_part = Mail::Part.new
#               html_part.content_type = "text/html; charset=UTF-8"
#               template = File.read(template_path)
#               html_part.body = ERB.new(template).result(data.instance_eval { binding })
#               #mail.html_part = html_part #Adjunta al mail
#               File.open("result.html", "w") { |file| file.write("#{html_part.body}") }
#               mail.add_file "result.html"
#               #fin seteo template
#             else
#               report = "mutx_report_#{result_id}.html"
#               template_report_path = (`pwd`+"/mutx/temp/#{report}").delete"\n"
#               html_part = Mail::Part.new
#               html_part.content_type = "text/html; charset=UTF-8"
#               #mail.html_part = html_part #Adjunta al mail
#               mail.add_file template_report_path
#               #fin seteo template
#             end

#             html_part = Mail::Part.new
#             html_part.content_type = "text/html; charset=UTF-8"
#             template1 = File.read(template_body_path)
#             html_part.body = ERB.new(template1).result(data.instance_eval { binding })
#             mail.html_part = html_part

#             puts "SENDING RESULT VIA EMAIL"

#             tries = 3
#             begin
#               mail.deliver!#send mail
#             rescue StandardError
#               tries -= 1
#               if tries > -
#                 puts
#                 puts "Reintentando envio de mail"
#                 puts
#                 retry
#               end
#             raise
#             end

#           end # notify_on == "any" or notify_on == "result.result_value"
#         else
#           puts "Misconfiguration on email settings"
#         end
#       end
#     end
#   end
# end
