require 'resolv'

# Resolve DNS on host
module Chloride
  class Chloride::Action::ResolveDNS < Chloride::Action
    attr_reader :address, :from

    def initialize(args)
      super

      @address = args[:address]
      @from = args[:from]
    end

    def go(&stream_block)
      @status = :running

      if @from
        begin
          cmd = "getent hosts #{@address}"
          cmd_event = Chloride::Event.new(:action_progress, name)
          msg = Chloride::Event::Message.new(:info, @from, "[#{@from}] #{cmd}\n\n")
          cmd_event.add_message(msg)
          stream_block.call(cmd_event)
          result = @from.execute(cmd, &update_proc(&stream_block))
          @status = (result[:exit_status]).zero? ? :success : :fail
        rescue Timeout::Error, Net::SSH::Disconnect => err
          @status = :fail
          raise(Chloride::RemoteError, "Connection terminated while executing command #{@cmd}: #{err}")
        end
      else
        begin
          Resolv.getaddress(@address)
          @status = :success
        rescue Resolv::ResolvError => _e
          @status = :fail
        end
      end
    end

    def success?
      @status == :success
    end

    def name
      :resolve_dns
    end

    def description
      from = @from || 'localhost'
      "Try to resolve DNS from #{from} to #{@address}"
    end
  end
end
