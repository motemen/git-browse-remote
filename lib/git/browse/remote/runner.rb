require 'git/browse/remote/core'
require 'git/browse/remote/version'
require 'optparse'

module Git::Browse::Remote
  class Runner
    def initialize(args)
      @args = args
      @core = Core.new
    end

    def parse_args!
      OptionParser.new do |opt|
        opt.banner  = 'git browse-remote [options] [<commit> | <remote>] [--] [<file>]'
        opt.version = VERSION
        opt.on('-r', '--remote=<remote>', 'specify remote') { |r| @core.remote = r }

        opt.on('--stdout', 'prints URL instead of opening browser') { @stdout = true }

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

          @core.init!(host, name.to_sym)

          STDERR.puts 'Mappings generated:'
          exec "git config --get-regexp ^browse-remote\\.#{host}\\."
        end
        opt.on('-L <n>', 'specify line number (only meaningful on file mode)', Integer) { |n| @core.line = n }
      end.parse!(@args)

      @core.target, @core.file = *@args[0..1]
    end

    def run
      parse_args!

      if @stdout
        puts @core.url
      else
        exec 'git', 'web--browse', @core.url
      end
    end
  end
end
