# Imagens e containers

## Imagem × container

- **Imagem:** modelo somente leitura, formado por camadas (*layers*). É o "molde".
- **Container:** instância em execução de uma imagem, com uma camada gravável por cima.

Vários containers podem nascer da mesma imagem.

## Comandos essenciais

```bash
docker pull nginx:1.27          # baixa uma imagem
docker run -d --name web -p 8080:80 nginx:1.27
docker ps                       # containers em execução
docker logs web                 # saída do container
docker exec -it web sh          # abre um shell dentro dele
docker stop web && docker rm web
docker images                   # imagens locais
```

`-d` executa em segundo plano; `-p 8080:80` publica a porta 80 do container na porta 8080 do host.

## Tags

Uma imagem tem nome e **tag** (`nginx:1.27`). Sem tag, o Docker usa `latest`, que **não** significa "a mais segura" nem "fixa" — em produção, prefira versões explícitas.

## Efêmero por padrão

Os dados gravados na camada do container **somem** quando o container é removido. Para persistir, use volumes (Módulo 2).
