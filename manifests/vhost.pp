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
    $ensure          = 'present'
)
{
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

    download_file { 'ezpublish_community_project-2011.10-with_ezc.tar.gz':
        site => 'http://share.ez.no/content/download/120893/567721/version/2/file/',
        cwd  => "/var/www/${domain}/htdocs",
        creates => "/var/www/${domain}/htdocs/${name}",
        user    => 'vagrant',
        require => Apache::Vhost[$domain],
    }

    extract_file { "/var/www/${domain}/htdocs/ezpublish_community_project-2011.10-with_ezc.tar.gz":
        dest    => "/var/www/${domain}/htdocs",
        options => "--strip-components=1",
        user    => 'vagrant',
        onlyif  => "test \$(/usr/bin/find /var/www/${domain}/htdocs | wc -l) -eq 2",
        notify  => Enforce_perms["Enforce g+rw /var/www/${domain}/htdocs"],
        require => Download_file['ezpublish_community_project-2011.10-with_ezc.tar.gz'],
    }

    enforce_perms{ "Enforce g+rw /var/www/${domain}/htdocs":
        dir     => "/var/www/${domain}/htdocs",
        perms   => "g+rw",
        require => Extract_file[ "/var/www/${domain}/htdocs/ezpublish_community_project-2011.10-with_ezc.tar.gz" ],
    }

    file {"/var/www/${domain}/htdocs/kickstart.ini":
        content => template('ezpublish/ezpublish/kickstart.ini.erb'),
        owner   => 'vagrant',
        group   => 'www-data',
        mode    => "0664",
        require => Download_file['ezpublish_community_project-2011.10-with_ezc.tar.gz'],
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
        $creates="",
        $user="")
{
    exec { $name:
        command => "wget ${site}/${name}",
        cwd => $cwd,
        creates => "${cwd}/${name}",
        user => $user,
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
