# Common provisioning roles

This repo contains common web development Ansible roles that could be reused freely.

## Usage

Start playbook with root remote ssh user on a newly created or non provisioned server. Afterwards the common role will prevent ssh login for root and create local user with sudo capability. Subsequent runs should use command line -K flag to enter sudo password from console. Additionally indicate remote SSH user that initializes SSH connection in your inventory or playbook.

    ansible-playbook -i hosts default-playbook.yml -k -K

Example with custom roles path and more logging.

    ANSIBLE_ROLES_PATH=$(pwd)/roles ANSIBLE_LOG_PATH=ansible.log ansible-playbook -i inventory/hosts.ini -l custom_host_group -e '@inventory/group_vars/mef_bbb_dev.yml'  playbooks/example.yml -vvv

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

### OpenVPN
Installs and configures OpenVPN server with Easy-RSA PKI for certificate management. Supports NAT alias feature for accessing remote networks with conflicting subnets.

**See full documentation:** [roles/openvpn/README.md](roles/openvpn/README.md)

**Features:**
- OpenVPN server with TLS authentication
- Easy-RSA PKI for certificate generation
- UFW or iptables firewall configuration
- NAT alias translation for subnet conflict resolution
- Support for TCP (SSH tunnel compatible) or UDP protocols
- Client certificate generation

**NAT Alias Feature:**
When your local network and remote LAN use the same subnet (e.g., both 192.168.0.0/24), NAT alias allows you to access remote servers via an alias subnet (e.g., 10.127.0.x → 192.168.x.x).

Available variables:

```yaml
# Server network settings
openvpn_server_port: 1194
openvpn_server_protocol: udp  # or tcp for SSH tunnel compatibility
openvpn_server_listen: ""     # Listen address (empty = all interfaces, "127.0.0.1" for localhost only)
openvpn_server_network: "10.8.0.0"
openvpn_server_netmask: "255.255.255.0"

# Routes to push to clients
openvpn_push_routes:
  - "192.168.100.0 255.255.255.0"

# NAT Alias Configuration (for subnet conflicts)
openvpn_use_nat_alias: false
openvpn_nat_alias_network: "10.127.0.0"      # Alias subnet clients use
openvpn_nat_alias_netmask: "255.255.255.0"
openvpn_remote_lan_network: "192.168.100.0"  # Actual remote LAN subnet
openvpn_remote_lan_interface: "eth0"         # Interface to remote LAN

# Easy-RSA PKI settings
openvpn_easyrsa_country: "US"
openvpn_easyrsa_province: "State"
openvpn_easyrsa_city: "City"
openvpn_easyrsa_org: "Organization"
openvpn_easyrsa_email: "admin@example.com"

# Security settings
openvpn_cipher: "AES-256-GCM"
openvpn_auth: "SHA256"
openvpn_tls_auth: true
openvpn_compression: "none"  # Disabled for security

# Connection settings
openvpn_keepalive_ping: 10
openvpn_keepalive_timeout: 120
openvpn_max_clients: 10

# Firewall management
openvpn_manage_firewall: true
openvpn_firewall_type: ufw  # ufw or iptables
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
    password: "REPLACE_ME"
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
bbb_lxc_host_packages:
- lxc-templates
- lxc-utils
- net-tools

# This is the name of LXC profile that should be used for all BBB LXC instances
bbb_lxc_profile: bbb_macvlan

# Mount point for extra LXC storage volume mounted within the container. If empty storage volume will not be created.
bbb_lxc_storage_shared: /opt/bbbshared

# The name of local network used for communication between containers directly. If empty network will not be created.
bbb_lxc_bridged_network: ''

# Default profile storage pool name for directory root.
bbb_lxc_storage_pool_default: default

# Storage pool name used for storage volume for BigBlueButton files
bbb_lxc_storage_pool: bigbluebutton

# Host OS path where LXC storage pool is created. Leave empty and role will not create new storage pool.
bbb_lxc_storage_pool_dir: ''
```        

### BigBlueButton LXC instance (bbb-lxc)
Installs and configures BigBlueButton LXC instances for load balanced usage. Many other features are installed. Check options bellow. 

Available variables:

