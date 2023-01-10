require 'git/browse/remote/git'
require 'pathname'
require 'uri'

module Git::Browse::Remote
  class Path < Array
    def to_s
      join('/')
    end
  end

  class Filepath < Pathname
    def to_s
      Pathname.new(Git.show_prefix).join(super).cleanpath.to_s
    end
  end

  class Core
    attr_accessor :lines, :file

    MAPPING_RECIPES = {
      :github => {
        :top  => 'https://{host}/{path}',
        :ref  => 'https://{host}/{path}/tree/{short_ref}',
        :rev  => 'https://{host}/{path}/commit/{commit}',
        :pr   => 'https://{host}/{path}/pull/{short_ref}',
        :file => 'https://{host}/{path}/{file.directory? and :tree or :blob}/{short_rev}/{file}{lines && "#L%s" % lines.join("-")}',
      },

      :gitweb => {
        :top => 'http://{host}/?p={path[-2..-1]}.git',
        :ref => 'http://{host}/?p={path[-2..-1]}.git;h={ref}',
        :rev => 'http://{host}/?p={path[-2..-1]}.git;a=commit;h={ref}',
        # XXX
        # I don't know file url of gitweb...
      }
    }

    def template_type
      if @file
        :file
      else
        mode
      end
    end

    def init!(host, name)
      mapping = MAPPING_RECIPES[name] or abort "Recipe '#{name}' not found"
      mapping.each do |mode,template|
        system %Q(git config --global browse-remote.#{host}.#{mode} '#{template}')
      end
    end

    def url
      if target && !@file && File.exist?(target)
        self.target, @file = nil, target
      end

      if @file && File.exist?(@file)
        @file = Filepath.new(@file)
      end

      if target
        if Git.is_valid_rev? target
          @ref = Git.full_name_of_rev(target)
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

      unless %r(^\w+://) === remote_url
        # SCP-like URLs of form "[user@]host.xz:path/to/repo.git"
        # will be converted to "ssh://[user@]host.xz/path/to/repo.git"
        remote_url = 'ssh://' + remote_url.sub(/:/, '/')
      end

      # Normal URLs
      u = URI(remote_url)
      host = u.host
      port = u.port
      host_port = if port == u.default_port then host else "#{host}:#{port}" end
      path = u.path.sub(%r(^/), '').split('/')
      path.last.sub!(/\.git$/, '')
      path = Path.new(path)

      template = `git config --get browse-remote.#{host}.#{template_type}`[/.+/]
      if not template and host == 'github.com'
        template = MAPPING_RECIPES[:github][template_type.to_sym] or
          abort "No '#{template_type}' mapping found for #{host} (maybe `git browse-remote --init` required)"
      end

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
        @ref.sub(%r(^refs/), '').
             sub(%r(^heads/), '').
             sub(%r(^tags/), '').
             sub(%r(^remotes/([^/]+)/), '')
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

    def line
      lines and lines.first
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
