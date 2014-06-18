# encoding: utf-8

require 'spec_helper'


module Rbk
  describe Shell do
    let :shell do
      described_class.new
    end

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
end
