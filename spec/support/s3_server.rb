# encoding: utf-8

require 'fakes3'

module FakeS3
  class FileStore
    def puts(*args)
    end
  end

  class XmlAdapter
    def self.append_objects_to_list_bucket_result(lbr, objects)
      return if objects.nil?

      objects.each do |s3_object|
        lbr.Contents do |contents|
          contents.Key(s3_object.name)
          contents.LastModified(s3_object.modified_date)
          contents.ETag("\"#{s3_object.md5}\"")
          contents.Size(s3_object.size)
          contents.StorageClass("STANDARD")

          contents.Owner do |owner|
            owner.ID("abc")
            owner.DisplayName("You")
          end
        end
      end
    end
  end
end

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
        @server.mount '/', FakeS3::Servlet, @store, 'localhost'
        @server.start
      end
      wait_for_server_start
    end

    def stop
      @server.shutdown
      @thread.join
    end

    private

    def wait_for_server_start(max_attempts=10)
      attempts = 0
      begin
        RestClient.get('http://localhost:5000')
      rescue RestClient::Exception
        attempts += 1
        if attempts > max_attempts
          fail('Server did not start!')
        else
          sleep(0.1)
          retry
        end
      end
    end
  end
end
