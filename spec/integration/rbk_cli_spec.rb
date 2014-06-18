# encoding: utf-8

require 'spec_helper'


FakeRepo = Struct.new(:name, :ssh_url)
describe 'rbk integration test' do
  let :run_cli do
    Rbk::Cli.run(%w[], github_repos: github_repos, s3: s3)
  end

  let :github_repos do
    double(:github_repos)
  end

  let :s3 do
    double(:s3)
  end

  let :config do
    {
      'github_access_token' => 'GITHUB-ACCESS-TOKEN',
      'bucket' => 'spec-bucket',
      'organization' => 'spec-org',
    }
  end

  let :repos do
    [FakeRepo.new('spec-repo', './spec-repo')]
  end

  let :shell do
    Rbk::Shell.new
  end

  let :uploaded_repos do
    []
  end

  def write_config_file
    File.open('.rbk.yml', 'w+') do |f|
      f.puts(YAML.dump(config))
    end
  end

  def setup_repo
    shell.exec 'git init --bare remote-repo.git'

    Dir.mkdir('spec-repo')
    Dir.chdir('spec-repo') do
      shell.exec [
        'git init',
        'echo "hello world" >> README',
        'git add . && git commit -m "Initial commit"',
        'git remote add origin ../remote-repo.git',
        'git push -u origin master',
      ].join(' && ') << ' > /dev/null 2>&1'
    end
  end

  def clone_archive(path, data)
    File.open(path, 'w') { |f| f.write(data) }
    shell.exec %(tar xzf #{path})
    Git.clone(path.basename('.tar.gz'), path.basename('.git.tar.gz'))
  end

  before do
    github_repos.stub(:new).with(oauth_token: 'GITHUB-ACCESS-TOKEN')
      .and_return(github_repos)
    github_repos.stub(:list).with(org: 'spec-org', auto_pagination: true)
      .and_return(repos)
  end

  before do
    s3.stub_chain(:buckets, :[]).with('spec-bucket') do
      double(:bucket).tap do |bucket|
        bucket.stub_chain(:objects, :[]) do
          double(:s3_object).tap do |s3_object|
            s3_object.stub(:write) do |pathname|
              uploaded_repos << [pathname, pathname.read]
            end
          end
        end
      end
    end
  end

  around do |example|
    Dir.mktmpdir do |sandbox_dir|
      Dir.chdir(sandbox_dir) do
        setup_repo
        write_config_file
        example.call
      end
    end
  end

  before do
    run_cli
  end

  it 'clones, compresses and uploads repos' do
    expect(uploaded_repos.size).to eq(1)
    uploaded_repos.each do |path, data|
      expect(path).to_not exist
      cloned = clone_archive(path, data)
      expect(cloned.log.size).to eq(1)
      expect(cloned.log.first.message).to eq('Initial commit')
    end
  end
end
