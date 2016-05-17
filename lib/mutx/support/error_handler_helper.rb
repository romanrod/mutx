module Mutx
  module Support
    class ErrorHandlerHelper

      def self.evaluate exception
        case exception
          # when Mongo::ConnectionTimeoutError
          #   ["Timeout Error","Could not connect to database"]
          when Psych::SyntaxError
            ["Parse Error","Cucumber.yml file is not configured correctly (#{exception.message})"]
          when Mutx::Error::TaskNotFound
            ["Task Name Error",exception.message]
          when Mutx::Error::Result
            ["Result Error", excetion.message]
          when Mutx::Error::MutxFile
            ["Mutx File", exception.message]
          when Mutx::Error::MutxDir
            ["Mutx File", exception.message]
          when Mutx::Error::Help
            ["Help Error", exception.message]
          else
            ["Unknown Error", "#{exception.message}#{exception.backtrace}"]
        end
      end
    end
  end
end


