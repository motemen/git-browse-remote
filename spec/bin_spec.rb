require 'rspec'
require 'tmpdir'
require 'pathname'
require 'open3'

unless ENV['CI']
  require 'simplecov'

  module SimpleCov
    def self.lap
      @result = SimpleCov::Result.new(Coverage.result.merge_resultset(SimpleCov::ResultMerger.merged_result.original_result))
      SimpleCov::ResultMerger.store_result(@result)
    end
  end
end

ROOT = Pathname.new(__FILE__).parent.parent

$:.unshift (ROOT + 'lib').to_s

require 'git/browse/remote'

def git(*args)
  out, err, status = Open3.capture3('git', *args.map { |arg| arg.to_s })
  if status != 0
    abort "git #{args.join(' ')} failed: #{err}"
  end
  out
end

RSpec.configure do |config|
  config.before(:all) do
    @pwd = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir @tmpdir

    git :init

    git :remote, 'add', 'origin', 'https://github.com/user/repo.git'
    git :remote, 'add', 'origin2', 'git@gh-mirror.host:user/repo2'

    FileUtils.copy_file ROOT + 'README.md', 'README.md'
    git :add, 'README.md'
    git :commit, '-m' '1st commit'

    git :commit, '-m' '2nd commit', '--allow-empty'

    git :checkout, '-b', 'branch-1'

    git :commit, '-m' 'branched commit', '--allow-empty'

    git :checkout, 'master'

    git :commit, '-m' '3rd commit (tagged)', '--allow-empty'
    git :tag, 'tag-a'

    git :commit, '-m' '4th commit (remote HEAD)', '--allow-empty'
    git :remote, 'add',     'local-remote', '.git'
    git :remote, 'update',  'local-remote'
    git :remote, 'set-url', 'local-remote', 'https://github.com/user/repo3.git'

    git :commit, '-m' '5th commit', '--allow-empty'

    git :commit, '-m' '6th commit', '--allow-empty'

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

RSpec::Matchers.define :navigate_to do |expected|
  match do |actual|
    expected === actual
  end
end

def command
  ROOT + 'bin/git-browse-remote'
end

def master_sha1
  @master_sha1 ||= git('rev-parse', 'master').chomp
end

def parent_sha1
  @parent_sha1 ||= git('rev-parse', 'master^1').chomp
end

def branch_sha1
  @branch_sha1 ||= git('rev-parse', 'branch-1').chomp
end

module Kernel
  def exec(*args)
    $exec_args = args
  end
end

def git_browse_remote(args)
  ARGV.replace(args)
  load ROOT + 'bin/git-browse-remote', true
end

def with_args(*args, &block)
  description = if args.empty?
    '(no arguments)'
  else
    args.join(' ')
  end

  describe description do
    subject do
      SimpleCov.start unless ENV['CI']

      git_browse_remote(args)

      SimpleCov.lap unless ENV['CI']

      $exec_args[2]
    end

    it(&block)
  end
end

describe 'git-browse-remote' do
  with_args '--init' do
    should_not be_nil
  end

  with_args '--init', 'gh-mirror.host=github' do
    should_not be_nil
  end

  with_args do
    should navigate_to('https://github.com/user/repo')
  end

  with_args '--top' do
    should navigate_to('https://github.com/user/repo')
  end

  with_args '--rev' do
    should navigate_to("https://github.com/user/repo/commit/#{master_sha1}")
  end

  with_args '--ref' do
    should navigate_to('https://github.com/user/repo/tree/master')
  end

  with_args 'HEAD~1' do
    should navigate_to("https://github.com/user/repo/commit/#{parent_sha1}")
  end

  with_args 'master' do
    should navigate_to("https://github.com/user/repo")
  end

  with_args '--', 'README.md' do
    should navigate_to("https://github.com/user/repo/blob/master/README.md")
  end

  with_args '--rev', '--', 'README.md' do
    should navigate_to("https://github.com/user/repo/blob/#{master_sha1[0..6]}/README.md")
  end

  with_args '-L3', '--', 'README.md' do
    should navigate_to("https://github.com/user/repo/blob/master/README.md#L3")
  end

  with_args 'branch-1' do
    should navigate_to("https://github.com/user/repo/tree/branch-1")
  end

  with_args '--rev', 'branch-1' do
    should navigate_to("https://github.com/user/repo/commit/#{branch_sha1}")
  end

  context 'on some branch' do
    before { git :checkout, 'branch-1' }

    with_args do
      should navigate_to("https://github.com/user/repo/tree/branch-1")
    end

    with_args '--top' do
      should navigate_to("https://github.com/user/repo")
    end

    with_args '--rev' do
      should navigate_to("https://github.com/user/repo/commit/#{branch_sha1}")
    end

    with_args 'README.md' do
      should navigate_to("https://github.com/user/repo/blob/branch-1/README.md")
    end
  end

  context 'on detached HEAD' do
    before { git :checkout, 'HEAD~1' }

    with_args do
      should navigate_to("https://github.com/user/repo/commit/#{parent_sha1}")
    end

    with_args 'HEAD' do
      should navigate_to("https://github.com/user/repo/commit/#{parent_sha1}")
    end
  end

  context 'on tag' do
    before { git :checkout, 'tag-a' }

    with_args do
      should navigate_to("https://github.com/user/repo/tree/tag-a")
    end
  end

  with_args '--remote', 'origin2' do
    should navigate_to("https://gh-mirror.host/user/repo2")
  end

  with_args '-r', 'origin2' do
    should navigate_to("https://gh-mirror.host/user/repo2")
  end

  with_args '-r', 'origin2', '--rev' do
    should navigate_to("https://gh-mirror.host/user/repo2/commit/#{master_sha1}")
  end

  with_args 'README.md' do
    should navigate_to("https://github.com/user/repo/blob/master/README.md")
  end

  with_args 'origin2' do
    should navigate_to("https://gh-mirror.host/user/repo2")
  end

  context 'on remote branch' do
    before { git :checkout, 'local-remote/master' }

    with_args do
      should navigate_to("https://github.com/user/repo3")
    end
  end

  it 'should abort on invalid ref' do
    expect { git_browse_remote([ 'xxx-nonexistent-ref' ]) }.to raise_error SystemExit
  end
end
