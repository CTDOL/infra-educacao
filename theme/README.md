# theme/ — Temas institucionais CTDOL (Padrão BM / DTIC)

## `theme/ctdol` — tema filho do Boost (Moodle 4.5)
- **Tokens (SCSS `scss/pre.scss`):** Azul Profundo `#0B2545`, Dourado `#C59B27`; neutros de apoio `#F4F4F1` (fundo) e `#555347` (texto secundário).
- **Acessibilidade WCAG 2.1 AA:** branco sobre azul 15,4:1; azul sobre dourado 5,9:1. **Branco sobre dourado reprova (2,6:1):** o dourado é só acento, com texto azul.
- **Não sobrescreve layouts de login**: o botão "Entrar com Conta CTDOL" (Keycloak SSO) é o do core e não pode ser oculto ou alterado.
- Deploy: `scripts/deploy_ci.sh` sincroniza `theme/ctdol` para `~/edu.ctdol.com.br/theme/ctdol/` e roda `upgrade.php` + `purge_caches.php`. Depois, ativar em Administração > Aparência > Temas.
