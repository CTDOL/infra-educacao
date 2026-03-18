# 🎓 Infraestrutura de Educação CTDOL (Moodle + ERPNext)

Bem-vindo ao repositório central de infraestrutura do projeto de capacitação da CTDOL. Este repositório contém as configurações e os scripts de automação para a implantação e o gerenciamento do ambiente educacional e administrativo na nossa VPS.

## 🔗 Links de Acesso
* **Plataforma de Ensino (Moodle):** [https://edu.ctdol.com.br/](https://edu.ctdol.com.br/)
* **Sistema de Gestão (ERPNext):** [https://erp.ctdol.com.br/](https://erp.ctdol.com.br/)

## 🏗️ Arquitetura do Sistema
Para garantir a estabilidade da VPS (gerenciada pelo cPanel/WHM) e evitar conflitos de dependências, utilizamos uma arquitetura híbrida, robusta e isolada:

* **Moodle (Nativo):** Executado diretamente no servidor Apache/PHP gerenciado pelo cPanel.
* **ERPNext (Dockerizado):** Executado em contêineres Docker isolados (porta local `8080`), utilizando o Apache do cPanel como *Reverse Proxy* silencioso através de regras de reescrita no `.htaccess`.
* **CDN e DNS (Cloudflare):** Atua como camada de segurança e cache (Nuvem Laranja ativada), com suporte SSL para garantir conexões seguras em todos os subdomínios.

## 📂 Estrutura de Arquivos
* `docker-compose.yml`: Define a infraestrutura do ERPNext. Inclui um banco de dados MariaDB isolado, instâncias de cache (Redis) e a aplicação Frappe. Foi desenhado para **não** entrar em conflito com o MySQL nativo do cPanel.
* `deploy_antigravity.py`: Nosso script de automação de *deploy* (Módulo Antigravity). Escrito em Python, ele garante que as atualizações dos contêineres e o recarregamento do Apache sejam feitos de forma segura e padronizada.

## 🚀 Como Executar uma Atualização (Módulo Antigravity)
Sempre que houver alterações no repositório, acesse a VPS via SSH e execute o Módulo Antigravity para atualizar o ambiente.

1. Acesse a VPS através do terminal (usando a sua chave SSH):
   ```bash
   ssh ctdolc07@vps-14409668
Navegue até o diretório privado do projeto:

Bash
cd ~/infra-educacao
Execute o script de deploy:

Bash
python3 deploy_antigravity.py
O script irá recriar automaticamente os contêineres Docker necessários (se houver alterações) e reiniciar os serviços do Apache usando as ferramentas nativas e seguras do WHM.

🛡️ Segurança e Boas Práticas
Isolamento do Código: Todo este código de infraestrutura está confinado na raiz do usuário (/home/ctdolc07/infra-educacao), fora do diretório público da web (public_html). Nenhuma destas configurações está exposta à internet.

Isolamento de Rede: O ERPNext expõe os seus serviços apenas para o localhost (127.0.0.1). Todo o tráfego externo precisa, obrigatoriamente, passar pelos filtros do Apache e da Cloudflare.

Repositório mantido pela equipe técnica da CTDOL.