```yaml
---
# URL path to official BBB bash install script
bbb_lxc_bbb_install_url: 'https://raw.githubusercontent.com/bigbluebutton/bbb-install/refs/heads/v3.0.x-release/bbb-install.sh'
# If set BBB will automatically redirect user to this url for default document root
bbb_lxc_bbb_redirect_url:
# Path of index file for default document root
# For BBB lower than v2.4: bbb_lxc_bbb_index_file: '/var/www/bigbluebutton-default/index.html'
bbb_lxc_bbb_index_file: '/var/www/bigbluebutton-default/assets/index.html'
# Path to BBB properties file
bbb_lxc_bbb_properties_file: '/usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties'
# Path to Freeswitch configuration
bbb_lxc_bbb_freeswitch_config_file: '/opt/freeswitch/etc/freeswitch/vars.xml'
# Target systemd unit directory
bbb_lxc_systemd_unit_dir: '/usr/lib/systemd/system'
# Path to HTML5 systemd unit file
bbb_lxc_bbb_html5unit_file: '{{ bbb_lxc_systemd_unit_dir }}/bbb-html5.service'
# If true container will be configured for local network
bbb_lxc_net_bridged: true
# If true role will force BBB install script even if BBB has already been installed
bbb_lxc_force_bbb_install: false
# Adjust CPU and scheduling policy for systemd units to prevent errors when running in LXC
bbb_systemd_containerize_units: true
# Disable AppArmor for LXC containers (set to true if you encounter AppArmor conflicts)
bbb_lxc_disable_apparmor: false
# Temporary directory to use on host OS for template processing
bbb_lxc_tmp_dir: /tmp
# If true recordings will be processed only out of working hours
bbb_lxc_recording_timer_enabled: false
# Path to recording timer file for systemd scheduling
bbb_lxc_recording_timer_file: /etc/systemd/system/bbb-record-core.timer.d/override.conf
# If true multiple kurentos instances will be configured via BBB install script
bbb_lxc_multiple_kurentos: true
# Optional HTML5 document title to shot in browser
bbb_lxc_html5_title: ''
# Set URL for collecting HTML5 client logs
bbb_lxc_html5_external_debug_url: ''
# Path to BBB shared directory
bbb_lxc_shared_dir: /opt/bbbshared/instances
# Path to playbook local directory where default slides are located
bbb_lxc_local_slides_dir: '{{ playbook_dir }}/../files/bbb'
# Array of default slide files to copy to BBB configuration
bbb_lxc_local_slides:
  - 'default.pptx'
  - 'default.pdf'

# Install Filebeat agent, unless disabled on instance config
bbb_lxc_install_filebeat: true
# Logstash URL that will be used as Filebeat output
bbb_lxc_filebeat_logstash_url:
# Default Filebeat input include_lines pattern
bbb_lxc_filebeat_include_pattern: '(ERR|WARN|error|warn|warning|critical|urgent|fail|exception)'
# Default Filebeat certificates directory
bbb_lxc_filebeat_cert_dir: /etc/filebeat/certs
# Local CA certificate file
# More info on how to setup certs for logstash can be found here (you can use same tutorial for filebeat client certs)
# https://kifarunix.com/easy-way-to-configure-filebeat-logstash-ssl-tls-connection/
bbb_lxc_filebeat_cacert: ''
# Local Certificate file
bbb_lxc_filebeat_clientcert: ''
# Local private key file
bbb_lxc_filebeat_clientkey: ''

# Node exporter docker image version (used for Docker Compose and Git tag for systemd installation)
bbb_lxc_node_exporter_version: v0.7.1

# Install prometheus node exporter, unless disabled on instance config
bbb_lxc_install_node_exporter: true

# Use Docker Compose for node exporter installation instead of systemd units
bbb_lxc_node_exporter_from_docker: false

# BBB node exporter docker directory
bbb_lxc_node_exporter_dir: /opt/bbb_node_exporter

# Systemd installation URLs (used when bbb_lxc_node_exporter_from_docker is false)
# Prometheus Node Exporter binary version and URL
bbb_lxc_node_exporter_binary_version: '1.10.2'
bbb_lxc_node_exporter_binary_url: 'https://github.com/prometheus/node_exporter/releases/download/v{{ bbb_lxc_node_exporter_binary_version }}/node_exporter-{{ bbb_lxc_node_exporter_binary_version }}.linux-amd64.tar.gz'

# BBB Exporter - Python-based installation (uses bbb_lxc_node_exporter_version variable for version/tag)
bbb_lxc_bbb_exporter_git_repo: 'https://github.com/greenstatic/bigbluebutton-exporter.git'
bbb_lxc_bbb_exporter_install_dir: '/opt/bigbluebutton-exporter'
bbb_lxc_bbb_exporter_config_dir: '/etc/bigbluebutton-exporter'
bbb_lxc_bbb_exporter_user: 'bbb-exporter'
bbb_lxc_bbb_exporter_systemd_source: '/opt/bigbluebutton-exporter/extras/systemd'

# Netdata installation script URL
bbb_lxc_netdata_install_url: 'https://get.netdata.cloud/kickstart.sh'

# BBB node exporter nginx config file
bbb_lxc_node_exporter_nginx_config: '{{ bbb_lxc_node_exporter_dir}}/nginx_prometheus_node_exporter.conf'

# Username and password for Prometheus HTTP authentication
bbb_lxc_node_exporter_user: bbb_prometheus
bbb_lxc_node_exporter_pass:

# Limit node_exporter nginx proxy to allow only requests from this ip address
bbb_lxc_node_exporter_ip_address:

# Defines a hostname for turn/turns server
bbb_lxc_turn_server:
# Turn/turns server secret
bbb_lxc_turn_secret:
# Path to BBB stun-turn configuration file
bbb_lxc_turn_config_file: /usr/share/bbb-web/WEB-INF/classes/spring/turn-stun-servers.xml
  
# List of default packages to install on BBB LXC instance
bbb_lxc_default_packages:
  - vim
  - git
  - tree
  - screen
  - htop
  - telnet
  - unattended-upgrades
  - nmap
  - etckeeper
  - net-tools
  - stress
  - bc

# List of LXC instances. See example bellow.
bbb_lxc_instances: []
#  - name: bbbmeet
#    hostname:
#    email:
#    ip_address:
#    network_ip:
#    net_mask:
#    broadcast:
#    install_bbb: false
#    default_route:
#    dns_servers:
#    profile:
#    image:
#    install_node_exporter:
#    node_exporter_from_docker: false  # Override global setting per instance
#    disable_apparmor: false  # Override global setting per instance
```

