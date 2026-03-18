#!/usr/bin/env python3
import os
import subprocess

# === CONFIGURAÇÃO ===
REPO_PATH = "/home/ctdolc07/infra-educacao"
# ====================

def voar_deploy():
    print("🚀 Iniciando sequência Antigravity (Deploy seguro para cPanel)...")
    
    try:
        os.chdir(REPO_PATH)
        
        print("[*] Subindo os contêineres do ERPNext...")
        subprocess.run(["docker-compose", "up", "-d"], check=True)
        print("[+] ERPNext em órbita na porta 8080 (Isolado).")
        
        print("[*] Reiniciando Apache via cPanel...")
        subprocess.run(["/scripts/restartsrv_httpd"], check=True)
        print("[+] Apache reiniciado de forma segura.")
        
        print("\n✅ Implantação concluída! O ambiente está flutuando perfeitamente.")
        
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Falha na gravidade! Erro de execução: {e}")
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")

if __name__ == "__main__":
    voar_deploy()
