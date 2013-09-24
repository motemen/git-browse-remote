require 'optparse'

module Git
  module Browse
    module Remote; end
  end
end

module Git::Browse::Remote
  module Git
    def self.is_valid_ref?(target)
      `git rev-parse --verify --quiet #{target}` && $? == 0
    end

    def self.is_valid_remote?(remote)
      `git config --get remote.#{remote}.url`.chomp.empty? == false
    end

    def self.parse_rev(ref)
      `git rev-parse #{ref}`.chomp
    end

    def self.parse_rev_short(ref)
      `git rev-parse --short #{ref}`.chomp
    end

    def self.full_name_of_ref(ref)
      `git rev-parse --symbolic-full-name #{ref}`.chomp
    end

    # the ref whom HEAD points to
    def self.resolved_head
      `git symbolic-ref -q HEAD`[/.+/]
    end

    def self.symbolic_name_of_head
      `git name-rev --name-only HEAD`.chomp.sub(%r(\^0$), '') # some workaround for ^0
    end
  end

  class Runner
    MAPPING_RECIPES = {
      :github => {
        :top  => 'https://{host}/{path}',
        :ref  => 'https://{host}/{path}/tree/{short_ref}',
        :rev  => 'https://{host}/{path}/commit/{commit}',
        :file => 'https://{host}/{path}/blob/{short_rev}/{file}{line && "#L%d" % line}'
      },

      :gitweb => {
        :top => 'http://{host}/?p={path[-2..-1]}.git',
        :ref => 'http://{host}/?p={path[-2..-1]}.git;h={ref}',
        :rev => 'http://{host}/?p={path[-2..-1]}.git;a=commit;h={ref}',
        # XXX
        # I don't know file url of gitweb...
      }
    }

    def initialize(args)
      @args = args
      @core = Core.new
    end

    def run
      OptionParser.new do |opt|
        opt.banner = 'git browse-remote [options] [<commit> | <remote>]'
        opt.on('-r', '--remote=<remote>', 'specify remote') { |r| @core.remote = r }

        opt.on('--top', 'open `top` page') { @core.mode = :top }
        opt.on('--rev', 'open `rev` page') { @core.mode = :rev }
        opt.on('--ref', 'open `ref` page') { @core.mode = :ref }
        opt.on('--init [<host>=<recipe>]', 'initialize default url mappings') do |config|
          if config
            host, name = *config.split(/=/, 2)
          else
            host, name = 'github.com', 'github'
          end

          STDERR.puts "Writing config for #{host}..."

          mapping = MAPPING_RECIPES[name.to_sym] or abort "Recipe '#{name}' not found"
          mapping.each do |mode,template|
            system %Q(git config --global browse-remote.#{host}.#{mode} '#{template}')
          end

          STDERR.puts 'Mappings generated:'
          exec "git config --get-regexp ^browse-remote\\.#{host}\\."
        end
        opt.on('-L <n>', 'specify line number (only meaningful on file mode)', Integer) { |n| @core.line = n }
      end.parse!(@args)

      @core.target, @core.file = *@args[0..1]

      exec 'git', 'web--browse', @core.url
    end

  end

  class Path < Array
    def to_s
      join('/')
    end
  end

  class Core
    attr_accessor :line, :file

    def template_type
      if @file
        :file
      else
        mode
      end
    end

    def url
      if target && !@file && File.exists?(target)
        self.target, @file = nil, target
      end

      if target
        if Git.is_valid_ref? target
          @ref = Git.full_name_of_ref(target)
        elsif Git.is_valid_remote? target
          @remote, @ref = target, 'master'
        else
          abort "Not a valid ref or remote: #{target}"
        end
      else
        @ref = Git.symbolic_name_of_head
      end

      if @ref == 'HEAD'
        @ref = nil
      end

      remote_url = `git config remote.#{remote}.url`[/.+/] or
          abort "Could not get remote url: #{remote}"

      host, *path = remote_url.sub(%r(^\w+://), '').sub(/^[\w-]+@/, '').split(/[\/:]+/)
      path.last.sub!(/\.git$/, '')
      path = Path.new(path)

      template = `git config --get browse-remote.#{host}.#{template_type}`[/.+/] or
          abort "No '#{template_type}' mapping found for #{host} (maybe `git browse-remote --init` required)"

      url = template.gsub(/\{(.+?)\}/) { |m| eval($1) }
    end

    def remote=(remote)
      @remote = remote
    end

    def remote
      return @remote if @remote

      if ref
        if ref.match(%r<^(?:refs/)?remotes/([^/]+)/>)
          @remote = $1
        end
      end

      @remote ||= 'origin'
    end

    def mode=(mode)
      @mode = mode
    end

    def mode
      return @mode if @mode

      if ref
        if ref.match(%r<^((?:refs/)?(?:heads|remotes/[^/]+)/)?master$>)
          @mode = :top
        elsif ref.match(%r<^(?:refs/)?(?:heads|tags|remotes)/>)
          @mode = :ref
        end
      end

      @mode || :rev
    end

    def _commit(short = false)
      if short
        Git.parse_rev_short(target || 'HEAD')
      else
        Git.parse_rev(target || 'HEAD')
      end
    end

    def commit
      _commit
    end

    def short_commit
      _commit(true)
    end

    def _rev(short = false)
      if mode == :rev
        _commit(short)
      else
        _ref(short) || _commit(short)
      end
    end

    def rev
      _rev
    end

    def short_rev
      _rev(true)
    end

    def _ref(short = false)
      if short
        @ref.sub(%r(^refs/), '')
            .sub(%r(^heads/), '')
            .sub(%r(^tags/), '')
            .sub(%r(^remotes/([^/]+)/), '')
      else
        @ref
      end
    end

    def ref
      _ref
    end

    def short_ref
      _ref(true)
    end

    def target=(target)
      @target = target
    end

    def target
      return @target if @target
      @target ||= Git.resolved_head
    end
  end
end
