# OpenVPN Ansible Role

This role automates the installation and configuration of OpenVPN server on Ubuntu with support for NAT alias subnet translation to resolve subnet conflicts.

## Features

- ✅ Automated OpenVPN server installation on Ubuntu
- ✅ Easy-RSA PKI certificate management
- ✅ **NAT Alias Support** - Access remote LAN via different subnet (no conflicts!)
- ✅ Split-tunnel routing configuration
- ✅ UFW and iptables firewall support
- ✅ Certificate-based authentication
- ✅ Secure defaults (AES-256-GCM, SHA256)

## Use Case: Subnet Conflict Resolution

**Problem:** Your local network and the remote LAN both use `192.168.0.0/24`.

**Solution:** Enable NAT alias to access the remote LAN via a different subnet!

### How NAT Alias Works

```
Your Computer                    VPN Server                Remote LAN
─────────────────────────────────────────────────────────────────────
Access: 10.127.0.50      →      NAT translates      →     192.168.0.50
        (alias)                  10.127.0.x to              (actual IP)
                                 192.168.0.x

Benefits:
✅ Access remote 192.168.0.x servers via 10.127.0.x
✅ Local 192.168.0.x network still accessible
✅ No need to disconnect VPN
✅ No routing conflicts!
```

## Quick Start

### 1. Add to Inventory

```ini
# inventory/hosts.ini
[openvpn_servers]
vpn.example.com ansible_user=ubuntu
```

### 2. Configure Variables

Create `inventory/group_vars/openvpn_servers.yml`:

```yaml
# Enable NAT alias for subnet conflict resolution
openvpn_use_nat_alias: true
openvpn_nat_alias_network: "10.127.0.0"      # Access remote LAN via this subnet
openvpn_nat_alias_netmask: "255.255.255.0"
openvpn_remote_lan_network: "192.168.0.0"    # Actual remote LAN subnet

# VPN tunnel settings
openvpn_server_network: "10.8.0.0"
openvpn_server_netmask: "255.255.255.0"

# PKI settings
openvpn_easyrsa_org: "MyOrg"
openvpn_easyrsa_email: "admin@example.com"
```

### 3. Run Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/openvpn_server.yml
```

### 4. Generate Client Certificates

After server deployment, generate client certificates:

```bash
# SSH to the server
ssh ubuntu@vpn.example.com

# Generate client cert
cd ~/openvpn-ca
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Download certificates to your local machine
# - ~/openvpn-ca/pki/ca.crt
# - ~/openvpn-ca/pki/issued/client1.crt
# - ~/openvpn-ca/pki/private/client1.key
# - ~/openvpn-ca/pki/ta.key
```

### 5. Client Configuration

Create `/etc/openvpn/client/client.conf`:

```
client
dev tun
proto tcp
remote vpn.example.com 1194
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
ca ca.crt
cert client1.crt
key client1.key
tls-auth ta.key 1
key-direction 1
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
compress lz4-v2
verb 3

# Route alias subnet through VPN
# This will be translated to 192.168.0.x on server
route 10.127.0.0 255.255.255.0 vpn_gateway
```

### 6. Connect and Use

```bash
# Connect to VPN
sudo systemctl start openvpn-client@client

# Access remote server at 192.168.0.50 using alias IP
ssh user@10.127.0.50

# Access remote web server at 192.168.0.100
curl http://10.127.0.100

# Your local 192.168.0.x network still works!
ping 192.168.0.1
```

## Role Variables

### Required Variables

None - role works with defaults, but you should customize these:

### Important Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_use_nat_alias` | `false` | Enable NAT alias for subnet conflict resolution |
| `openvpn_nat_alias_network` | `10.127.0.0` | Alias subnet for accessing remote LAN |
| `openvpn_remote_lan_network` | `192.168.0.0` | Actual remote LAN subnet |
| `openvpn_server_network` | `10.8.0.0` | VPN tunnel subnet |
| `openvpn_server_port` | `1194` | OpenVPN listening port |
| `openvpn_server_protocol` | `udp` | Protocol (udp/tcp) |
| `openvpn_server_listen` | `""` | Listen address (empty = all interfaces, `127.0.0.1` for localhost) |

