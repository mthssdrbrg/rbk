# encoding: utf-8

require 'optparse'


module Rbk
  class Configuration
    def initialize(config={})
      @config = defaults.merge(config)
      @parser = create_parser
    end

    def self.parse(argv)
      self.load_config.parse(argv).validate
    end

    def self.load_config
      if File.exists?('.rbk.yml')
        new(YAML.load_file('.rbk.yml'))
      elsif File.exists?(File.join(Dir.home, '.rbk.yml'))
        new(YAML.load_file(File.join(Dir.home, '.rbk.yml')))
      else
        new
      end
    end

    def parse(argv)
      @parser.parse(argv)
      self
    end

    def validate
      invalid_option?(@config['bucket'], 'Missing S3 bucket')
      invalid_option?(@config['github_access_token'], 'Missing GitHub access token')
      invalid_option?(@config['organization'], 'Missing organization')
      self
    end

    def method_missing(m, *args, &block)
      if @config.key?(m.to_s)
        @config[m.to_s]
      else
        super
      end
    end

    def help?
      @config['show_help']
    end

    def quiet?
      @config['quiet']
    end

    def usage
      @parser.to_s
    end

    def aws_credentials
      {
        access_key_id: @config['aws_access_key_id'],
        secret_access_key: @config['aws_secret_access_key']
      }
    end

    private

    def invalid_option?(value, message)
      if !help? && (!value || value.empty?)
        raise InsufficientOptionsError, message
      end
    end

    def defaults
      {
        'aws_access_key_id' => nil,
        'aws_secret_access_key' => nil,
        'bucket' => nil,
        'github_access_token' => ENV['GITHUB_ACCESS_TOKEN'],
        'organization' => nil,
        'quiet' => false,
        'show_help' => false,
      }
    end

    def create_parser
      OptionParser.new do |opt|
        opt.on('-o', '--organization=NAME', '(GitHub) Organization name') do |o|
          @config['organization'] = o
        end

        opt.on('-b', '--bucket=NAME', 'S3 bucket where to store backups') do |b|
          @config['bucket'] = b
        end

        opt.on('-G TOKEN', '--github-access-token=TOKEN', 'GitHub access token') do |token|
          @config['github_access_token'] = token
        end

        opt.on('-A KEY', '--access-key-id=KEY', 'AWS access key id') do |key|
          @config['aws_access_key_id'] = key
        end

        opt.on('-S KEY', '--secret-access-key=KEY', 'AWS secret access key') do |key|
          @config['aws_secret_access_key'] = key
        end

        opt.on('-q', '--quiet', 'Be quiet and mind your own business') do |key|
          @config['quiet'] = key
        end

        opt.on('-h', '--help', 'Display this screen') do
          @config['show_help'] = true
        end
      end
    end
  end
end
