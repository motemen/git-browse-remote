require 'git/browse/remote/runner'

def when_args_parsed(args, &block)
  context "with args #{args}" do
    subject(:runner) { Git::Browse::Remote::Runner.new(args) }
    before { runner.parse_args! }

    instance_eval(&block)
  end
end

def core
  runner.instance_variable_get(:@core)
end

describe Git::Browse::Remote::Runner do
  when_args_parsed ['--top'] do
    it 'should set @core.mode to :top' do
      expect(core.mode).to eq(:top)
    end
  end

  when_args_parsed ['--remote', 'upstream'] do
    it 'should set @core.remote to "upstream"' do
      expect(core.remote).to eq('upstream')
    end
  end

  when_args_parsed ['-L337'] do
    it 'should set @core.line to 337' do
      expect(core.line).to eq(337)
    end
  end

  pending do
    when_args_parsed ['-L337,400'] do
      it 'should set @core.lines to [337,400]' do
        expect(core.lines).to eq([337,400])
      end
    end
  end
end
