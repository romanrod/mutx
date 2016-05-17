module Mutx
  module Commands
    def self.install origin=nil

      begin


        Mutx::TaskRack.start([])

        puts "

        A new folder called mutx was created. Check the configuration file under config/ folder with the name mutx.conf.
        You'll find some configuration values there. Take a look and set your preferences!
        Enjoy Mutx
        Thanks
        "
        puts "Now, you can run bundle install and then `mutx start` command"

      rescue => e
        puts "\n\nERROR: #{e}\n\n #{e.backtrace}"

      end
    end
  end
end