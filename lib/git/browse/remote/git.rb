module Git::Browse::Remote
  module Git
    def self.is_valid_rev?(target)
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

    def self.full_name_of_rev(rev)
      `git rev-parse --symbolic-full-name #{rev}`[/.+/] or `git rev-parse --symbolic-full-name #{name_rev(rev)}`[/.+/]
    end

    # the ref whom HEAD points to
    def self.resolved_head
      `git symbolic-ref -q HEAD`[/.+/]
    end

    def self.name_rev(rev)
      `git name-rev --name-only #{rev}`.chomp
    end

    def self.symbolic_name_of_head
      name_rev('HEAD').sub(%r(\^0$), '') # some workaround for ^0
    end

    def self.show_prefix
      `git rev-parse --show-prefix`.chomp
    end
  end
end
