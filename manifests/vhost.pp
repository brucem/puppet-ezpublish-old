define ezpublish::vhost(
    $domain          = 'demo.ez.no',
    $timezone        = 'GMT',
    $db_name         = 'ez_demo',
    $db_user         = 'ez_demo',
    $db_pass         = 'password',
    $db_host         = 'localhost',
    $ez_primary_lang = 'eng-GB',
    $ez_site_title   = 'Demo Site',
    $ez_admin_fn     = 'Admin',
    $ez_admin_ln     = 'User',
    $ez_admin_pass   = 'publish',
    $ez_admin_email  = 'nospam@ez.no',
    $ez_package      = 'ezflow_site', # plain_site|ezwebin_site|ezwebin_site_clean|ezflow_site|ezflow_site_clean
    $version         = 'latest',
    $ensure          = 'present'
)
{
    case $version {
        latest,2011.11: {
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

    # where downloaded copies of eZ publish are kept
    $dist_dir = '/var/ezpublish-dist'

    file{ $ezpublish::dist_dir:
        ensure => 'directory'
    }

    host { $domain:
        ensure => 'present',
        ip     => '127.0.0.1',
    }

    # Setup webserver
    apache::vhost{ $domain:
        ensure  => $ensure,
        notify  => Exec["apache-graceful"],
        enable_default => false,
        mode    => "02775",
        group   => "www-data",
        user    => "vagrant",
    }

    apache::directive { "${domain} php settings":
        ensure    => $ensure,
        directive => template('ezpublish/apache/php_settings.erb'),
        vhost     => $domain,
    }

    apache::directive { "${domain} rewrite settings":
        ensure    => $ensure,
        directive => template('ezpublish/apache/rewrite.erb'),
        vhost     => $domain,
    }

    mysql::rights { $db_user:
        ensure   => $ensure,
        user     => $db_user,
        password => $db_pass,
        database => $db_name,
        host     => $db_host,
    }

    mysql::database { $db_name:
        ensure  => $ensure,
        require => Mysql::Rights[$db_user],
    }

    download_file { $download_file:
        site => $download_url,
        cwd  => $ezpublish::dist_dir,
        creates => "${ezpublish::dist_dir}/${name}",
        require => File[$ezpublish::dist_dir],
    }

    extract_file { "${ezpublish::dist_dir}/${download_file}":
        dest    => "/var/www/${domain}/htdocs",
        options => "--strip-components=1",
        user    => 'vagrant',
        onlyif  => "test \$(/usr/bin/find /var/www/${domain}/htdocs | wc -l) -eq 1",
        notify  => Enforce_perms["Enforce g+rw /var/www/${domain}/htdocs"],
        require => [Download_file[$download_file], Apache::Vhost[$domain]],
    }

    enforce_perms{ "Enforce g+rw /var/www/${domain}/htdocs":
        dir     => "/var/www/${domain}/htdocs",
        perms   => "g+rw",
        require => Extract_file[ "${ezpublish::dist_dir}/${download_file}" ],
    }

    file {"/var/www/${domain}/htdocs/kickstart.ini":
        content => template('ezpublish/ezpublish/kickstart.ini.erb'),
        owner   => 'vagrant',
        group   => 'www-data',
        mode    => "0664",
        require => Extract_file[ "${ezpublish::dist_dir}/${download_file}" ],
    }
}

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
