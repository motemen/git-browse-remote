require 'git/browse/remote/core'

describe Git::Browse::Remote::Core do
  subject(:core) { Git::Browse::Remote::Core.new }

  describe '#template_type' do
    context 'if @file set' do
      before { core.file = 'README.md' }

      it 'is :file' do
        expect(core.template_type).to be(:file)
      end
    end

    context 'if @file not set' do
      it 'is same as #mode' do
        expect(core.template_type).to be(core.mode)
      end
    end
  end

  describe '#remote' do
    context 'by default' do
      it 'is "origin"' do
        expect(core.remote).to eq('origin')
      end
    end

    context 'if remote set' do
      before { core.remote = 'remote-foo' }

      it 'is the set value' do
        expect(core.remote).to eq('remote-foo')
      end
    end

    context 'if #ref is a remote ref' do
      it 'is the remote name in the ref' do
        core.stub(:ref).and_return('remotes/remote-bar/master')
        expect(core.remote).to eq('remote-bar')
      end
    end
  end

  describe '#mode' do
    context 'by default' do
      it 'is :rev' do
        expect(core.mode).to eq(:rev)
      end
    end

    context 'if mode set' do
      before { core.mode = :foo }

      it 'is the set value' do
        expect(core.mode).to eq(:foo)
      end
    end

    context 'if #ref points to master' do
      it 'is :top' do
        core.stub(:ref).and_return('refs/heads/master')
        expect(core.mode).to eq(:top)
      end
    end

    context 'if #ref points to some ref' do
      it 'is :ref' do
        core.stub(:ref).and_return('refs/heads/branch-a')
        expect(core.mode).to eq(:ref)
      end
    end
  end

  describe '#commit' do
    it 'calls Git.parse_rev with #target' do
      Git::Browse::Remote::Git.should_receive(:parse_rev).with('__TARGET__').and_return('0000000000000000000000000000000000000000')
      core.stub(:target).and_return('__TARGET__')
      expect(core.commit).to eq('0000000000000000000000000000000000000000')
    end
  end

  describe '#short_commit' do
    it 'calls Git.parse_rev_short with #target' do
      Git::Browse::Remote::Git.should_receive(:parse_rev_short).with('__TARGET__').and_return('00000000')
      core.stub(:target).and_return('__TARGET__')
      expect(core.short_commit).to eq('00000000')
    end
  end

  describe '#_rev' do
    context 'if #mode is :ref (not :rev)' do
      before { core.stub(:mode).and_return(:ref) }

      context 'and #_ref is not defined' do
        it 'returns the #_commit value' do
          core.should_receive(:_commit).and_return('0000000000000000000000000000000000000000')
          expect(core._rev).to eq('0000000000000000000000000000000000000000')
        end
      end

      context 'and #_ref is defined' do
        it 'returns the #_ref value' do
          core.should_receive(:_ref).and_return('a-ref')
          expect(core._rev).to eq('a-ref')
        end
      end
    end

    context 'if #mode is :rev' do
      before { core.stub(:mode).and_return(:rev) }

      context 'and #_ref is not defined' do
        it 'returns the #_commit value' do
          core.should_receive(:_commit).and_return('0000000000000000000000000000000000000000')
          expect(core._rev).to eq('0000000000000000000000000000000000000000')
        end
      end

      context 'and #_ref is defined' do
        it 'returns the #_commit value though' do
          core.stub(:_ref).and_return('a-ref')
          core.should_receive(:_commit).and_return('0000000000000000000000000000000000000000')
          expect(core._rev).to eq('0000000000000000000000000000000000000000')
        end
      end
    end
  end

  describe '#short_ref' do
    context 'if @ref is "refs/heads/master"' do
      before { core.instance_variable_set :@ref, 'refs/heads/master' }
      it 'should be "master"' do
        expect(core.short_ref).to eq('master')
      end
    end

    context 'if @ref is "refs/heads/fix/some/bug"' do
      before { core.instance_variable_set :@ref, 'refs/heads/fix/some/bug' }
      it 'should be "fix/some/bug"' do
        expect(core.short_ref).to eq('fix/some/bug')
      end
    end

    context 'if @ref is "refs/tags/v0.0.1"' do
      before { core.instance_variable_set :@ref, 'refs/tags/v0.0.1' }
      it 'should be "v0.0.1"' do
        expect(core.short_ref).to eq('v0.0.1')
      end
    end

    context 'if @ref is "refs/remotes/origin/foo/bar"' do
      before { core.instance_variable_set :@ref, 'refs/remotes/origin/foo/bar' }
      it 'should be "foo/bar"' do
        expect(core.short_ref).to eq('foo/bar')
      end
    end
  end
end
