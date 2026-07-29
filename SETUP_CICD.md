# 🚀 Setup do CI/CD (GitHub Actions)

## 📁 Onde colocar cada arquivo

```
copa-challenger-data-engineering/
├── .github/
│   └── workflows/
│       └── dbt-ci.yml          ← NOVO (o workflow em si)
├── dbt/
│   ├── packages.yml             ← NOVO (necessário para dbt_expectations)
│   └── ...
```

**Comandos:**
```bash
cd copa-challenger-data-engineering

mkdir -p .github/workflows
cp dbt-ci.yml .github/workflows/dbt-ci.yml
cp packages.yml dbt/packages.yml
```

---

## 🎯 O que o pipeline faz

Ele tem **2 jobs** que rodam em toda vez que você der `push` ou abrir um Pull Request:

### 1️⃣ `validate` — Validação Rápida (sempre roda, ~30 segundos)
- Instala o dbt
- Roda `dbt parse`
- **Não precisa de banco de dados nem do dataset**
- Pega erros como: `ref()` apontando pra modelo que não existe, erro de sintaxe Jinja, ciclo de dependência entre modelos

**Por que separar isso?** Porque é rápido e vai te dar feedback em segundos sempre que você commitar — sem depender de baixar dataset nenhum.

### 2️⃣ `full-test` — Build Completo + Testes (roda depois do `validate` passar, ~3-5 min)
- Sobe um MySQL de verdade (container temporário, só existe durante o CI)
- Cria os schemas (`raw`, `staging`, `marts`) rodando seu `01_init.sql`
- Baixa o dataset real do Kaggle
- Roda `ingest_raw.py` (ingestão real)
- Roda `dbt run` (staging + marts + analytics)
- Roda `dbt test` (os 55 testes: genéricos + singulares)

**Isso simula o pipeline de produção inteiro**, do zero, a cada commit.

---

## 🔑 Configurar o Secret do Kaggle (OBRIGATÓRIO para o Job 2)

O Job `full-test` precisa baixar o dataset, e isso exige o token de autenticação do Kaggle. Sem isso configurado, **o Job 1 (validate) continua funcionando normalmente**, mas o Job 2 vai falhar.

### Passo 1: Obter o Token do Kaggle

1. Acesse [kaggle.com](https://www.kaggle.com) → faça login
2. Vá em **Settings** (ícone do seu perfil → Settings) → aba **Account**
3. Role até a seção **API**
4. Clique em **Create New Token**
5. Isso baixa um arquivo `kaggle.json` com o conteúdo:
   ```json
   {"username":"seu_usuario","key":"sua_chave_api_aqui"}
   ```
6. **Copie o valor da chave `key`** (é o token que você vai usar)

### Passo 2: Cadastrar como Secret no GitHub

1. Vá no seu repositório no GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Crie um secret com:

| Campo | Valor |
|-------|-------|
| **Name** | `KAGGLE_API_TOKEN` |
| **Secret** | Cole o valor da chave `key` do seu `kaggle.json` |

**Exemplo:**
```
KAGGLE_API_TOKEN=sua_chave_api_super_secreta_aqui
```

Pronto — o workflow já está configurado pra ler `${{ secrets.KAGGLE_API_TOKEN }}` e usá-lo automaticamente.

### ⚠️ Nunca comite suas credenciais!

Certifique-se que o arquivo `kaggle.json` **nunca** é commitado no repositório. Ele já está no `.gitignore` por padrão.

---

## ⚠️ E se eu não quiser configurar o Kaggle agora?

Sem problema! Você tem 2 opções:

**Opção A (recomendada por enquanto):** Deixe os 2 jobs como estão. O `validate` vai passar sempre (✅ verde no GitHub). O `full-test` vai falhar até você configurar os secrets — mas isso fica visível e documentado, não é um erro silencioso.

**Opção B:** Comentar/remover o job `full-test` do arquivo `dbt-ci.yml` por enquanto, e manter só o `validate`. Você adiciona o `full-test` depois quando quiser configurar os secrets.

Se quiser ir pela Opção B, me avisa que eu já te mando a versão só com o Job 1.

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
git add .github/workflows/dbt-ci.yml dbt/packages.yml

git commit -m "ci: adiciona pipeline de CI/CD com GitHub Actions

Workflow: dbt-ci.yml

Job 1 - validate (roda sempre, rápido):
  • dbt parse — valida sintaxe Jinja e referências (ref/source)
  • Não depende de banco de dados nem do dataset
  • Feedback em segundos a cada commit

Job 2 - full-test (build completo de integração):
  • Sobe MySQL real via GitHub Actions services
  • Cria schemas (raw/staging/marts) via 01_init.sql
  • Baixa dataset real do Kaggle (requer secrets KAGGLE_USERNAME/KAGGLE_KEY)
  • Roda ingest_raw.py
  • Roda dbt run (staging + marts + analytics)
  • Roda dbt test (55 testes: genéricos + singulares)

Adicional:
  • dbt/packages.yml — necessário para dbt_expectations
    (usado nos testes de percentual do schema.yml, não existia até agora)

Setup necessário (documentado em SETUP_CICD.md):
  • Cadastrar KAGGLE_USERNAME e KAGGLE_KEY como secrets do repositório"

git push origin main
```

---

## 🔍 Troubleshooting

### ❌ "dbt_expectations not found" no Job 1

Verifique se `dbt/packages.yml` foi commitado e se o step `dbt deps` roda **antes** do `dbt parse` (já está assim no workflow).

### ❌ Job 2 falha em "Baixar dataset do Kaggle" com erro de autenticação

O secret `KAGGLE_API_TOKEN` não está configurado corretamente no GitHub. Verifique:
1. Você cadastrou o secret com o nome exato `KAGGLE_API_TOKEN`?
2. O valor é o **token direto** (a chave `key` do `kaggle.json`, não o JSON inteiro)?
3. A credencial do Kaggle ainda é válida?

Se tiver dúvidas, refaça os passos acima para obter um novo token.

### ❌ Job 2 falha em "Criar schemas" com connection refused

O MySQL do `services` pode não ter subido a tempo. O `--health-cmd` já espera ele ficar pronto, mas se persistir, aumente `--health-retries` para 15-20.

### ❌ Quero rodar isso localmente antes de dar push

```bash
# Simula o Job 1 localmente
docker-compose -f docker/docker-compose.yml exec dbt bash
cd /workspace
dbt deps
dbt parse
```

---

**Pronto para fazer o commit?** 🚀