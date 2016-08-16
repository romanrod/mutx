# encoding: utf-8
require 'mutx'
require 'mail'
require 'erb'
require 'ostruct'
#require 'sidekiq/testing/inline'

module Mutx
  module Workers
    class EmailSender
      include Sidekiq::Worker
      def perform(result_id, subject, email, name, id)

        Mail.defaults do
          delivery_method :smtp, {
          address:              Mutx::Support::Configuration.smtp_address,
          port:                 Mutx::Support::Configuration.smtp_port,
          domain:               Mutx::Support::Configuration.smtp_domain,
          user_name:            Mutx::Support::Configuration.smtp_user,
          password:             Mutx::Support::Configuration.smtp_password,
          authentication:       Mutx::Support::Configuration.smtp_autentication,
          enable_starttls_auto: Mutx::Support::Configuration.smtp_enanle_start_tls_auto
          }
        end

        result = Mutx::Results::Result.get(result_id)

        template_path = (`pwd`+"/mutx/templates/mutx_template.html.erb").delete"\n"

        output = result.console_output
        status = result.status      

        #seteo el template
        mail = Mail.new
        mail.content_type "multipart/mixed;"

        data = OpenStruct.new(output: output, task_name: name, id: id, time: result.elapsed_time, status: status)
        html_part = Mail::Part.new
        html_part.content_type = "text/html; charset=UTF-8"
        template = File.read(template_path)
        html_part.body = ERB.new(template).result(data.instance_eval { binding })
        mail.html_part = html_part
        #fin seteo template
        mail.from 'Mutx <your@email.sender.org>'
        mail.to "#{email}"

        mail.subject = "[MuTX] ==> #{subject}"

        File.open("result.html", "w") { |file| file.write("#{html_part.body}") }

        mail.add_file "result.html"

        html_part.body "\nA continuacion se adjunta el resutado de la ejecucion solicitada. -.Equipo [MuTX].-"

        puts "ENVIANDO RESULTADO VIA MAIL"

        tries = 3
        begin
          mail.deliver!#send mail
        rescue StandardError
          tries -= 1
          if tries > -
            puts
            puts "Reintentando envio de mail"
            puts
            retry
          end
        raise
        end

      end
    end
  end
end