# Escrevendo um Dockerfile

O **Dockerfile** descreve, passo a passo, como construir uma imagem.

## Exemplo

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER 10001
EXPOSE 8000
CMD ["python", "app.py"]
```

## Instruções principais

- `FROM`: imagem base.
- `WORKDIR`: diretório de trabalho.
- `COPY`: copia arquivos do contexto de build para a imagem.
- `RUN`: executa um comando **durante o build** e gera uma nova camada.
- `EXPOSE`: documenta a porta usada (não a publica).
- `CMD`: comando padrão **ao iniciar o container**.

## Construir e executar

```bash
docker build -t minha-app:1.0 .
docker run --rm -p 8000:8000 minha-app:1.0
```

## Boas práticas

1. Copie primeiro o arquivo de dependências e instale-as; depois copie o código. Assim o cache de camadas evita reinstalar tudo a cada mudança.
2. Use imagens base pequenas e com versão fixa.
3. Não rode como `root`: use `USER`.
4. **Nunca** coloque senhas ou chaves na imagem.
5. Use um arquivo `.dockerignore` para não enviar `.git`, dumps e segredos ao build.
