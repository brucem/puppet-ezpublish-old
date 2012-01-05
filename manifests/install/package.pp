define ezpublish::install::package(
    $vhost,
    $ez_primary_lang = 'eng-GB',
    $ez_site_title   = 'Demo Site',
    $ez_admin_fn     = 'Admin',
    $ez_admin_ln     = 'User',
    $ez_admin_pass   = 'publish',
    $ez_admin_email  = 'nospam@ez.no',
    $ez_package      = 'ezflow_site', # plain_site|ezwebin_site|ezwebin_site_clean|ezflow_site|ezflow_site_clean
    $version         = 'latest'       # latest|2011.12|2011.11|2011.10|2011.9|2011.8
)
{
    # Work out where to get the version of eZ Publish from
    case $version {
        latest,2011.12: {
            $download_url = 'http://share.ez.no/content/download/122947/664516/version/1/file/'
            $download_file = 'ezpublish_community_project-2011.12-with_ezc.tar.gz'
        }
        2011.11: {
            $download_url = 'http://share.ez.no/content/download/122233/573797/version/1/file/'
            $download_file = 'ezpublish_community_project-2011.11-with_ezc.tar.gz'
        }
        2011.10: {
            $download_url = 'http://share.ez.no/content/download/120893/567721/version/2/file/'
            $download_file = 'ezpublish_community_project-2011.10-with_ezc.tar.gz'
        }
        2011.9: {
            $download_url = 'http://share.ez.no/content/download/119530/561729/version/1/file/'
            $download_file = 'ezpublish_community_project-2011.9-with_ezc.tar.gz'
        }
        2011.8: {
            $download_url = 'http://share.ez.no/content/download/118009/553426/version/3/file/'
            $download_file = 'ezpublish_community_project-2011.8-with_ezc.tar.gz'
        }
        default: { fail("Unrecognized eZ Publish version") }
    }

    # Where downloaded copies of eZ Publish are kept
    $dist_dir = '/var/ezpublish-dist'

    file{ $ezpublish::dist_dir:
        ensure => 'directory'
    }

    # Setup a hosts entry on the VM so the AcceptPathInfo Test works.
    # This isn't required when not running in a VM as the DNS should already be
    # setup.

    if $virtual == "virtualbox" {
        host { $vhost:
            ensure => $ensure,
            ip     => '127.0.0.1',
        }
    }

    # Ensure we have a local copy of the eZ Publish version
    download_file { $download_file:
        site => $download_url,
        cwd  => $ezpublish::dist_dir,
        creates => "${ezpublish::dist_dir}/${name}",
        require => File[$ezpublish::dist_dir],
    }

    # Extract the distribution into the DocRoot
    extract_file { "${ezpublish::dist_dir}/${download_file}":
        dest    => "/var/www/${vhost}/htdocs",
        options => "--strip-components=1",
        user    => $user,
        onlyif  => "test \$(/usr/bin/find /var/www/${vhost}/htdocs | wc -l) -eq 1",
        notify  => Enforce_perms["Enforce g+rw /var/www/${vhost}/htdocs"],
        require => [Download_file[$download_file], Apache::Vhost[$vhost]],
    }

    # Ensure the group can read and write the files
    enforce_perms{ "Enforce g+rw /var/www/${vhost}/htdocs":
        dir     => "/var/www/${vhost}/htdocs",
        perms   => "g+rw",
        require => Extract_file[ "${ezpublish::dist_dir}/${download_file}" ],
    }

    # Setup a kickstart.ini file the details
    file {"/var/www/${vhost}/htdocs/kickstart.ini":
        content => template('ezpublish/ezpublish/kickstart.ini.erb'),
        owner   => $user,
        group   => 'www-data',
        mode    => "0664",
        require => Extract_file[ "${ezpublish::dist_dir}/${download_file}" ],
    }
}

# Utility definations
define extract_file(
        $dest    = '.',
        $options = '',
        $user    = 'root',
        $onlyif  = '' )
{
    exec { $name:
        command => "tar xzf ${name} -C ${dest} ${options}",
        user    => $user,
        onlyif  => $onlyif,
    }
}

define download_file(
        $site="",
        $cwd="",
        $creates="")
{
    exec { $name:
        command => "wget ${site}/${name}",
        cwd => $cwd,
        creates => "${cwd}/${name}",
    }
}

define enforce_perms(
    $dir,
    $perms
)
{
    exec { "enforce ${dir} permissions":
      command => "chmod -R ${perms} ${dir}",
      onlyif  => "test \$(/usr/bin/find ${dir} ! -perm -${perms} | wc -l) -gt 0",
    }
}
