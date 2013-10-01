require 'git/browse/remote/core'
require 'git/browse/remote/version'
require 'optparse'

module Git::Browse::Remote
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
        opt.banner  = 'git browse-remote [options] [<commit> | <remote>] [--] [<file>]'
        opt.version = VERSION
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
end
