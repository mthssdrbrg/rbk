# encoding: utf-8

module Rbk
  class Shell
    def initialize(stream=$stdout)
      @stream = stream
    end

    def puts(message)
      @stream.puts(message)
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
