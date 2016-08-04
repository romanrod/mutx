# enconding: utf-8
module Mutx
  module Commands
    def self.help
      Mutx::Support::Log.debug "#{self}:#{__method__}" if Mutx::Support::Log
      puts "

      Mutx has some commands:

        - install
        - start
        - stop
        - restart
        - reset

      Note: If you stop mutx and then you want to get it up and the port you are using is already in use
            you could use the following commands (Ubunutu OS):

                $sudo netstat -tapen | grep :8080

            In this example we use the port 8080. This command will give you the app that is using the port.
            Then you could kill it getting its PID previously."
    end
  end
end