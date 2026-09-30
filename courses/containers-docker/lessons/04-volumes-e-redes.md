# Volumes e redes

## Volumes: persistindo dados

```bash
docker volume create dados-db
docker run -d --name db -v dados-db:/var/lib/postgresql/data postgres:16
```

O volume vive fora do ciclo de vida do container: remover o container **não** apaga os dados do volume.

Também existe o *bind mount*, que liga uma pasta do host ao container (`-v $(pwd):/app`), útil em desenvolvimento.

## Redes

Containers na **mesma rede definida pelo usuário** se encontram pelo **nome**:

```bash
docker network create app-net
docker run -d --name db --network app-net postgres:16
docker run -d --name api --network app-net minha-app:1.0
# dentro de "api", o banco responde em db:5432
```

## Publicar portas com cuidado

`-p 8080:80` expõe a porta em **todas** as interfaces do host. Para deixar acessível só localmente, use `-p 127.0.0.1:8080:80`.

## Docker Compose (visão geral)

O Compose descreve vários containers, volumes e redes em um arquivo `compose.yaml`, e sobe tudo com `docker compose up -d`.