### Network Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_server_netmask` | `255.255.255.0` | VPN tunnel netmask |
| `openvpn_nat_alias_netmask` | `255.255.255.0` | Alias subnet netmask |
| `openvpn_push_routes` | `["192.168.0.0 255.255.255.0"]` | Routes to push to clients |
| `openvpn_enable_ip_forward` | `true` | Enable IP forwarding |

### Security Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_cipher` | `AES-256-GCM` | Encryption cipher |
| `openvpn_auth` | `SHA256` | HMAC authentication algorithm |
| `openvpn_tls_auth` | `true` | Enable TLS authentication |
| `openvpn_compression` | `lz4-v2` | Compression algorithm |

### PKI Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_easyrsa_country` | `US` | Certificate country |
| `openvpn_easyrsa_province` | `State` | Certificate state/province |
| `openvpn_easyrsa_city` | `City` | Certificate city |
| `openvpn_easyrsa_org` | `Organization` | Certificate organization |
| `openvpn_easyrsa_email` | `admin@example.com` | Certificate email |

### Firewall Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_manage_firewall` | `true` | Manage firewall rules |
| `openvpn_firewall_type` | `ufw` | Firewall type (ufw/iptables) |

### Other Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openvpn_max_clients` | `10` | Maximum concurrent clients |
| `openvpn_client_to_client` | `false` | Allow client-to-client communication |
| `openvpn_log_verbosity` | `3` | Logging verbosity (0-11) |

## Configuration Examples

### Example 1: NAT Alias (Recommended for Subnet Conflicts)

```yaml
# Both local and remote networks use 192.168.0.0/24
openvpn_use_nat_alias: true
openvpn_nat_alias_network: "10.127.0.0"
openvpn_remote_lan_network: "192.168.0.0"
openvpn_push_routes: []  # Leave empty, NAT alias handles routing
```

**Client accesses remote servers via:** `10.127.0.x` → translated to `192.168.0.x`

### Example 2: Simple Split-Tunnel (No Subnet Conflict)

```yaml
# Remote LAN uses different subnet than local network
openvpn_use_nat_alias: false
openvpn_push_routes:
  - "10.0.0.0 255.255.0.0"  # Route to remote LAN
```

**Client accesses remote servers via:** `10.0.0.x` (direct routing)

### Example 3: Multiple Remote Networks

```yaml
openvpn_use_nat_alias: false
openvpn_push_routes:
  - "192.168.1.0 255.255.255.0"
  - "192.168.2.0 255.255.255.0"
  - "10.0.0.0 255.255.0.0"
```

## Directory Structure

```
roles/openvpn/
├── defaults/
│   ├── main.yml                    # Default variables
│   └── example-group-vars.yml      # Example configuration
├── handlers/
│   └── main.yml                    # Service handlers
├── tasks/
│   ├── main.yml                    # Main tasks
│   ├── firewall-ufw.yml           # UFW firewall configuration
│   ├── firewall-iptables.yml      # iptables configuration
│   └── nat-alias.yml              # NAT alias translation setup
└── templates/
    ├── server.conf.j2             # OpenVPN server config
    └── easyrsa-vars.j2            # Easy-RSA variables
```

## Troubleshooting

### NAT Alias Not Working

Check iptables NAT rules on server:

```bash
sudo iptables -t nat -L -n -v
```

Should show NETMAP rule:
```
Chain PREROUTING (policy ACCEPT)
NETMAP  all  --  *  *  10.8.0.0/24  10.127.0.0/24  to:192.168.0.0/24
```

### Cannot Access Remote LAN

1. Verify server can access remote LAN:
   ```bash
   ping 192.168.0.1  # From VPN server
   ```

2. Check IP forwarding is enabled:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # Should output: 1
   ```

3. Verify routing on client:
   ```bash
   ip route show
   # Should include: 10.127.0.0/24 via 10.8.0.1 dev tun0
   ```

### Firewall Blocking Traffic

Check UFW status:
```bash
sudo ufw status verbose
```

Ensure port 1194/udp is allowed.

## Dependencies

- Ubuntu 20.04 LTS or newer
- Ansible 2.9+

## License

Same as parent project

## Author

Generated for ansible-common-roles project

