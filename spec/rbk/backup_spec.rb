# encoding: utf-8

require 'spec_helper'


module Rbk
  describe Backup do
    describe '#run' do
      let :backup do
        described_class.new(repos, git, archiver, uploader, fileutils)
      end

      let :repos do
        double(:repos)
      end

      let :git do
        double(:git)
      end

      let :archiver do
        double(:archiver)
      end

      let :uploader do
        double(:uploader)
      end

      let :fileutils do
        double(:fileutils)
      end

      before do
        repos.stub(:each).and_yield(FakeRepo.new('repo', 'http://github.com/org/repo.git'))
        git.stub(:clone)
        archiver.stub(:create) do |path|
          %(#{path}.tar.gz)
        end
        uploader.stub(:upload)
        fileutils.stub(:remove_entry_secure)
      end

      context 'without any errors' do
        before do
          backup.run
        end

        it 'clones each repo' do
          expect(git).to have_received(:clone)
        end

        it 'clones w/ `bare` option' do
          expect(git).to have_received(:clone).with(anything, anything, bare: true)
        end

        it 'creates a tar archive of each cloned repo' do
          expect(archiver).to have_received(:create)
        end

        it 'uploads each tar archive' do
          expect(uploader).to have_received(:upload)
        end

        it 'removes each tar archive' do
          expect(fileutils).to have_received(:remove_entry_secure).with(/^repo-[0-9]{8}.git.tar.gz$/)
        end

        it 'removes each cloned repo (locally)' do
          expect(fileutils).to have_received(:remove_entry_secure).with(/^repo-[0-9]{8}.git$/)
        end
      end

      context 'errors during Git#clone' do
        before do
          repos.stub(:each)
            .and_yield(FakeRepo.new('fail-repo', 'git@github.com/org/fail-repo.git'))
            .and_yield(FakeRepo.new('repo', 'git@github.com/org/repo.git'))

            git.stub(:clone).with('git@github.com/org/fail-repo.git', anything, anything).and_raise(Git::GitExecuteError)
        end

        before do
          backup.run
        end

        it 'ignores them' do
          expect(git).to have_received(:clone).twice
          expect(uploader).to have_received(:upload).once
          expect(fileutils).to have_received(:remove_entry_secure).with(/^repo-[0-9]{8}.git.tar.gz$/)
          expect(fileutils).to have_received(:remove_entry_secure).with(/^repo-[0-9]{8}.git$/)
        end
      end
    end
  end
end
