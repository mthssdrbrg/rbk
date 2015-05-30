# encoding: utf-8

require 'spec_helper'


describe 'rbk integration test' do
  def run_cli(path)
    Dir.chdir(path) do
      Rbk::Cli.run(argv, github_repos: github_repos, s3: s3, shell: shell)
    end
  end

  let :argv do
    %w[]
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
    Rbk::Shell.new(false, stream)
  end

  let :stream do
    s = double(:stream)
    allow(s).to receive(:puts) do |message|
      messages << message
    end
    s
  end

  let :messages do
    []
  end

  let :uploaded_repos do
    []
  end

  def write_config_file(path)
    File.open(File.join(path, '.rbk.yml'), 'w+') do |f|
      f.puts(YAML.dump(config))
    end
  end

  def setup_repo(project_dir)
    Dir.chdir(project_dir) do
      %x(git init --bare ../remote-repo.git)
      commands = [
        'git init',
        'git config user.email "nobody@example.com"',
        'git config user.name "Nobody Doe"',
        'echo "hello world" >> README',
        'git add . && git commit -m "Initial commit"',
        'git remote add origin ../remote-repo.git',
        'git push -u origin master',
      ].join(' && ') << ' > /dev/null 2>&1'
      %x(#{commands})
    end
  end

  def clone_archive(path, data)
    archive_path = File.join('tmp', path.basename('.tar.gz'))
    repo_path = File.join('tmp', path.basename('.git.tar.gz'))
    Dir.chdir('tmp') do
      File.open(path, 'w') { |f| f.write(data) }
      %x(tar xzf #{path})
    end
    %x[git clone #{archive_path} #{repo_path} 2> /dev/null]
    repo_path
  end

  before do
    allow(github_repos).to receive(:new).with(oauth_token: 'GITHUB-ACCESS-TOKEN')
      .and_return(github_repos)
    allow(github_repos).to receive(:list).with(org: 'spec-org', auto_pagination: true)
      .and_return(repos)
  end

  before do
    allow(s3).to receive_message_chain(:buckets, :[]).with('spec-bucket') do
      double(:bucket).tap do |bucket|
        allow(bucket).to receive(:name).and_return(config['bucket'])
        allow(bucket).to receive_message_chain(:objects, :[]) do |key|
          double(:s3_object).tap do |s3_object|
            allow(s3_object).to receive(:key).and_return(key)
            allow(s3_object).to receive(:exists?).and_return(false)
            allow(s3_object).to receive(:write) do |pathname|
              uploaded_repos << [pathname, pathname.read]
            end
          end
        end
      end
    end
  end

  before do
    FileUtils.remove_entry_secure('tmp') if File.exists?('tmp')
    FileUtils.mkdir_p('tmp')
    tmpdir = Dir.mktmpdir
    project_dir = File.join(tmpdir, 'spec-repo')
    Dir.mkdir(project_dir)
    setup_repo(project_dir)
    write_config_file(tmpdir)
    run_cli(tmpdir)
  end

  it 'clones, compresses and uploads repos' do
    expect(uploaded_repos.size).to eq(1)
    uploaded_repos.each do |path, data|
      expect(path).to_not exist
      repo_path = clone_archive(path, data)
      logs = %x[cd #{repo_path} && git log --pretty=oneline].split("\n")
      expect(logs.size).to eq(1)
      expect(logs.first.split(' ', 2).last).to eq('Initial commit')
      expect(File.read(File.join(repo_path, 'README'))).to eq("hello world\n")
    end
  end

  context 'when given -h / --help' do
    let :argv do
      %w[--help]
    end

    it 'prints usage' do
      expect(messages.first).to match /Usage:/
    end
  end
end
