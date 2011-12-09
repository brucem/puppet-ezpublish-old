define ezpublish::database(
    $db_name = 'ez_demo',
    $db_user = 'ez_demo',
    $db_pass = 'password',
    $db_host = 'localhost',
    $ensure  = 'present'
) {
    # Setup Database & DB user
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

}
