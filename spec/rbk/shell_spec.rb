# encoding: utf-8

require 'spec_helper'


module Rbk
  describe Shell do
    let :shell do
      described_class.new(quiet, stream)
    end

    let :stream do
      double(:stream, puts: nil)
    end

    let :quiet do
      false
    end

    describe '#exec' do
      context 'when command is successful' do
        it 'returns output' do
          expect(shell.exec('whoami')).to_not eq('root')
        end
      end

      context 'when command fails' do
        it 'raises ExecError' do
          expect { shell.exec 'ls /this-should-most-likely-not-exist-ever 2>&1' }.to raise_error(ExecError, /ls: .+/i)
        end
      end
    end

    describe '#puts' do
      context 'when told to be quiet' do
        let :quiet do
          true
        end

        it 'does not output anything' do
          shell.puts('message')
          expect(stream).to_not have_received(:puts)
        end
      end

      context 'by default' do
        it 'prints message to given stream' do
          shell.puts('message')
          expect(stream).to have_received(:puts).with('message')
        end
      end
    end
  end
end
