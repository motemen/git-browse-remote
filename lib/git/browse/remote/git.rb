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
end
