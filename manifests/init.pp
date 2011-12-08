# Create an environment for an eZPublish installation
class ezpublish {
    require augeas
    require php
    require apache
    require php::apache
    require mysql::client

    # Central location of downloaded copies of eZ publish
    $dist_dir = '/var/ezpublish-dist'

    # Install php modules
    $php_module_list = ["mysql", "gd", "mcrypt", "imagick", "curl"]
    php::module{ $php_module_list:
        notify => Service["apache"],
    }

    # Install pear packages
    $php_pear_package_list = [ "apc", "pear" ]
    php::pear{ $php_pear_package_list:
        notify => Service["apache"],
    }

    # Install any required packages
    $package_list =["imagemagick"]
    package{ $package_list:
        ensure  => present,
    }

}
