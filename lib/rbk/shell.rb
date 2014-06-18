# encoding: utf-8

module Rbk
  class Shell
    def exec(command)
      output = %x(#{command})
      unless $?.success?
        raise ExecError, output
      end
      output
    end
  end
end
