# DOC_003 — Venda por Pix/link de pagamento com matrícula manual

> [!tldr] Resumo
> Fluxo de venda **sem CNPJ e sem gateway no Moodle**: o aluno paga por um **link de pagamento**
> (Pix ou cartão), envia o comprovante pelo **WhatsApp Business** e o operador o **matricula
> manualmente**. O curso continua com `"enrolment": { "type": "manual" }` no `course.json`.

---

## 1. O que o aluno vê
A página pública do curso (`https://edu.ctdol.com.br/<shortname>`) mostra, no resumo do curso
(`summary` do `course.json`), o bloco **"Como comprar"**: preço, link de pagamento e WhatsApp.

Valores atuais do `containers-docker`: **R$ 100,00**, link `https://mpago.la/2fc99ZD`
(Mercado Pago), WhatsApp Business **(51) 98552-2891**.

Regras para esse bloco (o repositório é **público**):
- Use **link de pagamento** (ou chave Pix **aleatória**). **Nunca** CPF, e-mail ou telefone pessoal como chave Pix.
- O WhatsApp publicado deve ser o **Business** da CTDOL.

## 2. Passo a passo de cada venda (operador)
1. **Receber o comprovante** no WhatsApp Business, com o **e-mail** que o aluno usou na Conta CTDOL.
2. **Conferir o pagamento no app/painel do link de pagamento** (não confie só no print do comprovante):
   valor = preço do curso, status *aprovado/recebido*.
3. **Garantir que o aluno já existe no Moodle**: ele precisa ter entrado ao menos uma vez em
   `https://edu.ctdol.com.br/login/index.php` → **Entrar com Conta CTDOL** (o cadastro é feito
   no Keycloak, na própria tela de login).
   Se ainda não entrou, peça para entrar e avisar.
4. **Matricular**: Moodle → curso → **Participantes** → **Inscrever usuários** → buscar pelo e-mail
   → papel **Estudante** → **Inscrever usuários**.
5. **Responder ao aluno** no WhatsApp com o link do curso.
6. **Registrar a venda** (planilha/controle: data, aluno, e-mail, valor, ID da transação) para o
   carnê-leão / contabilidade.

## 3. Mensagens prontas (WhatsApp)
**Pedido de comprovante**
> Olá! Para liberar seu acesso, envie o comprovante do pagamento e o e-mail da sua Conta CTDOL.
> Se ainda não tem conta, crie em https://edu.ctdol.com.br/login/index.php (botão *Entrar com Conta CTDOL*).

**Acesso liberado**
> Pagamento confirmado e matrícula feita! Acesse: https://edu.ctdol.com.br/<shortname>
> Bons estudos!

## 4. Cuidados
- **Não matricule antes de conferir o recebimento** no painel do link de pagamento (prints podem ser editados).
- Reembolso: estornar pelo painel do link e **cancelar a matrícula** em *Participantes*.
- Mudança de preço: atualizar o `summary` no `course.json` (PR) e o valor do link de pagamento.
- Fiscal: vendas como pessoa física entram no **carnê-leão**; consulte um contador.

## 5. Quando automatizar
Com volume maior, migrar para matrícula automática: gateway Mercado Pago próprio (`paygw`),
PayPal com CNPJ/MEI (`"type": "fee"`, já suportado pelo provisionador) ou plataforma
(Hotmart/Kiwify) + webhook.
