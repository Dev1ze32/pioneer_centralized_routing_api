import socket
import os
import re

def get_local_ip():
    """Get the primary local IP address of the machine on the network."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connect to a dummy external IP. It doesn't need to be reachable, 
        # it just forces the OS to figure out the primary network interface.
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def update_env_ip():
    """Reads the .env file, updates the SERVER_IP, and writes it back."""
    # The script is in scripts/, so .env is one directory up
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env_path = os.path.join(project_dir, '.env')
    
    if not os.path.exists(env_path):
        return

    current_ip = get_local_ip()
    
    with open(env_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Check if SERVER_IP already exists
    if re.search(r'^SERVER_IP=.*$', content, flags=re.MULTILINE):
        new_content = re.sub(r'^SERVER_IP=.*$', f'SERVER_IP={current_ip}', content, flags=re.MULTILINE)
    else:
        # Append it if it doesn't exist
        new_content = content.rstrip() + f'\n\n# ── Auto-Updated Server IP ────────────────────────────────────\nSERVER_IP={current_ip}\n'
        
    # Only write back if there was an actual change
    if new_content != content:
        with open(env_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Detected IP change! Updated .env with SERVER_IP={current_ip}")

if __name__ == '__main__':
    update_env_ip()
