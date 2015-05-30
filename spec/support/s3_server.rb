# encoding: utf-8

require 'fakes3'


module Support
  class S3Server
    def initialize(root_dir, port)
      FileUtils.mkdir_p(root_dir)
      @store = FakeS3::FileStore.new(root_dir)
      @server = WEBrick::HTTPServer.new({
        BindAddress: '0.0.0.0',
        Port: port,
        Logger: WEBrick::Log.new('/dev/null'),
        AccessLog: [],
      })
    end

    def start
      @thread = Thread.new do
        capture do
          @server.mount '/', FakeS3::Servlet, @store, 'localhost'
          @server.start
        end
      end
    end

    def stop
      @server.shutdown
      @thread.join
    end

    private

    def capture(stream=:stdout, &block)
      s = nil
      begin
        stderr, stdout, $stderr, $stdout = $stderr, $stdout, StringIO.new, StringIO.new
        result = (stream == :stdout) ? $stdout : $stderr
        yield
        s = result.string
      ensure
        $stderr, $stdout = stderr, stdout
      end
      puts s if ENV['SILENCE_LOGGING'] == 'no' && !s.empty?
      s
    end
    alias_method :silence, :capture
  end
end
