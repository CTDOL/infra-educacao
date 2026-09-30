# courses/ — Cursos Docs-as-Code

Cada curso é uma pasta `courses/<shortname>/` (kebab-case) com:

```
course.json                      # manifesto (schema abaixo)
lessons/*.md                     # aulas em Markdown (convertidas para HTML no provisionamento)
quiz/<nome>_moodle_aiken.txt     # questões no formato Aiken
```

## Regras
- **Zero dados de alunos, notas ou matrículas** no Git (LGPD). Não versionar backups `.mbz`.
- Vídeos e PDFs pesados ficam em storage externo/CDN e entram por embed HTML.
- Chave única do curso: `shortname`; `idnumber` também deve ser único (ex.: `CTDOL-DEV-001`).
- Novos cursos nascem na categoria oculta `_HOMOLOGACAO_SANDBOX` com `"visible": 0`.
- Publicação é **aditiva e idempotente**: cria o que falta, atualiza metadados/aulas; nunca faz restore destrutivo.

## Manifesto `course.json` (schema 1)
| Campo | Descrição |
|---|---|
| `shortname` / `idnumber` / `fullname` / `summary` | identificação |
| `category` | nome da categoria (criada se não existir) |
| `format` | formato do curso (`topics`) |
| `visible` | `0` oculto, `1` visível |
| `sections[]` | `name` + `lessons[]` (`title`,`file`) e/ou `quizzes[]` (`name`,`file`,`grade`,`attempts`) |

## Aiken
```
Enunciado em uma única linha
A. opção
B. opção
C. opção
D. opção
ANSWER: B
```
Uma linha em branco separa as questões; mínimo de 2 opções; `ANSWER` referencia uma opção existente.

Validação local: `python3 scripts/validar_cursos.py`.
