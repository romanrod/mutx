# encoding: utf-8
# encoding: utf-8

module Mutx
  module Support
    module Logo
      def self.show
        puts self.logo
      end

      def self.logo
        "
 __  __    _________   __
|  \\/  |  |__   __\\ \\ / /
| \\  / |_   _| |   \\ V / 
| |\\/| | | | | |    > <  
| |  | | |_| | |   / . \\ 
|_|  |_|\\__,_|_|  /_/ \\_\
                          
                          
             Version #{Mutx::VERSION}
  "
      end
    end
  end
end