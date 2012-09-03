define ezpublish::vhost(
    $user,
    $aliases  = [],
    $docroot  = false,
    $timezone = 'GMT',         # http://php.net/manual/en/timezones.php
    $ensure   = 'present'
)
{
    # Setup webserver
    apache::vhost{ $name:
        ensure  => $ensure,
        notify  => Exec["apache-graceful"],
        mode    => "02775",
        group   => "www-data",
        user    => $user,
        aliases => $aliases,
        docroot => $docroot,
    }

    apache::directive { "${name} php settings":
        ensure    => $ensure,
        directive => template('ezpublish/apache/php_settings.erb'),
        vhost     => $name,
    }

    apache::directive { "${name} rewrite settings":
        ensure    => $ensure,
        directive => template('ezpublish/apache/rewrite.erb'),
        vhost     => $name,
    }

}
