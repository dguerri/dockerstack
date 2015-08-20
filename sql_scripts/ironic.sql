CREATE DATABASE IF NOT EXISTS ironic;
GRANT ALL PRIVILEGES ON ironic.* TO '%IRONIC_DB_USER%'@'localhost' \
    IDENTIFIED BY '%IRONIC_DB_PASS%';
GRANT ALL PRIVILEGES ON ironic.* TO '%IRONIC_DB_USER%'@'%' \
    IDENTIFIED BY '%IRONIC_DB_PASS%';