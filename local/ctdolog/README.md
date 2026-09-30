# local_ctdolog — Prévia de compartilhamento (Open Graph)

Adiciona `og:title`, `og:description`, `og:image` (+ Twitter Card) ao `<head>` de `/course/info.php?id=<id>`,
usando nome, resumo e **imagem do curso** (Course image) do próprio Moodle.

- **Link para divulgar:** `https://edu.ctdol.com.br/course/info.php?id=<id>` (público, sem login).
  `course/view.php` redireciona ao SSO e não gera prévia.
- Requer o curso visível e imagem definida em Configurações do curso > Descrição > Imagem do curso.
- Não altera autenticação (Keycloak) nem outras páginas. Sem dados pessoais.
- Após o deploy, purgar caches (o `deploy_ci.sh` já faz) — o registro de hooks é cacheado.

Testar: colar o link no depurador de compartilhamento (Facebook Sharing Debugger / LinkedIn Post Inspector)
ou `curl -s <url> | grep -i 'og:'`. Redes sociais guardam a prévia em cache; use o depurador para forçar nova leitura.
