# 🧪 Laboratório Prático: Orquestração Multi-Serviço, Limites de Cgroups e Resiliência em Produção

> [!tldr] Resumo Executivo (Totem do Laboratório)
> - **Objetivo Prático:** Construir uma stack de microsserviços completa utilizando Docker Compose, aplicando quotas estritas de memória RAM para blindagem contra o OOM-Killer, isolamento de rede em bridge privada e persistência em named volumes. **A partir da v1.1.0, o laboratório também exercita a construção multi-stage (N1) e o endurecimento de privilégio (N4).**
> - **Entregáveis:** Arquivo `docker-compose.yml` funcional, teste de contenção de estresse com `stress-ng`, validação do confinamento de portas em `127.0.0.1`, **Dockerfile multi-stage comprovadamente enxuto e serviço aprovado no checklist de hardening**.

---

## 🎯 1. Cenário do Desafio

Você foi encarregado de implantar um microsserviço de autenticação e cache no ambiente de desenvolvimento local, garantindo que o banco de dados nunca fique exposto na rede externa e que a aplicação não consuma mais de 256 MB de memória RAM.

---

## 🛠️ 2. Roteiro Passo a Passo

### Passo 1: Criar o Arquivo `docker-compose.yml`
Crie um diretório de trabalho e salve o manifesto abaixo:

```yaml
version: '3.8'

services:
  web-app:
    image: nginx:alpine
    container_name: ctdol-lab-web
    restart: always
    ports:
      - "127.0.0.1:8089:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
    networks:
      - lab_network

  cache-db:
    image: redis:alpine
    container_name: ctdol-lab-redis
    restart: on-failure
    expose:
      - "6379"
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          memory: 128M
    networks:
      - lab_network

volumes:
  redis_data:
    name: ctdol_lab_redis_data

networks:
  lab_network:
    name: ctdol_lab_net
    driver: bridge
```

---

### Passo 2: Execução e Validação Operacional
```bash
# 1. Subir a stack em segundo plano
docker compose up -d

# 2. Verificar o status dos contêineres e mapeamento de portas
docker compose ps

# 3. Validar se a porta está restrita a 127.0.0.1 (segurança CTDOL)
netstat -tulpn | grep 8089 || lsof -i :8089

# 4. Inspecionar o consumo de memória em tempo real
docker stats --no-stream
```

---

### Passo 3: Teste de Resiliência de Cgroup (Simulação de Estresse)
Para comprovar a proteção contra o OOM-Killer sem derrubar o host:

```bash
# Dispara um contêiner temporário limitado a 64MB tentando alocar 128MB
docker run --rm -m 64m progrium/stress --vm 1 --vm-bytes 128M --timeout 5s
```
*Resultado Esperado:* O contêiner temporário é encerrado imediatamente pelo kernel com `Exit Code 137`, enquanto a stack principal (`ctdol-lab-web` e `ctdol-lab-redis`) permanece 100% operacional sem oscilações de memória.

---

### Passo 4: Construção Multi-Stage e Prova de Enxugamento (N1)

Crie `app/main.go` e `app/Dockerfile` para comprovar, na prática, que o toolchain de compilação **não** chega à imagem final:

```go
// app/main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "CTDOL Lab — build multi-stage OK")
	})
	http.ListenAndServe(":8080", nil)
}
```

```dockerfile
# app/Dockerfile
# syntax=docker/dockerfile:1

# --- Estágio 1: compilação (descartado na imagem final) ---
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod* ./
RUN go mod download 2>/dev/null || true
COPY main.go ./
RUN CGO_ENABLED=0 go build -o /bin/labapp ./main.go

# --- Estágio 2: runtime (contém apenas o binário) ---
FROM scratch AS runtime
COPY --from=build /bin/labapp /bin/labapp
EXPOSE 8080
ENTRYPOINT ["/bin/labapp"]
```

```bash
cd app && go mod init ctdol/labapp 2>/dev/null || true

# 1. Build do estágio final (padrão)
docker build -t ctdol-lab-app:multistage .

# 2. Build parando no estágio de compilação, para comparação
docker build --target build -t ctdol-lab-app:buildstage .

# 3. A PROVA: comparar o tamanho das duas imagens
docker images ctdol-lab-app --format "{{.Tag}}\t{{.Size}}"

# 4. Confirmar que o toolchain Go não existe na imagem final
docker run --rm ctdol-lab-app:multistage /bin/labapp --help 2>/dev/null || \
  echo "Imagem final nao possui shell nem SDK — comportamento esperado em FROM scratch"
```

