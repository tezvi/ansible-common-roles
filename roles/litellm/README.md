# LiteLLM Ansible Role
This role installs and configures LiteLLM with Ollama behind Nginx with SSL termination via Certbot.
## Architecture
```
Moodle
  |
  | HTTPS :443
  v
Nginx (TLS via Certbot)
  |
  | HTTP
  v
LiteLLM (127.0.0.1:4000)
  |
  +--> Ollama (127.0.0.1:11434)
  |
  +--> External APIs (fallback)
```
## Requirements
- Ubuntu 20.04/22.04/24.04
- Ports 80 and 443 accessible from the internet (for SSL certificate)
- DNS record pointing to the server
## Role Variables
### Required Variables
```yaml
litellm_domain: "api.example.com"          # Your API domain
litellm_letsencrypt_email: "ssl@example.com"  # Email for Let's Encrypt
litellm_master_key: "sk-your-master-key"   # API key for authentication
```
## Optional Variables
See `defaults/main.yml` for all available variables.

### Large Data Directories (For Separate Disk Storage)

**⚠️ See [DATA_DIRECTORIES.md](DATA_DIRECTORIES.md) for comprehensive guide**

Configure these to store large model files on separate disk devices:

```yaml
# Ollama models directory (can grow to 100GB+)
ollama_models_dir: "/data/ollama/models"      # null = use default

# LiteLLM data directory (for future expansion)
litellm_data_dir: "/data/litellm"             # null = skip creation

# LiteLLM cache directory
litellm_cache_dir: "/data/litellm/cache"      # null = skip creation

# Use symlinks (recommended) or environment override
litellm_use_symlinks: true

# Verify directories are on separate mount
litellm_verify_data_disk_mount: false
```

**Quick Start:**
- Single disk? → Leave all as `null` (default behavior)
- Separate data disk? → Set `ollama_models_dir` to mount point
- Multiple disks? → Set each directory separately
- Want symlinks? → Set `litellm_use_symlinks: true`

#### Ollama Settings
```yaml
ollama_enabled: true
ollama_models:
  - "llama3.1:8b"
ollama_num_threads: 48        # CPU threads for Ollama
ollama_numa_enabled: true     # NUMA optimization
```
#### LiteLLM Settings
```yaml
litellm_primary_model_name: "gpt-4"
litellm_primary_ollama_model: "ollama/llama3.1:8b"
litellm_request_timeout: 600
```
#### Fallback Configuration
```yaml
litellm_fallback_enabled: true
litellm_fallback_model_name: "gpt-4-fallback"
litellm_fallback_provider: "openai"
litellm_fallback_api_key: "sk-..."
```
#### Security Settings
```yaml
nginx_rate_limit_enabled: true
nginx_rate_limit_requests: "10r/s"
nginx_allowed_ips:
  - "192.168.1.0/24"
litellm_configure_firewall: true
```
## Example Playbook
```yaml
---
- hosts: llm_servers
  become: yes
  roles:
    - role: litellm
      vars:
        litellm_domain: "api.myschool.edu"
        litellm_letsencrypt_email: "admin@myschool.edu"
        litellm_master_key: "sk-myschool-secret-key-12345"
        ollama_models:
          - "llama3.1:8b"
        ollama_num_threads: 32
```
## Moodle Integration
Configure Moodle to use the API:
1. Set API URL: `https://api.myschool.edu/v1/chat/completions`
2. Set API Key: Your `litellm_master_key` value
3. Select model: `gpt-4` (or your `litellm_primary_model_name`)
## API Endpoints
- `GET /health` - Health check
- `GET /v1/models` - List available models
- `POST /v1/chat/completions` - Chat completions (OpenAI-compatible)
## Testing
```bash
# Test health endpoint
curl https://api.example.com/health
# Test models endpoint
curl -H "Authorization: Bearer sk-your-master-key" \
  https://api.example.com/v1/models
# Test chat completion
curl -X POST https://api.example.com/v1/chat/completions \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```
## Tags
- `litellm` - All tasks
- `litellm-base` - Base package installation
- `litellm-data-dirs` - Data directory management (models, cache)
- `litellm-ollama` - Ollama installation and configuration
- `litellm-install` - LiteLLM installation
- `litellm-config` - LiteLLM configuration
- `litellm-nginx` - Nginx installation
- `litellm-ssl` - SSL certificate setup
- `litellm-firewall` - Firewall configuration
## License
MIT
## Author
Your Name
