require 'rspec'
require 'tmpdir'
require 'pathname'
require 'open3'

unless ENV['CI']
  require 'simplecov'

  module SimpleCov
    def self.lap
      if running
        @result = SimpleCov::Result.new(Coverage.result.merge_resultset(SimpleCov::ResultMerger.merged_result.original_result))
        SimpleCov::ResultMerger.store_result(@result)
      end
    end
  end
end

ROOT = Pathname.new(__FILE__).parent.parent

$:.unshift ROOT.join('lib').to_s

require 'git/browse/remote'

def git(*args)
  if Open3.methods(false).include? :capture3
    out, err, status = Open3.capture3('git', *args.map { |arg| arg.to_s })
  else
    out = `git #{args.map { |arg| arg.to_s.shellescape }.join(' ')}`
    status = $?.to_i
  end

  if status != 0
    abort "git #{args.join(' ')} failed: #{err}"
  end

  out[/.*/]
end

RSpec.configure do |config|
  config.before(:all) do
    @pwd = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir @tmpdir

    @sha1 = {}

    git :init

    git :config, '--local', 'user.email', 'gbr@example.com'
    git :config, '--local', 'user.name',  'git-browse-remote tester'

    git :remote, 'add', 'origin', 'https://github.com/user/repo.git'
    git :remote, 'add', 'origin2', 'git@gh-mirror.host:user/repo2'

    git :remote, 'add', 'origin3', 'ssh://git@my-git-host.com:9999/user/repo2'
    git :config, '--local', 'browse-remote.my-git-host.com.top',  'https://{host}/{path}'

    git :remote, 'add', 'origin4', 'ssh://git@my-git-host2.com:9999/user/repo2'
    git :config, '--local', 'browse-remote.my-git-host2.com.top',  'https://{host_port}/{path}'

    git :remote, 'add', 'origin5', 'git@my-git-host3.com:9999/user/repo2' # here 9999 is a part of path
    git :config, '--local', 'browse-remote.my-git-host3.com.top',  'https://{host_port}/{path}'

    FileUtils.copy_file ROOT + 'README.md', 'README.md'
    git :add, 'README.md'
    git :commit, '-m' '1st commit'

    FileUtils.mkdir_p 'foo/bar'
    FileUtils.touch   'foo/bar/baz.txt'
    git :add, 'foo/bar/baz.txt'
    git :commit, '-m' '2nd commit'

    git :checkout, '-b', 'branch-1'

    git :commit, '-m' 'branched commit', '--allow-empty'
    @sha1[:'branch-1'] = git 'rev-parse', 'HEAD'

    git :checkout, 'master'

    git :commit, '-m' '3rd commit (tagged)', '--allow-empty'
    git :tag, 'tag-a'

    git :commit, '-m' '4th commit (remote HEAD)', '--allow-empty'
    git :remote, 'add',     'local-remote', '.git'
    git :remote, 'update',  'local-remote'
    git :remote, 'set-url', 'local-remote', 'https://github.com/user/repo3.git'

    git :commit, '-m' '5th commit', '--allow-empty'
    @sha1[:'master~1'] = git 'rev-parse', 'HEAD'

    git :commit, '-m' '6th commit', '--allow-empty'
    @sha1[:master]  = git 'rev-parse', 'HEAD'

    # system 'git log --abbrev-commit --oneline --decorate --graph --all'
    # the commit graph looks like below;
    #
    # * e6b5d6f (local-remote/branch-1, branch-1) branched commit
    # | * 03b1d4d (HEAD, master) 6th commit
    # | * b591899 5th commit
    # | * 3139e94 (local-remote/master) 4th commit (remote HEAD)
    # | * a423770 (tag: tag-a) 3rd commit (tagged)
    # |/
    # * 06f6ebb 2nd commit
    # * ff7b92b 1st commit
  end

  config.after(:all) do
    FileUtils.remove_entry @tmpdir
    Dir.chdir @pwd
  end

  config.after(:each) do
    git :checkout, 'master'
  end
end

module Kernel
  def exec(*args)
    $exec_args = args
  end
end

def git_browse_remote(args)
  begin
    SimpleCov.start unless ENV['CI']
    ARGV.replace(args)
    load ROOT + 'bin/git-browse-remote', true
    true
  rescue
    false
  ensure
    SimpleCov.lap unless ENV['CI']
  end
end

def opened_url
  git_browse_remote(args)

  if $exec_args[0..1] == [ 'git', 'web--browse' ]
    $exec_args[2]
  else
    nil
  end
end

def when_run_with_args(*args, &block)
  context "when run with args #{args}" do
    let(:args) { args }
    instance_eval(&block)
  end
end

