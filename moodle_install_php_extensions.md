## Instruções para Terminal Root (WHM)

Como você tem acesso ao terminal do WHM (como root), execute os comandos abaixo na ordem. Eles vão instalar as extensões necessárias para o **PHP 8.3** do cPanel e configurar os limites exigidos pelo Moodle:

```bash
# 1. Instala as extensões obrigatórias
dnf install -y ea-php83-php-iconv ea-php83-php-intl ea-php83-php-fileinfo ea-php83-php-sodium ea-php83-php-zip ea-php83-php-gd ea-php83-php-mbstring

# 2. Configura o max_input_vars em um arquivo separado para não perder em atualizações
echo "max_input_vars = 5000" > /opt/cpanel/ea-php83/root/etc/php.d/z99-moodle.ini

# 3. Reinicia o servidor Apache (padrão cPanel)
/scripts/restartsrv_httpd
```

### Após executar os comandos:
Basta me dar o OK aqui que eu retomo o instalador do Moodle (`admin/cli/install.php`) automaticamente para você.
