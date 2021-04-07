# Common provisioning roles

This repo contains common web development Ansible roles that could be reused freely.

## Usage

Start playbook with root remote ssh user on a newly created or non provisioned server. Afterwards the common role will prevent ssh login for root and create local user with sudo capability. Subsequent runs should use command line -K flag to enter sudo password from console. Additionally indicate remote SSH user that initializes SSH connection in your inventory or playbook.

    ansible-playbook -i hosts default-playbook.yml -k -K

Inventory file example "hosts":

    [localhost]
    127.0.0.1 ansible_connection=local
    
    [example]
    example.com ansible_ssh_user=foo ansible_become_user=root

Additionally if you have problems resolving python libraries add this to you inventory.

    [example]
    example.com ansible_python_interpreter=/usr/bin/python3

**Playbook configuration**

./files directory is used for custom install packages that could not be downloaded by ansible directly, either because of proxy restrictions or if there are no direct download links available (ie. oracle).
Make sure to check role default variables for expected install packages.
1. Oracle: roles/oracle/defaults/main.yml -> variable _oracle_instantclient_packages_

All other default role variables (roles/*/defaults/main.yml) can be overriden at playbook or inventory or group_vars level.


### Global variables

Should be defined for any playbook.

```yaml
app_user: app
app_uid: 1000
admin_user: foobar
admin_user_password: # could be blank
server_hostname: example.com
web_domain: # defaults to server_hostname
```

## Available roles

### Apache
Installs and configures Apache2 web server in mod_event mode.

Available variables:

```yaml
http_document_root: "/var/www/{{ server_hostname }}"
http_domain_name: # defaults to global web_domain or example.com
letsencrypt_email: ssl@example.com
install_letsencrypt: true
```
    
### Common
Installs and configures server environment (bash, cron, various config, unattended auto upgrades).

Local directory ./files can be populated with private / public keys names {{ app_user }}.key and {{ app_user }}.key.pub for automatic SSH key based authentication.

Available variables:

```yaml
unattended_upgrades_email: root
unattended_upgrades_enable: true
user_default_shell: /bin/bash
app_user: appuser
app_uid: 1000
admin_user: adminuser
admin_user_password: # could be blank
server_hostname: example.com
default_packages: []
```
    
### Composer
Installs PHP Composer package manager globally.

Available variables:

    composer_path: /usr/local/bin/composer
    
### Fail2Ban
Installs and configures security Fail2Ban service.
    
### Mediawiki-Parsoid
Installs and configures Mediawiki Parsoid service for Mediawiki application. 

Available variables:

    parsoid_uri: localhost

### Memcached
Installs and configures Memcached daemon. 

Available variables:

```yaml
memcached_settings:
  - name: m # Memory consumption
    value: 200
  - name: c # Max connections
    value: 1024
```

### Mysql
Installs and configures MySQL database server. Additionally it creates configured users and databases. Imports data from local SQL dump files if files are available and _ONLY_ if databases were created for the first time.  

Available variables:

```yaml
mysql_user: mysql
mysql_root_password: password
mysql_port: 3306
mysql_dump_dir: /tmp/mysqldumps

# Example
# mysql_databases:
#   - database: dbname
#     user: user
#     password: password
#     dump_file: filepath
mysql_databases: []
```

### Oracle
Installs and configures Oracle database server. Role expects user to manually download and prepare installation packages in playbook's files directory.

Available variables:

```yaml
install_packages_dir: "{{ playbook_dir }}/files"

# default install packages directory
oracle_instantclient_package_dir: "{{ install_packages_dir }}/oracle-instantclient"

# list of package files that has to be installed in specific order
oracle_instantclient_packages:
    - {filename: 'oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm'}
    - {filename: 'oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm'}
    - {filename: 'oracle-instantclient12.2-jdbc-12.2.0.1.0-1.x86_64.rpm'}
    - {filename: 'oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm'}

oracle_instantclient_lib: "/usr/lib/oracle/12.2/client64/lib/"
oracle_instantclient_home: "/usr/lib/oracle/12.2/client64"
oracle_instantclient_include: "/usr/include/oracle/12.2/client64"
```

### PHP
Installs and configures PHP and PHP-FPM server. Automatically configures FPM pools and connects with Apache.

Available variables:

```yaml
php_web_domain: # defaults to global web_domain or example.com
php_fpm_pool: www
php_fpm_memory_limit: 128M
php_fpm_listen_allowed_clients: 127.0.0.1
php_fpm_listen_owner: www-data
php_fpm_listen_group: www-data
php_fpm_listen_mode: 0660
php_fpm_pm_mode: dynamic
php_fpm_pm_max_children: 50
php_fpm_pm_start_servers: 5
php_fpm_pm_min_spare_servers: 5
php_fpm_pm_max_spare_servers: 35
php_fpm_pm_max_requests: 500

# Oracle related configuration
oracle_instantclient_include: /usr/include/oracle/12.2/client64
php_oci8_tns_admin: /usr/lib/oracle/12.2/client64/network/admin
php_oci8_nls_lang: AMERICAN_AMERICA.WE8MSWIN1252
php_oci8_nls_sort: AMERICAN
php_oci8_nls_date_format: yyyy-mm-dd hh24:mi:ss
php_oci8_lang: en_US
php_oci8_nls_numeric_characters: .,
```
    
### Postfix
Installs and configures Postfix outgoing mail server, Dovecot incoming mail server, Amavis with Spamassasin and Clam Antivirus support plus extra email tools.

Available variables:

```yaml
postfix_config_file: /etc/postfix/main.cf
postfix_inet_interfaces: localhost
postfix_inet_protocols: all
postfix_maildir_name: Maildir
postfix_mail_hostname: # defaults to global web_domain or example.com
postfix_virtual_user_map:
  - emails:
      - admin@localhost
    user: "{{ app_user }}"
dkim_short_domain: # defaults to global web_domain or example.com
```
    
### RabbitMQ
Installs and configures RabbitMQ message broker server. 

Available variables:

```yaml
rabbitmq_plugins:
  - rabbitmq_management

rabbitmq_users:
  - user: "admin"
    password: "adminpasswd"
    vhost: /
    configure_priv: .*
    read_priv: .*
    write_priv: .*
    tags: administrator
```
    
### Redis
Installs and configures Redis - in memory database.
    
### Supervisor
Installs and configures process management tool SupervisorD. 

Available variables:

    supervisor_command_name: batch_consumer
    supervisor_command_path: path/to/binary or command
        
### BigBlueButton LXD host (bbb-lxd-host)
Installs and configures server to support multiple load balanced BigBlueButton instances running in isolated LXC containers. 

Available variables:

```yaml
# Install these extra yum packages
bbb_lxd_host_packages:
- lxc-templates
- lxc-utils
- net-tools

# This is the name of LXC profile that should be used for all BBB LXC instances
bbb_lxd_profile: bbb_macvlan

# Mount point for extra LXC storage volume mounted within the container. If empty storage volume will not be created.
bbb_lxd_storage_shared: /opt/bbbshared

# The name of local network used for communication between containers directly. If empty network will not be created.
bbb_lxd_bridged_network: ''

# Default profile storage pool name for directory root.
bbb_lxd_storage_pool_default: default

# Storage pool name used for storage volume for BigBlueButton files
bbb_lxd_storage_pool: bigbluebutton

# Host OS path where LXC storage pool is created. Leave empty and role will not create new storage pool.
bbb_lxd_storage_pool_dir: ''
```
    
### Wkhtml
Installs webkit based PDF renderer engine. 

## Example Playbook

```yaml
- name: "Provision remote server"
  hosts:
    - example.com
  handlers:
    - import_tasks: handlers/global.yml
  connection: ssh
  become: yes
  become_user: root
  become_method: sudo
  gather_facts: yes
  force_handlers: true
  any_errors_fatal: true
  vars:
    app_user: app
    admin_user: foobar
    app_uid: 1000
    server_hostname: app
    hostname: example.com

  pre_tasks:
    - name: Update APT cache
      apt: update_cache=yes

  roles:
    - role: common
      vars:
        unattended_upgrades_email: root
    - role: apache
      vars:
        http_document_root: "/var/www/{{ server_hostname }}"
        http_domain_name: example.com
        letsencrypt_email: ssl@example.com
        install_letsencrypt: false
    - oracle
    - php
    - composer
    - role: memcached
      vars:
        memcached_settings:
          - name: m # Memory consumption
            value: 200
    - wkhtml
    - redis
    - rabbitmq
    - supervisor
    - postfix
    - fail2ban
    - role: mysql
      vars:
        mysql_root_password: password
        mysql_databases:
          - database: dbname
           user: user
           password: password
           dump_file: filepath
    - role: mediawiki-parsoid
      vars:
        parsoid_uri: "http://www.{{ http_domain_name }}/w/api.php"
```

## License

MIT / BSD

## Author Information

Created in 2018 by [Andrej Vitez](https://www.andrejvitez.com/).
