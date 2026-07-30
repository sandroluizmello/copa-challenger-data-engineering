# 🚀 Setup do CI/CD (GitHub Actions)

## 📁 Onde colocar cada arquivo

```
copa-challenger-data-engineering/
├── .github/
│   └── workflows/
│       └── dbt-ci.yml          ← workflow em si
├── dbt/
│   ├── packages.yml             ← necessário para dbt_expectations
│   └── ...
├── scripts/
│   ├── ingest_raw.py
│   └── download_kaggle.py       ← download automatizado do dataset
└── SETUP_CICD.md                ← este arquivo, na raiz
```

---

## 🎯 O que o pipeline faz

Ele tem **2 jobs** que rodam toda vez que você der `push` ou abrir um Pull Request pra `main`/`develop`.

### 1️⃣ `validate` — Validação Rápida (sempre roda, ~30 segundos)
- Instala o dbt
- Roda `dbt deps` (instala pacotes, ex. `dbt_expectations`)
- Roda `dbt parse`
- **Não precisa de banco de dados nem do dataset**
- Pega erros como: `ref()` apontando pra modelo que não existe, erro de sintaxe Jinja, ciclo de dependência entre modelos

**Por que separar isso?** É rápido e dá feedback em segundos a cada commit, sem depender de baixar dataset nenhum.

### 2️⃣ `full-test` — Build Completo + Testes (roda depois do `validate` passar, ~3-5 min)
- Instala as dependências de ingestão (`pandas`, `numpy`, etc via `requirements.txt`)
- Cria um **venv isolado só pro Kaggle** (`.venv-kaggle`) — veja a nota técnica abaixo sobre por quê
- Sobe um MySQL de verdade (container temporário, só existe durante o CI)
- Cria os schemas (`raw`, `staging`, `marts`) e o usuário da aplicação rodando `01_init.sql`
- Escreve o `~/.kaggle/kaggle.json` a partir dos secrets (`KAGGLE_USERNAME` + `KAGGLE_API_TOKEN`)
- Baixa o dataset real do Kaggle (`scripts/download_kaggle.py`, usando o venv isolado)
- Roda a ingestão (`scripts/ingest_raw.py`)
- Instala o dbt (com `protobuf==4.25.3` pinado — nota técnica abaixo)
- Roda `dbt run` (staging + marts + analytics)
- Roda `dbt test` (55 testes: 52 genéricos + 3 singulares)

**Isso simula o pipeline de produção inteiro**, do zero, a cada commit.

---

## 🧠 Nota técnica: por que existe um venv isolado só pro Kaggle

O `kaggle` (biblioteca/CLI 2.x, com suporte ao novo sistema de API Token do Kaggle) depende do `kagglesdk`, que exige `protobuf >= 6`.

Já o `dbt-core` está preso na faixa `1.7.x` — dependência do adapter `dbt-mysql`, que é um projeto comunitário não atualizado há tempos — e essa versão do dbt tem um bug conhecido que quebra com `protobuf >= 5` (por isso pinamos `protobuf==4.25.3` na instalação do dbt).

Essas duas exigências de protobuf são **incompatíveis no mesmo ambiente Python**. A solução foi isolar a instalação do `kaggle` num venv separado (`.venv-kaggle`), evitando que os dois conflitem.

---

## 🔑 Configurar os Secrets do Kaggle (OBRIGATÓRIO para o Job 2)

O Kaggle usa autenticação via `username` + `key` (não é um token único genérico — mesmo o novo sistema de "API Tokens" do Kaggle, pra essa biblioteca especificamente, precisa dos dois campos). Sem isso configurado, **o Job 1 (`validate`) continua funcionando normalmente**, mas o Job 2 (`full-test`) vai falhar na etapa de download.

### Passo 1: Gerar o Token do Kaggle

