# encoding: utf-8

require 'spec_helper'


describe 'bin/rbk' do
  def run_cli(path)
    Dir.chdir(path) do
      VCR.use_cassette('repos') do
        @exit_status = Rbk::Cli.run(argv, s3: s3, shell: shell, stderr: stderr)
      end
    end
  end

  def exit_status
    @exit_status
  end

  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  def project_dir
    @project_dir ||= File.join(tmpdir, 'spec-repo')
  end

  def s3_dir
    @s3_dir ||= File.join(tmpdir, 's3')
  end

  def write_config_file(path)
    File.open(File.join(path, '.rbk.yml'), 'w') do |f|
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

  let :argv do
    %w[]
  end

  let :s3 do
    AWS::S3.new({
      access_key_id: 'ACCESS_KEY_ID',
      secret_access_key: 'SECRET_ACCESS_KEY',
      s3_port: 5000,
      s3_endpoint: 'localhost',
      s3_force_path_style: true,
      use_ssl: false,
    })
  end

  let :config do
    {
      'github_access_token' => 'GITHUB-ACCESS-TOKEN',
      'bucket' => 'spec-bucket',
      'organization' => 'spec-org',
    }
  end

  let :shell do
    Rbk::Shell.new(false, stdout)
  end

  let :uploaded_repos do
    bucket = s3.buckets['spec-bucket']
    bucket.objects.map do |object|
      path = Pathname.new(object.key).basename
      [path, object.read]
    end
  end

  let :stdout do
    StringIO.new
  end

  let :stderr do
    StringIO.new
  end

  before do
    FileUtils.remove_entry_secure('tmp') if File.exists?('tmp')
    FileUtils.mkdir_p('tmp')
    FileUtils.mkdir_p(project_dir)
    setup_repo(project_dir)
    write_config_file(tmpdir)
  end

  let :s3_server do
    Support::S3Server.new(s3_dir, 5000)
  end

  before do
    s3_server.start
  end

  after do
    s3_server.stop
  end

  context 'when given all necessary options' do
    before do
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

    it 'returns 0 as exit status' do
      expect(exit_status).to be_zero
    end
  end

  context 'when given -h / --help' do
    let :argv do
      %w[--help]
    end

    before do
      run_cli(tmpdir)
    end

    it 'prints usage' do
      expect(stdout.string).to match /Usage:/
    end
  end

  context 'when missing any necessary option' do
    let :config do
      {'bucket' => 'hello-world'}
    end

    before do
      run_cli(tmpdir)
    end

    it 'prints usage to $stderr' do
      expect(stderr.string).to match(/Usage:/)
    end

    it 'returns 1 as exit status' do
      expect(exit_status).to eq(1)
    end
  end

  context 'when any error occurs' do
    before do
      allow(s3).to receive(:buckets).and_raise(ArgumentError)
      run_cli(tmpdir)
    end

    it 'prints a message to stderr' do
      expect(stderr.string).to eq("ArgumentError (ArgumentError)\n")
    end

    it 'returns 1 as exit status' do
      expect(exit_status).to eq(1)
    end
  end
end
