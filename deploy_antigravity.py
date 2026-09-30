#!/usr/bin/env python3
"""Deploy/sincronizacao do repositorio de infraestrutura do Moodle CTDOL na VPS.

Faz `git pull --ff-only`, garante permissao de execucao dos scripts e (opcional)
purga caches do Moodle. NAO reinicia o Apache por padrao.

Uso: python3 deploy_antigravity.py [--purge-cache] [--reload-apache]
"""
import os
import subprocess
import sys

REPO_PATH = os.environ.get("REPO_PATH", "/home/ctdolc07/infra-educacao")
PHP_BIN = "/usr/local/bin/ea-php83"
MOODLE_DIR = "/home/ctdolc07/edu.ctdol.com.br"


def run(cmd):
    print("[*] " + " ".join(cmd))
    subprocess.run(cmd, check=True)


def main():
    args = set(sys.argv[1:])
    try:
        os.chdir(REPO_PATH)
        run(["git", "pull", "--ff-only"])
        for nome in sorted(os.listdir("scripts")):
            if nome.endswith(".sh"):
                os.chmod(os.path.join("scripts", nome), 0o755)
        if "--purge-cache" in args:
            run([PHP_BIN, f"{MOODLE_DIR}/admin/cli/purge_caches.php"])
        if "--reload-apache" in args:
            run(["/scripts/restartsrv_httpd"])  # somente root; nunca systemctl
        print("[+] Sincronizacao concluida.")
    except subprocess.CalledProcessError as e:
        print(f"[!] Falha: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
