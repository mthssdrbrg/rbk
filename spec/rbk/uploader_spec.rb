# encoding: utf-8

require 'spec_helper'


module Rbk
  describe Uploader do
    let :uploader do
      described_class.new(bucket, shell)
    end

    let :bucket do
      double(:bucket, name: 'spec-bucket')
    end

    let :s3_object do
      double(:s3_object, write: nil, exists?: false)
    end

    let :shell do
      double(:shell, puts: nil)
    end

    before do
      bucket.stub_chain(:objects, :[]) do |key|
        s3_object.stub(:key).and_return(key)
        s3_object
      end
    end

    describe '#upload' do
      context 'when file already exists on S3' do
        before do
          s3_object.stub(:exists?).and_return(true)
        end

        before do
          uploader.upload('spec-file.tgz')
        end

        it 'skips it' do
          expect(s3_object).to_not have_received(:write)
        end

        it 'prints a warning' do
          expect(shell).to have_received(:puts).with(/already exists, skipping/)
        end
      end

      context 'when file does not exist on S3' do
        before do
          uploader.upload('spec-file.tgz')
        end

        it 'uploads it' do
          expect(s3_object).to have_received(:write).with(Pathname.new('spec-file.tgz'))
        end

        it 'prints an info message' do
          expect(shell).to have_received(:puts).with(/Writing .+ to s3:\/\/.+/)
        end
      end
    end
  end
end
