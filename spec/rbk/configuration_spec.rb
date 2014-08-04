# encoding: utf-8

require 'spec_helper'

module Rbk
  describe Configuration do
    def write_config(options)
      File.open('.rbk.yml', 'w+') do |f|
        f.puts(YAML.dump(options))
      end
    end

    describe '#validate' do
      let :config do
        described_class.new(options)
      end

      let :options do
        {
          'organization' => 'some-org',
          'bucket' => 'some-s3-bucket',
          'github_access_token' => 'some-token',
        }
      end

      context 'when required options are missing' do
        context 'organization' do
          before do
            options.delete('organization')
          end

          it 'raises an InsufficientOptionsError' do
            expect { config.validate }.to raise_error(InsufficientOptionsError, /Missing organization/)
          end
        end

        context 'bucket' do
          before do
            options.delete('bucket')
          end

          it 'raises an InsufficientOptionsError' do
            expect { config.validate }.to raise_error(InsufficientOptionsError, /Missing S3 bucket/)
          end
        end

        context 'github_access_token' do
          before do
            options.delete('github_access_token')
          end

          it 'raises an InsufficientOptionsError' do
            expect { config.validate }.to raise_error(InsufficientOptionsError, /Missing GitHub access token/)
          end

          context 'if GITHUB_ACCESS_TOKEN is set' do
            it 'uses the value' do
              ENV['GITHUB_ACCESS_TOKEN'] = 'HELLO!'
              expect { config.validate }.to_not raise_error
              expect(config.github_access_token).to eq('HELLO!')
              ENV['GITHUB_ACCESS_TOKEN'] = nil
            end
          end

          context 'if GITHUB_ACCESS_TOKEN is set but empty' do
            it 'raises an InsufficientOptionsError' do
              ENV['GITHUB_ACCESS_TOKEN'] = ''
              expect { config.validate }.to raise_error(InsufficientOptionsError, /Missing GitHub access token/)
              ENV['GITHUB_ACCESS_TOKEN'] = nil
            end
          end
        end
      end
    end

    describe '#parse' do
      let :config do
        described_class.new
      end

      context '-b / --bucket' do
        it 'sets bucket' do
          config.parse(%w[-b bucket])
          expect(config.bucket).to eq('bucket')
        end
      end

      context '-G / --github-access-token' do
        it 'sets github_access_token' do
          config.parse(%w[-G access-token])
          expect(config.github_access_token).to eq('access-token')
        end
      end

      context '-A / --access-key-id' do
        it 'sets aws_access_key_id' do
          config.parse(%w[-A access-key-id])
          expect(config.aws_access_key_id).to eq('access-key-id')
        end
      end

      context '-S / --secret-access-key' do
        it 'sets aws_secret_access_key' do
          config.parse(%w[-S secret-access-key])
          expect(config.aws_secret_access_key).to eq('secret-access-key')
        end
      end

      context '-o / --organization' do
        it 'sets organization' do
          config.parse(%w[-o some-org])
          expect(config.organization).to eq('some-org')
        end
      end

      context '-q / --quiet' do
        it 'sets quiet flag' do
          config.parse(%w[-q])
          expect(config.quiet).to be_true
          expect(config.quiet?).to be_true
        end
      end

      context '-h / --help' do
        it 'sets `show_help` to true' do
          config.parse(%w[-h])
          expect(config.show_help).to be true
          config.parse(%w[--help])
          expect(config.show_help).to be true
        end
      end
    end

    context '.load' do
      let :config do
        described_class.load
      end

      around do |example|
        Dir.mktmpdir do |sandbox_dir|
          Dir.chdir(sandbox_dir) do
            example.call
          end
        end
      end

      context 'when there is a .rbk.yml in the current directory' do
        let :options do
          {'organization' => 'from .rbk.yml'}
        end

        before do
          write_config(options)
        end

        it 'reads configuration from file' do
          expect(config.organization).to eq('from .rbk.yml')
        end
      end

      context 'when there is not, but there is a ~/.rbk.yml' do
        let! :old_home do
          ENV['HOME']
        end

        let :options do
          {'organization' => 'from ~/.rbk.yml'}
        end

        around do |example|
          Dir.mktmpdir do |tmp_home|
            ENV['HOME'] = tmp_home
            Dir.chdir(tmp_home) do
              write_config(options)
            end
            example.call
          end
        end

        after do
          ENV['HOME'] = old_home
        end

        it 'reads configuration from file' do
          expect(config.organization).to eq('from ~/.rbk.yml')
        end
      end

      context 'when there is no .rbk.yml anywhere' do
        it 'returns default configuration' do
          expect(config.organization).to be_nil
          expect(config.bucket).to be_nil
          expect(config.github_access_token).to be_nil
        end
      end
    end

    context '.create' do
      it 'validates the resulting configuration' do
        expect { described_class.create(%w[]) }.to raise_error(InsufficientOptionsError)
      end

      context 'when there is a .rbk.yml somewhere' do
        let :config do
          described_class.create(%w[-o from-cmd-opts])
        end

        let :options do
          {
            'organization' => 'org from file',
            'bucket' => 'bucket from file',
            'github_access_token' => 'token from file',
          }
        end

        around do |example|
          Dir.mktmpdir do |sandbox_dir|
            Dir.chdir(sandbox_dir) do
              example.call
            end
          end
        end

        before do
          write_config(options)
        end

        it 'uses command line options over configuration file options' do
          expect(config.organization).to eq('from-cmd-opts')
        end
      end
    end

    context '#aws_credentials' do
      it 'returns a hash with configured AWS credentials' do
        configuration = described_class.new.parse(%w[-A KEY_ID -S SECRET])
        expect(configuration.aws_credentials).to eq({access_key_id: 'KEY_ID', secret_access_key: 'SECRET'})
      end
    end

    context 'when calling a method that is not a configuration option' do
      it 'raises NoMethodError' do
        expect { described_class.new.something }.to raise_error(NoMethodError)
      end
    end
  end
end
