#!/usr/bin/ruby

def main()
	if ARGV.empty? then
		puts "Usage ./port-install-from.rb hostname"
		puts ""
		puts "Installs all macports packages present on hostname on the local machine"
		puts ""
		puts "It is highly recommended to use this script in conjunction with shared"
		puts "archives so you don't have to compile everything twice. See the"
		puts "instructions at:"
		puts "  https://trac.macports.org/wiki/howto/ShareArchives2"
		exit -1
	end

	remote_host = ARGV[0]

	puts "Connecting to #{remote_host} via ssh to read port list"
	remote_packages = parse_package_list `ssh "#{remote_host}" port installed`
	local_packages = parse_package_list `port installed`

	to_install = packages_to_install(local_packages, remote_packages)

	if not to_install.empty? then
		install_line = to_install.map { |name, version| "#{name}@#{version}" }.join(" ")
		puts "Installing " + install_line
		system 'sudo sh -c "port selfupdate && port install ' + install_line + '"'
	else
		puts "Nothing to install"
	end
end


def parse_package_list(package_list)
	parsed_packages = {}
	package_list.each_line do |line| 
		if line.include? "(active)" then
			line.strip!
			package, version = line.split
			version.slice!(0)

			parsed_packages[package] = version
		end
	end
	parsed_packages
end


def packages_to_install(local_packages, remote_packages)
	to_install = {}
	remote_packages.each do |name, remote_version|
		if local_packages.has_key? name then
			local_version = local_packages[name]
			if remote_version.newer_than? local_version then
				to_install[name] = remote_version
			elsif local_version.newer_than? version then
				puts "Package #{name} local version (#{local_version}) is newer than remote version (#{version})"
			end
		else
			to_install[name] = remote_version
		end
	end

	to_install
end


class String
	def newer_than? (other) 
		self_as_list = self.scan(/\d+|\D+/).map {|part| part =~ /\d+/ ? part.to_i : part }
		other_as_list = other.scan(/\d+|\D+/).map {|part| part =~ /\d+/ ? part.to_i : part }

		return (self_as_list <=> other_as_list) > 0 
	end
end

main
