# encoding: utf-8

module Rbk
  class Shell
    def initialize(quiet=false, stream=$stdout)
      @quiet = quiet
      @stream = stream
    end

    def puts(message)
      @stream.puts(message) unless @quiet
    end

    def exec(command)
      output = %x(#{command})
      unless $?.success?
        raise ExecError, output
      end
      output
    end
  end
end
