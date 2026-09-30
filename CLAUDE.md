# 🟣 Diretrizes de Governança e Operação: Moodle LMS CTDOL

> [!tldr] Resumo Executivo
> - **Alvo:** Moodle LMS CTDOL (`https://edu.ctdol.com.br`)
> - **Infraestrutura:** VPS HostGator (`162.240.177.16`), conta cPanel `ctdolc07`
> - **Autenticação:** Provedor de Identidade Corporativo Keycloak (Realm `moodle`, OIDC `auth_oauth2`)
> - **Metodologia de Cursos:** Docs-as-Code (Markdown + Aiken `.txt` versionados em `courses/`)
> - **Precedência:** As regras de segurança e integridade deste arquivo são mandatórias e invioláveis.

---

## 0. Limites Inegociáveis & Regras de Ouro
1. **SSO Keycloak Sagrado:** NUNCA alterar, desativar ou reverter o plugin `auth_oauth2` ou o realm `moodle`. O botão *"Entrar com Conta CTDOL"* em `https://edu.ctdol.com.br/login/index.php` deve permanecer 100% ativo.
2. **Zero Destruição (.mbz Proibido):** NUNCA use backups binários `.mbz` com restore destrutivo sobre cursos existentes. Cursos em produção recebem apenas atualizações aditivas de aulas; questionários com notas ou tentativas de alunos jamais são sobrescritos.
3. **Proteção cPanel:** NUNCA edite `httpd.conf` ou `apache2.conf`. NUNCA use `systemctl restart apache2` (reload apenas pelo root com `/scripts/restartsrv_httpd`).
4. **Isolamento ctdolc07:** A conta hospeda múltiplos subdomínios da CTDOL. NÃO altere nada fora de `~/edu.ctdol.com.br`, `~/moodledata`, `~/infra-educacao`, `~/backups/moodle` e `~/logs`.
5. **Zero Leakage:** NUNCA commitar senhas, `config.php`, `.env` ou dumps SQL no Git.

---

## 🛠️ Comandos de Operação na VPS
- **Executar Cron:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php`
- **Limpar Cache:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/purge_caches.php`
- **Modo Manutenção:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/maintenance.php --enable` (ou `--disable`)
- **Status do Sistema:** `bash /home/ctdolc07/infra-educacao/scripts/status_moodle.sh`
- **Backup Manual:** `bash /home/ctdolc07/infra-educacao/scripts/backup_moodle.sh`

---

## 🔐 Procedimento de Emergência (Break-Glass do SSO)
Se o Keycloak estiver indisponível e o administrador precisar acessar via senha local de emergência:
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=manual,oauth2
```
*Após restabelecer o Keycloak, reverter imediatamente para o padrão Zero Trust:*
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=oauth2
```

---

## 🎓 Protocolo Canônico de Publicação de Cursos Docs-as-Code

Quando acionado para **criar**, **atualizar** ou **publicar** um curso no Moodle (ex: *"Claude, publique o curso X"* ou *"atualize as aulas do curso Y"*), execute rigorosamente o seguinte roteiro:

### 1. Topologia Obrigatória (`courses/<shortname>/`)
```text
courses/
└── <shortname>/
    ├── course.json                 # Manifesto declarativo do curso (Schema v1)
    ├── cover.jpg                   # Imagem do card de capa (16:9, paleta CTDOL)
    ├── lessons/                    # Aulas estruturadas em Markdown (.md)
    │   ├── 01-nome-da-aula.md
    │   ├── 02-nome-da-aula.md
    │   └── ...
    └── quiz/                       # Avaliação objetiva no Formato Aiken (.txt)
        └── <shortname>_moodle_aiken.txt
```

### 2. Especificação do Manifesto (`course.json`)
```json
{
  "schema": 1,
  "shortname": "containers-docker",
  "idnumber": "CTDOL-DEV-001",
  "fullname": "Engenharia de Contêineres com Docker (Do Desenvolvimento à Produção)",
  "category": "CTDOL Dev / Formação Técnica",
  "summary": "Resumo curricular claro do curso para exibição no card da página inicial.",
  "image": "cover.jpg",
  "format": "topics",
  "visible": 1,
  "sections": [
    {
      "name": "Módulo 1 — Fundamentos e Kernel Linux",
      "lessons": [
        { "title": "Aula 01: Fundamentos, Namespaces e Cgroups", "file": "lessons/01-fundamentos-namespaces-cgroups.md" }
      ]
    },
    {
      "name": "Avaliação de Certificação",
      "quizzes": [
        {
          "name": "Avaliação: Containers com Docker",
          "file": "quiz/containers_docker_moodle_aiken.txt",
          "grade": 10,
          "attempts": 3
        }
      ]
    }
  ]
}
```
> [!IMPORTANT]
> - `visible`: Deve ser `1` para aparecer na página inicial do Moodle.
> - `category`: Se a categoria iniciar com `_` (ex: `_HOMOLOGACAO_SANDBOX`), o Moodle cria com `visible = 0` (oculta). Para cursos públicos, use categorias limpas sem prefixo `_`.

### 3. Padrão das Aulas (`lessons/*.md`)
- Sem frontmatter YAML (remover delimitadores `---`).
- Sem wikilinks Obsidian (converter `[[Nota|Texto]]` para `Texto` puro).
- URLs de imagens devem ser absolutas HTTPS (zero binários no Git).

### 4. Padrão do Banco de Avaliação Aiken (`quiz/*.txt`)
```text
Qual e a primitiva do kernel Linux responsavel por limitar memoria RAM de um conteiner?
A. Namespaces
B. Control Groups (Cgroups)
C. Union File System
D. Hypervisor KVM
ANSWER: B
```
- Alternativas em maiúsculas seguidas de ponto e espaço (`A. `, `B. `, etc.).
- Gabarito exatamente no formato `ANSWER: X`.
- Linha em branco obrigatória entre cada questão.

### 5. Validação Local Estática (Shift-Left)
**Mandatório antes de qualquer commit:**
```bash
python3 scripts/validar_cursos.py
```
- Corrija qualquer erro apontado pelo validador. O pipeline do CI/CD bloqueará o build se houver falhas.

### 6. Git Commit & Push
```bash
git add courses/<shortname>/
git commit -m "feat(cursos): adicionar curso <shortname> (<fullname>)"
git push origin main
```

### 7. Deploy & Provisionamento na VPS
Conecte-se via SSH (`ssh vps-ctdol`) e execute:
```bash
# 1. Puxar as novidades do Git
cd ~/infra-educacao && git pull origin main

# 2. Dry-run preventivo (simulação)
/usr/local/bin/ea-php83 scripts/provisionar_cursos.php

# 3. Aplicar o provisionamento do curso
/usr/local/bin/ea-php83 scripts/provisionar_cursos.php --apply --course=<shortname>

# 4. Purgar caches do Moodle
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/purge_caches.php
```

### 8. Checklist de Homologação Pós-Deploy
1. Acessar `https://edu.ctdol.com.br/?redirect=0` e confirmar que o card do curso está visível na vitrine pública.
2. Acessar `https://edu.ctdol.com.br/course/view.php?id=<id>` e validar que as páginas e o questionário foram criados com sucesso.
3. Emitir relatório final ao operador com link direto do curso.
