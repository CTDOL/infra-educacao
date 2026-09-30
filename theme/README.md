# theme/ — Tema oficial CTDOL (Padrao BM / DTIC)

Guia de engenharia para o tema institucional. Ainda nao ha tema versionado; este diretorio recebe o codigo.

## Principios
- **Filho do Boost**: `$THEME->parents = ['boost'];` — nunca editar `theme/boost` do core (sobrescrito em upgrades).
- Nome do componente: `theme_ctdol` (pasta `theme/ctdol` no Moodle).
- Seguir identidade visual **Padrao BM / DTIC** (paleta, tipografia, logotipos) do manual vigente; tokens em variaveis SCSS.
- **Nao alterar a tela de login/fluxo SSO**: o botao "Entrar com Conta CTDOL" (auth_oauth2/Keycloak) deve permanecer visivel e funcional. Personalize apenas estilo (SCSS), nunca remova o bloco de login por IdP.

## Estrutura minima
```
theme/ctdol/
  version.php  lib.php  config.php
  lang/pt_br/theme_ctdol.php  lang/en/theme_ctdol.php
  scss/pre.scss  scss/post.scss
  pix/ (logo, favicon)  templates/  settings.php
```

## Fluxo de desenvolvimento
1. Desenvolver aqui; deploy copiando/sincronizando para `/home/ctdolc07/edu.ctdol.com.br/theme/ctdol/` (ver README raiz).
2. `admin/cli/upgrade.php` (com `maintenance.php --enable` antes) e `scripts/limpar_cache.sh`.
3. Validar contraste WCAG AA, responsividade e o login SSO em https://edu.ctdol.com.br/login/index.php.
4. Nao commitar binarios grandes nem segredos.