### BigBlueButton Scalelite (bbb-lxc-scalelite)
Installs and configures Scalelite to a specific LXC container. Each BBB instance can be automatically registered to load balancer and configured for distributed sharing of each BigBlueButton published recordings.

Available variables:

```yaml
---
bbb_scalelite_lxc:
  #  name:
  #  hostname:
  #  email:
  #  recording_poll: true # Enable polling of new recordings
  members: []
  # members:
  #  - hostname: example.com
  #    lxc: lxcname # used if ansible controller has direct access to LXC host to automatically inspect for BBB secret
  #    multiplier: 0.5 # defaults to bbb_scalelite_lxc.default_multiplier
  #    secret: examplehash # refers to BBB API secret

# Select installation method
# - docker_compose: uses https://github.com/tezvi/scalelite-run.git (legacy behavior)
# - systemd: installs official systemd units that run Scalelite Docker containers
bbb_scalelite_install_mode: docker_compose  # docker_compose | systemd

bbb_scalelite_default_multiplier: '1.0'
bbb_scalelite_dir: '/opt/scalelite-run'
bbb_scalelite_git_repo: 'https://github.com/tezvi/scalelite-run.git'
bbb_scalelite_shared: '/opt/bbbshared'
bbb_scalelite_recordings: '{{ bbb_scalelite_shared }}/scalelite-recordings'
bbb_scalelite_recordings_spool: '{{ bbb_scalelite_recordings }}/spool'
bbb_scalelite_spool_gid: 998
bbb_scalelite_tmp_dir: /tmp
bbb_scalelite_recordings_script_url: 'https://raw.githubusercontent.com/blindsidenetworks/scalelite/master/bigbluebutton/scalelite_post_publish.rb'
bbb_scalelite_recordings_prune_script_url: 'https://raw.githubusercontent.com/blindsidenetworks/scalelite/master/bigbluebutton/scalelite_prune_recordings.sh'

# Required when bbb_scalelite_install_mode is "systemd"
# These are written to /etc/default/scalelite inside the Scalelite LXC.
# Provide real values via group_vars/host_vars (do not commit secrets).
bbb_scalelite_database_url: 'postgresql://scalelite:REPLACE_ME@db.example.com/scalelite'
bbb_scalelite_redis_url: 'redis://:REPLACE_ME@redis.example.com:6379/0'

# Docker tag used by units (defaults match bbb_scalelite_docker_image_version)
bbb_scalelite_tag: 'v1.6.12.1'

# Optional tuning
bbb_scalelite_nginx_ssl: true
bbb_scalelite_nginx_behind_proxy: false
bbb_scalelite_poll_interval: 60
bbb_scalelite_nginx_extra_opts: ''
bbb_scalelite_api_extra_opts: ''
bbb_scalelite_poller_extra_opts: ''
bbb_scalelite_recording_importer_extra_opts: ''
```
