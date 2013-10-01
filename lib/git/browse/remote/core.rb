require 'git/browse/remote/git'

module Git::Browse::Remote
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

    def target=(target)
      @target = target
    end

    def target
      return @target if @target
      @target ||= Git.resolved_head
    end
  end
end
