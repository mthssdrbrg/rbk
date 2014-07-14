# encoding: utf-8

module Rbk
  class Uploader
    def initialize(bucket, shell, date=Date.today)
      @bucket = bucket
      @shell = shell
      @date_prefix = (date || Date.today).strftime('%Y%m%d')
    end

    def upload(path)
      s3_object = @bucket.objects[[@date_prefix, path].join('/')]
      if s3_object.exists?
        @shell.puts(%(s3://#{@bucket.name}/#{s3_object.key} already exists, skipping...))
      else
        @shell.puts(%(Writing #{path} to s3://#{@bucket.name}/#{s3_object.key}))
        s3_object.write(Pathname.new(path))
      end
    end
  end
end
