# Installs mysql database
class ezpublish::standalone inherits ezpublish {
    require mysql::server
}
