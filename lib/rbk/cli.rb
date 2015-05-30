# encoding: utf-8

module Rbk
  class Cli
    def self.run(argv=ARGV, options={})
      new(argv, options).run
    end

    def initialize(argv, options={})
      @argv = argv
      @options = options
      @git = @options[:git] || Git
      @github_repos = @options[:github_repos] || Github::Repos
      @stderr = @options[:stderr] || $stderr
    end

    def run
      @config = Configuration.create(@argv)
      @config.validate
      @shell = @options[:shell] || Shell.new(@config.quiet?)
      @archiver = Archiver.new(@shell)
      @s3 = @options[:s3] || AWS::S3.new(@config.aws_credentials)
      @uploader = Uploader.new(@s3.buckets[@config.bucket], @shell)
      if @config.help?
        @shell.puts(@config.usage)
      else
        Backup.new(repos, git, archiver, uploader, shell).run
      end
      0
    rescue => e
      @stderr.puts(%(#{e.message} (#{e.class})))
      if e.is_a?(InsufficientOptionsError)
        @stderr.puts(@config.usage)
      end
      1
    end

    private

    attr_reader :git, :archiver, :uploader, :shell

    def repos
      @repos ||= begin
        r = @github_repos.new(oauth_token: @config.github_access_token)
        r.list(org: @config.organization, auto_pagination: true)
      end
    end

    class Archiver
      def initialize(shell=Shell.new)
        @shell = shell
      end

      def create(path)
        archive = %(#{path}.tar.gz)
        @shell.exec(%(tar czf #{archive} #{path}))
        archive
      end
    end
  end
end
