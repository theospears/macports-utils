#!/usr/bin/ruby

if ARGV.empty? then
	puts "Usage ./port-install-from.rb hostname"
	exit -1
end

remote_host = ARGV[0]

class String
	def newer_version_than? (other) 
		self_as_list = self.scan(/\d+|\D+/).map {|part| part =~ /\d+/ ? part.to_i : part }
		other_as_list = other.scan(/\d+|\D+/).map {|part| part =~ /\d+/ ? part.to_i : part }

		return (self_as_list <=> other_as_list) > 0 
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

local_packages = parse_package_list `port installed`
remote_packages = parse_package_list `ssh #{remote_host} port installed`

packages_to_install = {}

remote_packages.each do |name, version|
	if local_packages.has_key? name then
		local_version = local_packages[name]
		if version.newer_version_than? local_version then
			packages_to_install[name] = version
		elsif local_version.newer_version_than? version then
			puts "Package #{name} local version (#{local_version}) is newer than remote version (#{version})"
		end
	else
		packages_to_install[name] = version
	end
end

if not packages_to_install.empty? then
	install_line = packages_to_install.map { |name, version| "#{name}@#{version}" }.join(" ")
	puts "Installing " + install_line
	system 'sudo sh -c "port selfupdate && port install ' + install_line + '"'
else
	puts "Nothing to install"
end
