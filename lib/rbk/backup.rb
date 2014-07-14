# encoding: utf-8

module Rbk
  class Backup
    def initialize(repos, git, archiver, uploader, shell, fileutils=FileUtils)
      @repos = repos
      @git = git
      @archiver = archiver
      @uploader = uploader
      @shell = shell
      @fileutils = fileutils
      @date_suffix = Date.today.strftime('%Y%m%d')
    end

    def run
      @repos.each do |repo|
        clone_path = %(#{repo.name}-#{@date_suffix}.git)
        @shell.puts(%(Cloning "#{repo.name}" to "#{clone_path}"))
        if cloned?(repo.ssh_url, clone_path)
          archive = @archiver.create(clone_path)
          @uploader.upload(archive)
          @fileutils.remove_entry_secure(archive)
          @fileutils.remove_entry_secure(clone_path)
        else
          @shell.puts(%(Failed to clone "#{repo.name}"))
        end
      end
    end

    private

    def cloned?(url, path)
      @git.clone(url, path, bare: true)
      true
    rescue Git::GitExecuteError
    end
  end
end