1. Acesse [kaggle.com/settings](https://www.kaggle.com/settings) → faça login
2. Aba **API Tokens**
3. Clique em **Generate New Token** (ou, se preferir o método legado, em **Legacy API Credentials** → **Create Legacy API Key**)
4. Anote seu **username** (aparece no canto superior direito do Kaggle) e a **key**/token gerado

### Passo 2: Cadastrar os 2 Secrets no GitHub

1. Vá no seu repositório → **Settings** → **Secrets and variables** → **Actions**
2. Clique em **New repository secret** e crie os dois:

| Name | Secret |
|------|--------|
| `KAGGLE_USERNAME` | seu usuário do Kaggle |
| `KAGGLE_API_TOKEN` | o token/key gerado no Passo 1 |

Pronto — o workflow já está configurado pra ler os dois secrets, escrever o `kaggle.json` e usá-lo automaticamente.

### ⚠️ Nunca comite suas credenciais!

O `kaggle.json` é gerado dinamicamente dentro do CI a partir dos secrets — ele nunca é commitado no repositório.

---

## ⚠️ E se eu não quiser configurar o Kaggle agora?

Sem problema! Você tem 2 opções:

**Opção A (recomendada por enquanto):** Deixe os 2 jobs como estão. O `validate` vai passar sempre (✅ verde no GitHub). O `full-test` vai falhar até você configurar os secrets — mas isso fica visível e documentado, não é um erro silencioso.

**Opção B:** Comentar/remover o job `full-test` do arquivo `dbt-ci.yml` por enquanto, e manter só o `validate`. Você adiciona o `full-test` depois quando quiser configurar os secrets.

---

## ✅ Como saber se funcionou

Depois do push, vá na aba **Actions** do seu repositório no GitHub. Você vai ver:

```
dbt CI
├── validate       ✅ (roda sempre)
└── full-test      ✅ ou ❌ (depende dos secrets)
```

Clique em qualquer job pra ver os logs detalhados de cada step.

---

## 📝 Commit

```bash
git add .github/workflows/dbt-ci.yml dbt/packages.yml scripts/download_kaggle.py

git commit -m "ci: adiciona pipeline de CI/CD com GitHub Actions

Workflow: dbt-ci.yml

Job 1 - validate (roda sempre, rápido):
  • dbt parse — valida sintaxe Jinja e referências (ref/source)
  • Não depende de banco de dados nem do dataset

Job 2 - full-test (build completo de integração):
  • kaggle instalado em venv isolado (.venv-kaggle), evitando conflito
    de protobuf com o dbt-core (preso em 1.7.x pelo adapter dbt-mysql)
  • Sobe MySQL real via GitHub Actions services
  • Cria schemas (raw/staging/marts) + usuário via 01_init.sql
  • Baixa dataset real do Kaggle (requer secrets KAGGLE_USERNAME +
    KAGGLE_API_TOKEN)
  • Roda scripts/ingest_raw.py
  • Roda dbt run (staging + marts + analytics)
  • Roda dbt test (55 testes: genéricos + singulares)

Adicional:
  • dbt/packages.yml — necessário para dbt_expectations
  • scripts/download_kaggle.py — download automatizado via Kaggle CLI

Setup necessário (documentado em SETUP_CICD.md):
  • Cadastrar KAGGLE_USERNAME e KAGGLE_API_TOKEN como secrets do repositório"

git push origin main
```

---

## 🔍 Troubleshooting

### ❌ "dbt_expectations not found" no Job 1

Verifique se `dbt/packages.yml` foi commitado e se o step `dbt deps` roda **antes** do `dbt parse` (já está assim no workflow).

### ❌ Job 2 falha em "Baixar dataset do Kaggle" com `KeyError: 'username'` ou erro de autenticação

O `kaggle.json` não foi escrito corretamente. Verifique:
1. Os 2 secrets (`KAGGLE_USERNAME` e `KAGGLE_API_TOKEN`) estão cadastrados com esses nomes exatos?
2. O step "Configurar credenciais do Kaggle" roda **antes** do step "Baixar dataset do Kaggle"?
3. A credencial do Kaggle ainda é válida?

### ❌ Job 2 falha em "Criar schemas" com `ERROR 1410` ou "connection refused"

- **ERROR 1410 (You are not allowed to create a user with GRANT):** o `01_init.sql` precisa ter um `CREATE USER IF NOT EXISTS` antes do `GRANT` — o MySQL 8.0 não cria usuário implicitamente mais.
- **connection refused:** o MySQL do `services` pode não ter subido a tempo. Aumente `--health-retries` se persistir.

### ❌ Job 2 falha em "Rodar ingestão" com "No such file or directory"

Confira se o caminho no workflow bate com a localização real do script (`scripts/ingest_raw.py`, não `ingest_raw.py` na raiz).

### ❌ Erro de versão do pandas/numpy/scikit-learn incompatível com Python 3.10

Alguns pacotes em versões muito recentes exigem Python 3.11+/3.12+. O projeto está fixado em Python 3.10 (por causa do `dbt-mysql`/`dbt-core`), então `requirements.txt` usa versões compatíveis (`pandas==2.2.3`, `numpy==2.1.3`); pacotes ainda não usados no código (`scikit-learn`, `scipy`, `ipykernel`) ficam sem versão travada.

### ❌ Quero rodar isso localmente antes de dar push

```bash
# Simula o Job 1 localmente
docker-compose -f docker/docker-compose.yml exec dbt bash
cd /workspace
dbt deps
dbt parse
```

---

**Setup completo e funcionando em produção.** ✅