describe 'git-browse-remote' do
  when_run_with_args '--init', 'gh-mirror.host=github' do
    it 'should run successfully' do
      expect(git_browse_remote(args)).to be(true)
    end
  end

  context 'when on master' do
    when_run_with_args do
      it 'should open top page' do
        expect(opened_url).to eq("https://github.com/user/repo")
      end
    end

    when_run_with_args '--top' do
      it 'should open top page' do
        expect(opened_url).to eq("https://github.com/user/repo")
      end
    end

    when_run_with_args '--rev' do
      it 'should open rev page' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:master]}")
      end
    end

    when_run_with_args '--ref' do
      it 'should open ref page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/master")
      end
    end

    when_run_with_args 'HEAD~1' do
      it 'should open previous rev\'s page' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:'master~1']}")
      end
    end

    when_run_with_args 'master' do
      it 'should open top page' do
        expect(opened_url).to eq("https://github.com/user/repo")
      end
    end

    when_run_with_args '--', 'README.md' do
      it 'should open the file page' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/master/README.md")
      end
    end

    when_run_with_args '--rev', '--', 'README.md' do
      it 'should open the file page by revision' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/#{@sha1[:master][0..6]}/README.md")
      end
    end

    when_run_with_args '-L3', '--', 'README.md' do
      it 'should open the file at the specified line' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/master/README.md#L3")
      end
    end

    when_run_with_args 'branch-1' do
      it 'should open the branch page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/branch-1")
      end
    end

    when_run_with_args '--rev', 'branch-1' do
      it 'should open the rev page of the branch' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:'branch-1']}")
      end
    end

    when_run_with_args '--remote', 'origin2' do
      it 'should open the specified remote page' do
        expect(opened_url).to eq("https://gh-mirror.host/user/repo2")
      end
    end

    when_run_with_args '-r', 'origin2' do
      it 'should open the specified remote page' do
        expect(opened_url).to eq("https://gh-mirror.host/user/repo2")
      end
    end

    when_run_with_args '-r', 'origin2', '--rev' do
      it 'should open the specified remote page and the revision' do
        expect(opened_url).to eq("https://gh-mirror.host/user/repo2/commit/#{@sha1[:master]}")
      end
    end

    when_run_with_args 'README.md' do
      it 'should open file file page' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/master/README.md")
      end
    end

    when_run_with_args 'origin2' do
      it 'should open the remote' do
        expect(opened_url).to eq("https://gh-mirror.host/user/repo2")
      end
    end

    when_run_with_args '--remote', 'origin3' do
      it 'should open the specified remote page, `host` does not include port' do
        expect(opened_url).to eq("https://my-git-host.com/user/repo2")
      end
    end

    when_run_with_args '--remote', 'origin4' do
      it 'should open the specified remote page, using `host_port` variable' do
        expect(opened_url).to eq("https://my-git-host2.com:9999/user/repo2")
      end
    end

    when_run_with_args '--remote', 'origin5' do
      it 'should open the specified remote page on a SCP-like URL' do
        expect(opened_url).to eq("https://my-git-host3.com/9999/user/repo2")
      end
    end
  end

  context 'on some branch' do
    before { git :checkout, 'branch-1' }

    when_run_with_args do
      it 'should open the current branch page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/branch-1")
      end
    end

    when_run_with_args '--top' do
      it 'should open the top page' do
        expect(opened_url).to eq("https://github.com/user/repo")
      end
    end

    when_run_with_args '--rev' do
      it 'should open the revision page of current HEAD' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:'branch-1']}")
      end
    end

    when_run_with_args '--pr' do
      it 'should open the pull request page' do
        expect(opened_url).to eq("https://github.com/user/repo/pull/branch-1")
      end
    end

    when_run_with_args 'README.md' do
      it 'should open the file page at current branch' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/branch-1/README.md")
      end
    end
  end

  context 'on detached HEAD' do
    before { git :checkout, 'HEAD~1' }

    when_run_with_args do
      it 'should open the revision page' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:'master~1']}")
      end
    end

    when_run_with_args 'HEAD' do
      it 'should open the revision page' do
        expect(opened_url).to eq("https://github.com/user/repo/commit/#{@sha1[:'master~1']}")
      end
    end
  end

  context 'on tag' do
    before { git :checkout, 'tag-a' }

    when_run_with_args do
      it 'should open the tag page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/tag-a")
      end
    end
  end

  context 'on remote branch' do
    before { git :checkout, 'local-remote/master' }

    when_run_with_args do
      it 'should open the remote' do
        expect(opened_url).to eq("https://github.com/user/repo3")
      end
    end
  end

  context 'after changing branches' do
    before {
      git :checkout, 'branch-1'
      git :checkout, 'master'
    }

    when_run_with_args 'HEAD@{1}' do
      it 'should open the previous branch page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/branch-1")
      end
    end

    when_run_with_args '--ref', 'HEAD@{1}' do
      it 'should open the previous branch page' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/branch-1")
      end
    end
  end

  when_run_with_args 'foo/bar' do
    it 'should accept directory as an argument' do
      expect(opened_url).to eq("https://github.com/user/repo/tree/master/foo/bar")
    end
  end

  context 'when at non-toplevel directory' do
    before { @_pwd = Dir.pwd; Dir.chdir 'foo' }
    after { Dir.chdir @_pwd }

    when_run_with_args '../README.md' do
      it 'should resolve relative path' do
        expect(opened_url).to eq("https://github.com/user/repo/blob/master/README.md")
      end
    end

    when_run_with_args '.' do
      it 'should resolve relative path' do
        expect(opened_url).to eq("https://github.com/user/repo/tree/master/foo")
      end
    end
  end

  it 'should abort on invalid ref' do
    expect { git_browse_remote([ 'xxx-nonexistent-ref' ]) }.to raise_error SystemExit
  end
end
