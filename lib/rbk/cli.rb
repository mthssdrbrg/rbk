# encoding: utf-8

module Rbk
  class Cli
    def self.run(argv=ARGV, options={})
      new(argv, options).setup.run
    end

    def initialize(argv, options={})
      @argv = argv
      @options = options
    end

    def setup
      config = Configuration.parse(@argv)
      repos = github.new(oauth_token: config.github_access_token)
      @repo_list = repos.list(org: config.organization, auto_pagination: true)
      @git = @options[:git] || Git
      @archiver = Archiver.new
      @uploader = Uploader.new(s3.buckets[config.bucket])
      self
    end

    def run
      Backup.new(@repo_list, @git, @archiver, @uploader).run
    end

    private

    def s3
      @s3 ||= @options[:s3] || AWS::S3.new
    end

    def github
      @github ||= @options[:github_repos] || Github::Repos
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
