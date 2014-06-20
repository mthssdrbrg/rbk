# encoding: utf-8

module Rbk
  class Backup
    def initialize(repos, git, archiver, uploader, fileutils=FileUtils)
      @repos = repos
      @git = git
      @archiver = archiver
      @uploader = uploader
      @fileutils = fileutils
      @date_suffix = Date.today.strftime('%Y%m%d')
    end

    def run
      @repos.each do |repo|
        clone_path = %(#{repo.name}-#{@date_suffix}.git)
        next unless clone(repo.ssh_url, clone_path)
        archive = @archiver.create(clone_path)
        @uploader.upload(archive)
        @fileutils.remove_entry_secure(archive)
        @fileutils.remove_entry_secure(clone_path)
      end
    end

    private

    def clone(url, path)
      @git.clone(url, path, bare: true)
      true
    rescue Git::GitExecuteError
    end
  end
end
