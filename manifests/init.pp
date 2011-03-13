#
# Puppet Ruby Enterprise Edition Installation Module (from source and rvm)
#
# Copyright (C) 2010 Davide Guerri (davide.guerri@gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# ### Installing ruby enterprise edition from source ###
#
#	Usage:
#
#		ruby_enterprise::from_source { "ruby-enterprise-1.8.7_2011.03": }
#
#	OR
#
#		ruby_enterprise::from_source { "ruby-enterprise-1.8.7_2011.02": 
# 			ruby_version => "1.8.7",
#			ruby_enterprise_revision => "2011.02",
#		}
#
#	Supported parameters:
#
#		* ruby_version
#			Desired ruby version (Please see http://code.google.com/p/rubyenterpriseedition/downloads/list)
#			Defaults to "1.8.7"
#		* ruby_enterprise_revision
#			Desired ruby enterprise revision (See http://code.google.com/p/rubyenterpriseedition/downloads/list)
#			Defaults to "2011.03"
#		* destination_base_directory
#			Destination directory for ruby enterprise. 
#			Defaults to "/opt"
#			Please note that the actual destination directory will be:
#				
#				"${destination_base_directory}/ruby-enterprise-${ruby_version}-${ruby_enterprise_revision}"
#
#
#	Defines:
#		
#		Exec[ "ruby-enterprise-${ruby_version}-${ruby_enterprise_revision}_install" ]
#
#
#			
# ### Installing ruby enterprise edition from rvm ###
#
#	Usage:
#
#		rvm::system_wide { "rvm": }	# See the puppet-rvm module
#		ruby_enterprise::from_rvm { "ruby-enterprise-1.8.7_2011.03": }
#
#	OR
#
#		rvm::system_wide { "rvm": }	# See the puppet-rvm module
#		ruby_enterprise::from_rvm { "ruby-enterprise-1.8.7_2011.02": 
#			ruby_version => "1.8.7",
#			ruby_enterprise_revision => "2011.02",
#		}
#
#	Supported parameters:
#
#		* ruby_version
#			Desired ruby version (Please see http://code.google.com/p/rubyenterpriseedition/downloads/list)
#			Defaults to "1.8.7"
#		* ruby_enterprise_revision
#			Desired ruby enterprise revision (See http://code.google.com/p/rubyenterpriseedition/downloads/list)
#			Defaults to "2011.03"
#
#	Require:
#
#		Exec[ "rvm_install" ]
#	
#	Defines:
#
#		Exec[ "rvm_ruby-enterprise-${ruby_version}-${ruby_enterprise_revision}_install" ]
#

define ruby_enterprise::from_source ( 
	$ruby_version = "1.8.7", 
	$ruby_enterprise_revision = "2011.03", 
	$destination_base_directory = "/opt" ) {

	# Setting global parameters and environment
	$package_name = "ruby-enterprise-${ruby_version}-${ruby_enterprise_revision}"
	$package_targz_name = "${package_name}.tar.gz"
	$package_uri = "http://rubyenterpriseedition.googlecode.com/files/${package_targz_name}"
	$destination_directory = "${destination_base_directory}/${package_name}/"
	$ruby_executable_path = "${destination_directory}/bin/ruby"
	$working_directory = "/tmp"
	$timeout = 600 # 10 minutes

	Exec { 
		path => [
			'/usr/local/bin',
			'/usr/local/sbin',
			'/usr/bin',
			'/usr/sbin',
			'/bin/',
			'/sbin',
		],
		cwd => $working_directory,
	}

	# Setting up requisites

	case $operatingsystem {
		Ubuntu, Debian: { 
			$required_packages = [ 
				'tar', 
				'wget', 
				'build-essential', 
				'patch', 
				'zlib1g-dev', 
				'libssl-dev', 
				'libreadline5-dev' 
			] 
		}
		RedHat, Fedora, Centos: { # Untested!
			$required_packages = [ 
				'tar', 
				'wget', 
				'gcc-c++', 
				'make', 
				'patch', 
				'zlib-devel', 
				'openssl-devel', 
				'readline-devel' 
			] 
		}
		default: { 
			fail("Unsupported distribution!") 
		}
	}

	package { "ruby_enterprise_from_source_required_packages":
		name => $required_packages,
		ensure => installed,
	}

	file { 'ruby_enterprise_destination_base_directory':
		path => "${destination_base_directory}",
		ensure => directory,
		owner => root,
		group => root,
		mode => 755,
	}

	# Proceding with download, untar and install

	exec { "${package_name}_download":
		command => "wget -q '$package_uri' -O '${working_directory}/${package_targz_name}'",
		creates => "${working_directory}/${package_targz_name}",
		require => Package[ "ruby_enterprise_from_source_required_packages" ],
		unless => "test -f ${ruby_executable_path}",
	}

	exec { "${package_name}_untar":
		command => "tar xzf ${package_targz_name}",
		timeout => $timeout,
		require => Exec[ "${package_name}_download" ],
	}

	exec { "${package_name}_install":
		command => "./installer --auto ${destination_directory}",
		cwd => "${working_directory}/${package_name}/",
		timeout => $timeout,
		require => Exec[ "${package_name}_untar" ],
	}

	tidy { "${package_name}_source_remove":
		path => "${working_directory}",
		require => Exec[ "${package_name}_install" ],
		recurse => 1,
		matches => [ "${package_name}*" ],
	}

}

define ruby_enterprise::from_rvm ( 
	$ruby_version = "1.8.7", 
	$ruby_enterprise_revision = "2011.03") {

	# Setting global parameters and environment
	$package_name = "ruby-enterprise-${ruby_version}-${ruby_enterprise_revision}"
	$rvm_package_name = "ree-${ruby_version}-${ruby_enterprise_revision}"
	$working_directory = "/tmp"
	$timeout = 600 # 10 minutes

	Exec { 
		path => [
			'/usr/local/bin',
			'/usr/local/sbin',
			'/usr/bin',
			'/usr/sbin',
			'/bin/',
			'/sbin',
		],
		cwd => $working_directory,
	}

	# Setting up requisites

	case $operatingsystem {
		Ubuntu, Debian: { 
			$required_packages = [ 
				'build-essential', 
				'patch', 
				'zlib1g-dev', 
				'libssl-dev', 
				'libreadline5-dev'
			] 
		}
		RedHat, Fedora, Centos: { # Untested!
			$required_packages = [ 
				'gcc-c++', 
				'make', 
				'patch', 
				'zlib-devel', 
				'openssl-devel', 
				'readline-devel' 
			] 
		}
		default: { 
			fail("Unsupported distribution!") 
		}
	}

	package { "rvm_${package_name}_required_packages":
		name => $required_packages,
		ensure => installed,
	}

	# Proceding with download, untar and install

	exec { "rvm_${package_name}_install":
		command => "rvm install ${rvm_package_name}",
		timeout => $timeout,
		require => [	
			Exec[ "rvm_install" ],
			Package[ "rvm_${package_name}_required_packages" ], 
		],
		unless => "rvm use ree",
	}
}

