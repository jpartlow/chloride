require 'chloride/errors'
require 'chloride/event'
require 'chloride/action'

# Executes a shell command on the hosts provided. Will block until completion.
module Chloride
  class Action::Execute < Chloride::Action
    attr_reader :results, :hosts

    # TODO: Document args
    def initialize(args)
      super

      @hosts = args[:hosts] || [args[:host]]
      @cmd = args[:cmd]
      @sudo = args[:sudo] || false
    end

    # TODO: Document block format
    def go(&stream_block)
      @status = :running
      @results = {}
      @hosts.each do |host|
        cmd_event = Chloride::Event.new(:action_progress, name)
        msg = if host.localhost
                "[localhost/#{host}] #{@cmd}\n\n"
              else
                "[#{host}] #{@cmd}\n\n"
              end
        cmd_event.add_message(Chloride::Event::Message.new(:info, host, msg))
        stream_block.call(cmd_event)
        @results[host.hostname] = host.execute(@cmd, @sudo, &update_proc(&stream_block))
      end

      @results
    end

    def success?
      @results.all? do |_host, result|
        (result[:exit_status]).zero?
      end
    end

    def error_message(hostname)
      if @results.key?(hostname) && @results[hostname].key?(:stderr)
        @results[hostname][:stderr].strip
      end
    end

    def name
      :execute
    end

    def description
      "Execute `#{@cmd}` on #{@hosts.join(', ')}"
    end
  end
end
