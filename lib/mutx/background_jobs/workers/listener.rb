# enconding: utf-8
require 'mutx'
require 'socket'

module Mutx
  module Workers
    class Listener
      include Sidekiq::Worker
        def perform(result_id)


          tcp_port = result.id.to_s[-4..-1].to_i

          #server = TCPServer.new tcp_port # Server bound to port tcp_port

          ###########################
          #begin
          #

          server = TCPServer.new tcp_port # Server bound to port tcp_port

          @running = true

          Thread.start("#{result.mutx_command}") do |command|


          end


        end
    end
  end
end
