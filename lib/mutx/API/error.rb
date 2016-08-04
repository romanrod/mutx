# enconding: utf-8
module Mutx
  module API
    class Error

      # @param [QueryString Object] args =
      #   :msg
      #   :request
      def self.show(args)
        response = {
          "message" => args.msg,
          "request" => args.request
        }
        response
      end
    end
  end
end