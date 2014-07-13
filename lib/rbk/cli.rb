# encoding: utf-8

module Rbk
  class Cli
    def self.run(argv=ARGV, options={})
      new(argv, options).setup.run
    end

    def initialize(argv, options={})
      @argv = argv
      @options = options
      @git = @options[:git] || Git
      @s3 = @options[:s3] || AWS::S3.new
      @github = @options[:github_repos] || Github::Repos
    end

    def setup
      config = Configuration.parse(@argv)
      @repos = list_repos(config)
      @archiver = Archiver.new
      @uploader = Uploader.new(@s3.buckets[config.bucket])
      self
    end

    def run
      Backup.new(@repos, @git, @archiver, @uploader).run
    end

    private

    def list_repos(config)
      r = @github.new(oauth_token: config.github_access_token)
      r.list(org: config.organization, auto_pagination: true)
    end

    class Archiver
      def initialize
        @shell = Shell.new
      end

      def create(path)
        archive = %(#{path}.tar.gz)
        @shell.exec(%(tar czf #{archive} #{path}))
        archive
      end
    end

    class Uploader
      def initialize(bucket)
        @bucket = bucket
        @date_prefix = Date.today.strftime('%Y%m%d')
      end

      def upload(path)
        s3_object = @bucket.objects[[@date_prefix, path].join('/')]
        s3_object.write(Pathname.new(path))
      end
    end
  end
end