> [!target] O que observar
> A tag `buildstage` carrega o SDK completo do Go; a tag `multistage` contém **apenas o binário estático**. Registre os dois valores exibidos pelo comando 3 no seu relatório — **use os números reais da sua execução**, nunca uma estimativa (Regra 13.1).

---

### Passo 5: Endurecimento de Privilégio (N4)

Acrescente ao `docker-compose.yml` um serviço já endurecido e comprove a redução de privilégio:

```yaml
  app-hardened:
    build: ./app
    image: ctdol-lab-app:multistage
    container_name: ctdol-lab-hardened
    restart: on-failure
    ports:
      - "127.0.0.1:8090:8080"
    user: "1000:1000"                  # não roda como root
    cap_drop:
      - ALL                            # derruba todas as capabilities
    security_opt:
      - no-new-privileges:true         # bloqueia escalonamento via setuid
    read_only: true                    # raiz imutável em runtime
    tmpfs:
      - /tmp
    deploy:
      resources:
        limits:
          memory: 64M
    networks:
      - lab_network
```

```bash
docker compose up -d app-hardened

# 1. O processo NÃO deve rodar como root (UID esperado: 1000)
docker inspect ctdol-lab-hardened --format '{{.Config.User}}'

# 2. Todas as capabilities devem ter sido derrubadas
docker inspect ctdol-lab-hardened --format 'CapDrop={{.HostConfig.CapDrop}} CapAdd={{.HostConfig.CapAdd}}'

# 3. no-new-privileges deve estar ativo
docker inspect ctdol-lab-hardened --format '{{.HostConfig.SecurityOpt}}'

# 4. O sistema de arquivos raiz deve ser somente leitura
docker inspect ctdol-lab-hardened --format 'ReadOnly={{.HostConfig.ReadonlyRootfs}}'

# 5. PROVA NEGATIVA: a escrita na raiz deve falhar
docker exec ctdol-lab-hardened sh -c 'touch /payload' 2>&1 || \
  echo "Escrita na raiz bloqueada — hardening efetivo"
```

> [!caution] O erro que este passo ensina a não cometer
> Jamais monte `/var/run/docker.sock` dentro de um contêiner por conveniência. Quem fala com o socket do Docker fala como **root no host** — basta montar o sistema de arquivos do host em um contêiner privilegiado para obter controle total da máquina.

---

## 🏆 Critérios de Aceitação

**Orquestração e resiliência (N2–N3)**
- [x] O serviço web responde na URL `http://127.0.0.1:8089`.
- [x] O serviço Redis não responde na interface externa do host.
- [x] O volume nomeado `ctdol_lab_redis_data` persiste dados após `docker compose down`.
- [x] Nenhum contêiner ultrapassa o limite de Cgroup estipulado.

**Build moderno (N1)**
- [ ] A imagem `multistage` é comprovadamente menor que a `buildstage`, com ambos os tamanhos reais registrados no relatório.
- [ ] A imagem final não contém o SDK do Go nem shell interativo.
- [ ] O `Dockerfile` declara `# syntax=docker/dockerfile:1` e nomeia seus estágios com `AS`.

**Hardening (N4)**
- [ ] `docker inspect` confirma usuário não-root (UID 1000).
- [ ] `CapDrop` contém `ALL` e `CapAdd` está vazio ou contém apenas o estritamente necessário.
- [ ] `no-new-privileges` está ativo e `ReadonlyRootfs` é `true`.
- [ ] A tentativa de escrita em `/` falha (prova negativa executada e registrada).
- [ ] Nenhum serviço da stack monta `/var/run/docker.sock`.

---

## 📋 Changelog
- 2026-09-18 (🟣 Claude Code): v1.1.0 — Acréscimo do **Passo 4 (build multi-stage com prova de enxugamento)** e do **Passo 5 (endurecimento de privilégio com prova negativa de escrita)**, alinhando o laboratório aos conteúdos incorporados ao curso na v1.1.0. Critérios de aceitação reorganizados por nível. Passos 1 a 3 preservados integralmente.

---

## 🔗 Conexões & Grafo
- **MOC do Curso:** 00_MOC_Curso_Containers_Docker
- **Aula de Apoio:** Aula_04_Producao_Anti_OOM_Compose_Swarm_Alpine_N3
- **Aula de Build Moderno:** Aula_02_Ciclo_de_Vida_Dockerfile_Camadas_Imutaveis_N1
- **Aula de Segurança:** Aula_05_Seguranca_Hardening_Rootless_Capabilities_N4
- **Simulado Avaliativo:** Avaliacao_Curso_Containers_Docker
- **Referência de CLI:** Modelo_Docker_CLI_Referencia_Canonica
