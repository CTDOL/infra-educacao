#!/usr/bin/env python3
"""Valida courses/*/course.json e os bancos de questoes Aiken. Sem dependencias externas."""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent / "courses"
KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
OPCAO = re.compile(r"^[A-Z][.)] \S")
RESP = re.compile(r"^ANSWER: ([A-Z])$")
# Pastas/rotas do Moodle que nao podem virar atalho curto (manter em sincronia com publicar_atalhos.sh).
RESERVADOS = set(
    "admin analytics auth availability backup badges blocks blog cache calendar cohort comment communication "
    "competency completion contentbank course customfield enrol error files filter grade group h5p help install "
    "lang lib local login media message mnet mod my notes payment pix plagiarism portfolio privacy question "
    "rating report reportbuilder repository rss search tag theme user webservice cgi-bin".split()
)
erros = []


def erro(msg):
    erros.append(msg)


def validar_aiken(arquivo):
    blocos = [b for b in re.split(r"\n\s*\n", arquivo.read_text(encoding="utf-8").strip()) if b.strip()]
    if not blocos:
        erro(f"{arquivo}: vazio")
    for n, bloco in enumerate(blocos, 1):
        linhas = bloco.splitlines()
        letras = [l[0] for l in linhas[1:-1] if OPCAO.match(l)]
        resp = RESP.match(linhas[-1])
        if len(linhas) < 4 or len(letras) != len(linhas) - 2 or len(letras) < 2:
            erro(f"{arquivo}: questao {n} fora do formato Aiken")
        elif not resp or resp.group(1) not in letras:
            erro(f"{arquivo}: questao {n} com ANSWER ausente ou invalido")
        elif OPCAO.match(linhas[0]):
            erro(f"{arquivo}: questao {n} sem enunciado")


def main():
    cursos = sorted(p for p in RAIZ.glob("*/course.json"))
    if not cursos:
        erro("nenhum course.json encontrado")
    vistos = {"shortname": set(), "idnumber": set()}
    for manifesto in cursos:
        pasta = manifesto.parent
        try:
            dados = json.loads(manifesto.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            erro(f"{manifesto}: JSON invalido ({e})")
            continue
        for campo in ("schema", "shortname", "idnumber", "fullname", "category", "sections"):
            if campo not in dados:
                erro(f"{manifesto}: campo obrigatorio ausente: {campo}")
        sn = dados.get("shortname", "")
        if not KEBAB.match(sn) or sn != pasta.name:
            erro(f"{manifesto}: shortname deve ser kebab-case e igual ao nome da pasta")
        for chave in vistos:
            valor = dados.get(chave)
            if valor in vistos[chave]:
                erro(f"{manifesto}: {chave} duplicado: {valor}")
            vistos[chave].add(valor)
        if "shortlink" in dados:
            if not isinstance(dados["shortlink"], bool):
                erro(f"{manifesto}: shortlink deve ser true/false")
            elif dados["shortlink"] and sn in RESERVADOS:
                erro(f"{manifesto}: shortname '{sn}' e reservado do Moodle e nao pode ser atalho")
        if "image" in dados:
            img_rel = dados["image"]
            img_alvo = (pasta / img_rel).resolve()
            if pasta.resolve() not in img_alvo.parents or not img_alvo.is_file():
                erro(f"{manifesto}: arquivo de imagem inexistente ou fora do curso: {img_rel}")
            elif not img_rel.lower().endswith((".png", ".jpg", ".jpeg", ".webp", ".svg")):
                erro(f"{manifesto}: extensao de imagem invalida: {img_rel}")
        if "enrolment" in dados:
            enr = dados["enrolment"]
            if not isinstance(enr, dict):
                erro(f"{manifesto}: campo enrolment deve ser um objeto")
            else:
                tipo = enr.get("type")
                if tipo not in ("manual", "self", "fee"):
                    erro(f"{manifesto}: enrolment.type invalido: {tipo} (esperado: manual, self, fee)")
                if tipo == "fee":
                    fee = enr.get("fee", {})
                    try:
                        valor_ok = isinstance(fee, dict) and float(fee.get("amount", 0)) > 0
                    except (TypeError, ValueError):
                        valor_ok = False
                    if not valor_ok:
                        erro(f"{manifesto}: enrolment.fee deve conter amount positivo para tipo fee")
                    elif not re.fullmatch(r"[A-Z]{3}", str(fee.get("currency", ""))):
                        erro(f"{manifesto}: enrolment.fee.currency deve ser codigo ISO de 3 letras (ex.: BRL)")
                    elif not str(fee.get("account", "")).strip():
                        erro(f"{manifesto}: enrolment.fee.account deve ter o nome da conta de pagamento do Moodle")
        for sec in dados.get("sections", []):
            itens = [l["file"] for l in sec.get("lessons", [])] + [q["file"] for q in sec.get("quizzes", [])]
            for rel in itens:
                alvo = (pasta / rel).resolve()
                if pasta.resolve() not in alvo.parents or not alvo.is_file():
                    erro(f"{manifesto}: arquivo inexistente ou fora do curso: {rel}")
                elif rel.endswith(".txt"):
                    validar_aiken(alvo)
    for e in erros:
        print("ERRO:", e)
    print(f"{len(cursos)} curso(s) verificado(s), {len(erros)} erro(s).")
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main())
