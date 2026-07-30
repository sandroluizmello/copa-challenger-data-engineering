# ⚽ Copa Challenger - Data Engineering

Projeto **ponta a ponta** de engenharia de dados usando o histórico das Copas do Mundo da FIFA, aplicando boas práticas modernas: arquitetura Medallion, dbt para transformações, containerização com Docker, e pipeline automatizada.

**Stack:** Python 3.10 • MySQL 8.0 • dbt Core • Docker Compose • SQLAlchemy

---

## 🎯 Objetivo do Projeto

Construir um **Data Warehouse das Copas do Mundo** desde a ingestão de dados brutos até modelos prontos para análise, demonstrando:

- ✅ Pipelines de ingestão robustas com validações
- ✅ Transformações organizadas e versionadas com dbt
- ✅ Arquitetura em camadas (Medallion: Raw → Staging → Marts)
- ✅ Ambiente reproduzível com Docker
- ✅ Testes automatizados de qualidade de dados
- ✅ CI/CD com GitHub Actions
- ✅ Documentação gerada automaticamente

---

## 🏗️ Arquitetura

```
 ┌─────────────────────────────────────────────────────────┐
 │  Kaggle (FIFA World Cup Dataset - CSV)                  │
 └────────────────┬────────────────────────────────────────┘
                  │
                  ▼
 ┌─────────────────────────────────────────────────────────┐
 │  BRONZE (Schema: raw)                                   │
 │  • Dados exatos como chegam da fonte                    │
 │  • Sem transformações, sem limpeza                      │
 │  • 3 tabelas: world_cup, fifa_ranking, matches          │
 └────────────────┬────────────────────────────────────────┘
                  │
            dbt run (staging)
                  │
                  ▼
 ┌─────────────────────────────────────────────────────────┐
 │  SILVER (Schema: staging)                               │
 │  • Dados limpos e padronizados                          │
 │  • Validações de integridade                            │
 │  • Deduplicação e tratamento de nulos                   │
 │  • Views para performance                               │
 └────────────────┬────────────────────────────────────────┘
                  │
            dbt run (marts)
                  │
                  ▼
 ┌─────────────────────────────────────────────────────────┐
 │  GOLD (Schema: marts) - STAR SCHEMA + ANALYTICS         │
 │                                                         │
 │  Dimensões:                                             │
 │  • dim_teams        - Informações dos times             │
 │  • dim_world_cups   - Histórico das copas               │
 │  • dim_stadiums     - Dados dos estádios                │
 │                                                         │
 │  Fatos Centrais:                                        │
 │  • fct_matches      - Tabela central (chave integrada)  │
 │                                                         │
 │  Fatos Especializados:                                  │
 │  • fct_match_cards               - Cartões              │
 │  • fct_match_goals               - Gols marcados        │
 │  • fct_match_penalty_shootouts   - Penalidades          │
 │  • fct_match_substitutions       - Substituições        │
 │                                                         │
 │  Views de Análise (Fase 1 - 8 views):                   │
 │  • analytics_dashboard_main_kpis - KPIs consolidados    │
 │  • analytics_team_overall_performance - Performance     │
 │  • analytics_team_by_world_cup - Performance/Copa       │
 │  • analytics_world_cup_summary - Resumo das copas       │
 │  • analytics_world_cup_champions_history - Campeões     │
 │  • analytics_top_scorers - Artilheiros históricos       │
 │  • analytics_team_discipline - Cartões por time         │
 │  • analytics_team_evolution_over_time - Trends          │
 │                                                         │
 └─────────────────────────────────────────────────────────┘
```

### 📊 Diagrama do Star Schema

```
                        ┌──────────────┐
                        │  dim_teams   │
                        └──────┬───────┘
                               │
   ┌──────────────┐            │            ┌──────────────┐
   │dim_world_cups│────────────┼────────────│ dim_stadiums │
   └───────┬──────┘            │            └──────┬───────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               ▼
                        ┌───────────────┐
                        │  fct_matches  │
                        └───────┬───────┘
                                │
        ┌───────────────┬───────┴───────┬──────────────────┐
        ▼               ▼               ▼                  ▼
┌───────────────┐┌───────────────┐┌────────────────────┐┌───────────────────┐
│fct_match_cards││fct_match_goals││fct_match_penalty_  ││fct_match_         │
│               ││               ││shootouts           ││substitutions      │
└───────────────┘└───────────────┘└────────────────────┘└───────────────────┘
```

---

## 📁 Estrutura do Projeto

```
copa-challenger-data-engineering/
│
├── 📂 .github/
│   └── workflows/
│       └── dbt-ci.yml                   # Pipeline de CI/CD (validate + full-test)
│
├── 📂 docker/                           # Orquestração de containers
│   ├── docker-compose.yml               # Define MySQL + dbt
│   └── Dockerfile                       # Imagem Python com dbt
│
├── 📂 database/                         # Banco de dados
│   └── init-scripts/
│       └── 01_init.sql                  # Cria schemas + usuário (raw, staging, marts)
│
├── 📂 dbt/                              # Transformações de dados
│   ├── dbt_project.yml                  # Config do projeto
│   ├── profiles.yml                     # Credenciais (env vars)
│   ├── packages.yml                     # Pacotes dbt (ex. dbt_expectations)
│   ├── schema.yml                       # Documentação de tabelas + testes genéricos
│   ├── models/
│   │   ├── staging/                     # Limpeza e validação
│   │   │   ├── stg_world_cups.sql
│   │   │   ├── stg_matches.sql
│   │   │   ├── stg_stadiums.sql
│   │   │   └── stg_teams.sql
│   │   ├── marts/
│   │   │   ├── core/                    # Fatos e dimensões (Star Schema)
│   │   │   │   ├── dim_teams.sql
│   │   │   │   ├── dim_world_cups.sql
│   │   │   │   ├── dim_stadiums.sql
│   │   │   │   ├── fct_matches.sql
│   │   │   │   ├── fct_match_cards.sql
│   │   │   │   ├── fct_match_goals.sql
│   │   │   │   ├── fct_match_penalty_shootouts.sql
│   │   │   │   └── fct_match_substitutions.sql
│   │   │   └── analytics/               # Views de análise (Fase 1 ✅)
│   │   │       ├── analytics_dashboard_main_kpis.sql
│   │   │       ├── analytics_team_overall_performance.sql
│   │   │       ├── analytics_team_by_world_cup.sql
│   │   │       ├── analytics_world_cup_summary.sql
│   │   │       ├── analytics_world_cup_champions_history.sql
│   │   │       ├── analytics_top_scorers.sql
│   │   │       ├── analytics_team_discipline.sql
│   │   │       └── analytics_team_evolution_over_time.sql
│   ├── tests/
│   │   ├── generic/                    # Testes genéricos (via schema.yml)
│   │   └── singular/                   # Testes singulares personalizados ✅
│   │       ├── test_team_record_consistency.sql
│   │       ├── test_no_negative_goals.sql
│   │       └── test_percentage_between_0_100.sql
│   ├── macros/                          # Funções SQL reutilizáveis
│   └── seeds/                           # CSVs de referência
│
├── 📂 data/                             # Datasets
│   └── raw/                             # CSVs do Kaggle (não versionado)
│       ├── world_cup.csv
│       ├── fifa_ranking_2022-10-06.csv
│       └── matches_1930_2022.csv
│
├── 📂 scripts/                          # Scripts utilitários
│   ├── ingest_raw.py                    # Ingestão de CSVs → MySQL (com logging)
│   └── download_kaggle.py               # Download automatizado do dataset (Kaggle API)
│
├── requirements.txt                     # Dependências Python
├── .env.example                         # Template de variáveis (DB + Kaggle)
├── .gitignore                           # Arquivos a ignorar
├── .dockerignore                        # Arquivos para ignorar no build
└── README.md                            # Este arquivo
```

---

## 🚀 Como Rodar o Projeto

### 📋 Pré-requisitos

- **Docker** >= 20.10 e **Docker Compose** >= 2.0
- **Git** para clonar o repositório
- ~5GB de espaço em disco
- **Conta no Kaggle** (para baixar o dataset)

### 1️⃣ Clonar o Repositório

```bash
git clone https://github.com/sandroluizmello/copa-challenger-data-engineering.git
cd copa-challenger-data-engineering
```

### 2️⃣ Configurar Variáveis de Ambiente

```bash
# Copiar o template
cp .env.example .env

# Ver o conteúdo (opcional)
cat .env
```

**`.env` padrão:**
```ini
DB_HOST=mysql
DB_PORT=3307
DB_USER=dbt_user
DB_PASSWORD=dbt_password_123
DB_NAME=copa_challenger

KAGGLE_USERNAME=
KAGGLE_API_TOKEN=
```

> ⚠️ **Aviso:** Credenciais apenas para **desenvolvimento local**. Nunca use em produção!

### 3️⃣ Baixar o Dataset do Kaggle

**Opção A — Script automatizado (recomendado):**
```bash
# 1. Gere seu token em: https://www.kaggle.com/settings > API Tokens > Generate New Token
# 2. Cole username e token no seu .env (KAGGLE_USERNAME e KAGGLE_API_TOKEN)
# 3. Instale as dependências e rode:

pip install -r requirements.txt
python scripts/download_kaggle.py
```

**Opção B — Manual:**
```bash
# 1. Ir em: https://www.kaggle.com/datasets/piterfm/fifa-football-world-cup
# 2. Clicar em "Download"
# 3. Descompactar os arquivos:

unzip archive.zip -d data/raw/

# Resultado esperado:
# data/raw/world_cup.csv
# data/raw/fifa_ranking_2022-10-06.csv
# data/raw/matches_1930_2022.csv
```

**Alternativa (via Kaggle CLI):**
```bash
pip install kaggle
kaggle datasets download -d piterfm/fifa-football-world-cup -p data/raw/ --unzip
```

### 4️⃣ Subir os Containers

```bash
# Do diretório raiz do projeto:
docker-compose -f docker/docker-compose.yml up -d

# Verificar status:
docker-compose -f docker/docker-compose.yml ps
```

**Output esperado:**
```
NAME            STATUS              PORTS
copa_mysql      Up (healthy)        0.0.0.0:3307->3306/tcp
copa_dbt        Up                  -
```

> 💡 **Dica:** Para não digitar `-f docker/docker-compose.yml` toda vez, execute:
> ```bash
> export COMPOSE_FILE=docker/docker-compose.yml
> # Ou navegue para a pasta docker:
> cd docker && docker-compose up -d
> ```

### 5️⃣ Testar Conexão com o dbt

```bash
docker-compose -f docker/docker-compose.yml exec dbt dbt debug
```

**Output esperado:**
```
Configuration:
  profiles.yml file: /workspace/profiles.yml
  dbt version: 1.6.0
  adapter plugin: dbt-mysql

Connected to: mysql://dbt_user@mysql:3307/copa_challenger
✓ All checks passed!
```

### 6️⃣ Executar Ingestão dos Dados

```bash
# Entre no container dbt
docker-compose -f docker/docker-compose.yml exec dbt bash

# Dentro do container, rode:
cd /workspace/..
python ingest_raw.py
```

**Output esperado:**
```
🚀 Iniciando a ingestão dos dados brutos para o MySQL (Schema: raw)...
📦 Lendo world_cup.csv...
📥 Gravando tabela 'raw.world_cup' (96 linhas)...
✅ Tabela 'raw.world_cup' populada com sucesso!
...
🏁 Processo de ingestão concluído com sucesso!
```

### 7️⃣ Executar Transformações com dbt

```bash
# Dentro do container dbt (use 'docker-compose exec dbt bash' se não estiver)

# Listar os modelos
dbt list

# Executar as transformações (staging + marts + analytics)
dbt run

# Rodar testes de qualidade
dbt test

# Gerar documentação
dbt docs generate

# Visualizar documentação (em outro terminal local)
dbt docs serve
# Abre em: http://localhost:8000
```

---

## 🔌 Acesso ao MySQL

### Via CLI (dentro do container)

```bash
docker-compose -f docker/docker-compose.yml exec mysql bash

# Dentro do container:
mysql -h mysql -u dbt_user -pdbt_password_123 copa_challenger

# Listar tabelas raw:
USE raw;
SHOW TABLES;

# Ver dados:
SELECT * FROM world_cup LIMIT 5;

# Ver dimensões criadas:
USE marts;
SELECT * FROM dim_teams;
SELECT * FROM dim_world_cups;
SELECT * FROM dim_stadiums;

# Ver fatos:
SELECT * FROM fct_matches LIMIT 10;
SELECT COUNT(*) FROM fct_match_goals;
SELECT COUNT(*) FROM fct_match_cards;

# Ver analytics:
SELECT * FROM analytics_dashboard_main_kpis;
SELECT * FROM analytics_team_overall_performance;
SELECT * FROM analytics_top_scorers;
```

### Via Client Gráfico (DBeaver, MySQL Workbench, etc.)

```
Host:     localhost
Port:     3307
Username: dbt_user
Password: dbt_password_123
Database: copa_challenger
```

---

## 📚 Comandos dbt Úteis

Execute dentro do container dbt (`docker-compose exec dbt bash`):

```bash
# Ver status do projeto
dbt debug

# Listar modelos
dbt list                          # Todos
dbt list -s models/staging        # Apenas staging
dbt list -s models/analytics      # Apenas analytics
dbt list -s tag:daily             # Apenas modelos com tag 'daily'

# Executar transformações
dbt run                           # Todos os modelos
dbt run -s models/staging         # Apenas staging
dbt run -s models/analytics       # Apenas analytics
dbt run -s +my_model              # Dependências à frente de my_model
dbt run -s my_model+              # Dependências atrás de my_model

# Testes
dbt test                          # Todos os testes (genéricos + singulares)
dbt test -s models/analytics      # Apenas testes de analytics
dbt test --select test_type:singular  # Apenas testes singulares

# Documentação
dbt docs generate                 # Gera docs em target/manifest.json
dbt docs serve                    # Abre em http://localhost:8000

# Limpeza
dbt clean                         # Remove pasta target/

# Modo dry-run
dbt compile                       # Compila SQL sem executar
```

---

## 🔄 CI/CD (GitHub Actions) ✅

O projeto tem um pipeline automatizado que roda a cada `push` ou Pull Request pra `main`/`develop`: [`.github/workflows/dbt-ci.yml`](./.github/workflows/dbt-ci.yml).

### Job 1 — `validate` (roda sempre, ~30s)
- `dbt parse` — valida sintaxe Jinja e referências (`ref`/`source`), sem precisar de banco de dados nem do dataset.

### Job 2 — `full-test` (build completo de integração, ~3-5 min)
- Sobe um MySQL real (GitHub Actions services)
- Cria os schemas e o usuário da aplicação via `01_init.sql`
- Baixa o dataset real do Kaggle (`scripts/download_kaggle.py`, em venv isolado — veja nota técnica abaixo)
- Roda a ingestão (`ingest_raw.py`)
- Roda `dbt run` (staging + marts + analytics)
- Roda `dbt test` (52 testes genéricos + 3 singulares)

### 🔑 Setup necessário (uma vez só)

Cadastre 2 secrets no repositório (**Settings → Secrets and variables → Actions**):

| Secret | Onde conseguir |
|--------|----------------|
| `KAGGLE_USERNAME` | Seu usuário do Kaggle |
| `KAGGLE_API_TOKEN` | [kaggle.com/settings](https://www.kaggle.com/settings) → aba **API Tokens** → **Generate New Token** |

Sem esses 2 secrets, o Job 1 (`validate`) continua funcionando normalmente — só o Job 2 (`full-test`) depende deles.

### 🧠 Nota técnica: por que o Kaggle roda num venv isolado

O `kaggle` (biblioteca/CLI, versão 2.x com suporte ao novo API Token) depende do `kagglesdk`, que exige `protobuf >= 6`. Já o `dbt-core` está preso na faixa `1.7.x` (dependência do adapter `dbt-mysql`, que não é atualizado há tempos) e precisa de `protobuf < 5` — um bug conhecido do dbt nessa versão quebra com protobuf mais novo. As duas exigências são incompatíveis no mesmo ambiente Python, então o workflow instala o Kaggle num **venv isolado** (`.venv-kaggle`) só pra esse step, evitando o conflito.

---

## 📊 Star Schema - Fatos e Dimensões Implementados

| Tabela | Descrição | Tipo |
|--------|-----------|------|
| `dim_teams` | Informações dos times | Slowly Changing Dimension (SCD 1) |
| `dim_world_cups` | Histórico das copas | Estática |
| `dim_stadiums` | Dados dos estádios | Estática |

### 📊 Tabelas de Fatos

| Tabela | Descrição | Granularidade |
|--------|-----------|---------------|
| `fct_matches` | Tabela central de partidas | Uma linha por partida |
| `fct_match_cards` | Registros de cartões | Uma linha por cartão |
| `fct_match_goals` | Registros de gols | Uma linha por gol |
| `fct_match_penalty_shootouts` | Penalidades em disputas | Uma linha por cobrança |
| `fct_match_substitutions` | Substituições | Uma linha por substituição |

---

## 📊 Analytics Views - Fase 1 ✅

**8 views de análise implementadas** cobrindo os principais casos de uso:

### 🎯 Dashboard & KPIs
- **analytics_dashboard_main_kpis** — KPIs consolidados para homepage (total copas, partidas, gols, artilheiro histórico)

### 🏆 Performance de Times
- **analytics_team_overall_performance** — Estatísticas gerais de cada seleção (vitórias, derrotas, gols)
- **analytics_team_by_world_cup** — Performance por seleção E por edição da Copa
- **analytics_team_evolution_over_time** — Evolução entre Copas consecutivas (trends)

### 🌍 Histórico de Copas
- **analytics_world_cup_summary** — Resumo de cada edição (campeão, vice, gols, público)
- **analytics_world_cup_champions_history** — Histórico de campeões/vices com extras (time mais indisciplinado, melhor em pênaltis)

### ⚽ Análise Ofensiva
- **analytics_top_scorers** — Ranking de artilheiros históricos (gols por tipo)

### 🔴 Análise Defensiva
- **analytics_team_discipline** — Estatísticas de cartões por seleção (amarelos, vermelhos, expulsões)

**Todas reutilizam o Star Schema** e seguem boas práticas de dbt (comments, prefix padrão, views em marts schema).

---

## 🧪 Testes Automatizados ✅

**Cobertura completa com genéricos + singulares:**

### ✅ Genéricos (via schema.yml)
- **52 testes automatizados** cobrindo:
  - `not_null`: campos críticos não vazios
  - `unique`: chaves primárias verdadeiramente únicas
  - `relationships`: integridade referencial (FKs válidas)
  - `accepted_values`: enums validados (ex: card_type ∈ {AMARELO, VERMELHO, SEGUNDO_AMARELO})
  - `dbt_expectations.*_between`: percentuais entre 0-100%

### ✅ Singulares (SQL customizado)
- **test_team_record_consistency** — Valida: `wins + draws + losses = total_matches`
- **test_no_negative_goals** — Nenhum gol negativo em nenhuma tabela
- **test_percentage_between_0_100** — Percentuais válidos em todas as views

**Status:** Todos os testes passam ✅ (PASS=52 WARN=0 ERROR=0)

---

## 📈 Status do Projeto

- [x] Setup Docker (MySQL + dbt)
- [x] Schemas criados (raw, staging, marts)
- [x] Script de ingestão de dados (com logging e validações)
- [x] Projeto dbt estruturado
- [x] Modelos de staging (limpeza e validação)
- [x] Modelos de marts - Star Schema completo ⭐
  - [x] dim_teams
  - [x] dim_world_cups
  - [x] dim_stadiums
  - [x] fct_matches
  - [x] fct_match_cards
  - [x] fct_match_goals
  - [x] fct_match_penalty_shootouts
  - [x] fct_match_substitutions
- [x] **Views de análise - Fase 1** ⭐ NOVO
  - [x] analytics_dashboard_main_kpis
  - [x] analytics_team_overall_performance
  - [x] analytics_team_by_world_cup
  - [x] analytics_world_cup_summary
  - [x] analytics_world_cup_champions_history
  - [x] analytics_top_scorers
  - [x] analytics_team_discipline
  - [x] analytics_team_evolution_over_time
- [x] **Testes automatizados** ⭐ NOVO
  - [x] Genéricos (52 testes via schema.yml)
  - [x] Singulares (3 testes customizados)
- [x] **CI/CD (GitHub Actions)** ⭐ NOVO
  - [x] Job validate (dbt parse)
  - [x] Job full-test (build completo + 55 testes com dados reais)
- [ ] Dashboard (Streamlit)
- [ ] Modelo preditivo (Machine Learning)

---

## 🛠️ Stack Utilizada

| Componente | Tecnologia | Versão |
|-----------|-----------|--------|
| **Banco de Dados** | MySQL | 8.0 |
| **Transformação** | dbt Core | 1.7.x (fixado pelo adapter `dbt-mysql`) |
| **Container** | Docker | 20.10+ |
| **Python** | Python | 3.10 |
| **ORM** | SQLAlchemy | 2.0+ |
| **Dados** | Pandas | 2.2+ |
| **CI/CD** | GitHub Actions | - |

---

## 📝 Próximos Passos

1. **Dashboard com Streamlit** - Visualizações interativas dos dados de matches
2. **Modelo preditivo** - Prever resultado de partidas com sklearn
3. **Deployment** - Deploy em cloud (AWS/GCP/Azure)

---

## 🔍 Troubleshooting

### ❌ Erro: "Cannot connect to MySQL"

```bash
# Verificar se container MySQL está saudável
docker-compose -f docker/docker-compose.yml ps

# Ver logs
docker-compose -f docker/docker-compose.yml logs mysql

# Aguardar ~30 segundos e tentar novamente
sleep 30
docker-compose -f docker/docker-compose.yml exec dbt dbt debug
```

### ❌ Erro: "File not found: data/raw/world_cup.csv"

```bash
# Verificar se arquivos existem
ls -la data/raw/

# Se não existem, baixar do Kaggle:
# https://www.kaggle.com/datasets/piterfm/fifa-football-world-cup
```

### ❌ Erro: "Port 3307 already in use"

```bash
# Liberar a porta ou usar outra
docker-compose -f docker/docker-compose.yml down

# Ou mudar em docker/docker-compose.yml:
# ports:
#   - "3308:3306"   # Usar 3308 em vez de 3307
```

### ❌ Erro: "dbt_expectations not found"

```bash
# Se tiver problemas com dbt_expectations, instale via packages.yml
# Adicione ao dbt/packages.yml:
# packages:
#   - package: calogica/dbt_expectations
#     version: 0.8.0

dbt deps
dbt test
```

### ❌ Erro ao baixar dataset do Kaggle ("Could not find kaggle.json" / "KeyError: 'username'")

```bash
# Confirme que KAGGLE_USERNAME e KAGGLE_API_TOKEN estão no seu .env (local)
# ou cadastrados como secrets do repositório (CI/CD)

cat .env | grep KAGGLE

# Gere um novo token em:
# https://www.kaggle.com/settings > API Tokens > Generate New Token
```

### ❌ Erro: "permission denied" ao executar scripts

```bash
# Dar permissão
chmod +x scripts/ingest_raw.py

# Ou executar via Python:
docker-compose -f docker/docker-compose.yml exec dbt python ingest_raw.py
```

### ❌ dbt não encontra arquivos

```bash
# Certificar que está executando do diretório correto
docker-compose -f docker/docker-compose.yml exec dbt pwd

# Deve ser: /workspace

# Se não estiver, ajustar volumes no docker-compose.yml
```

### ❌ Testes falhando

```bash
# Rodar testes com verbosidade
dbt test --debug

# Rodar teste específico
dbt test -s test_team_record_consistency

# Ver qual dado está causando falha
dbt test --store-failures
# Depois conferir: dbt_tests.test_failures (tabela criada)
```

---

## 🤝 Como Contribuir

1. Fork o repositório
2. Crie uma branch (`git checkout -b feature/sua-feature`)
3. Commit suas mudanças (`git commit -m 'Add feature'`)
4. Push para a branch (`git push origin feature/sua-feature`)
5. Abra um Pull Request

---

## 📚 Recursos e Documentação

- [dbt Documentation](https://docs.getdbt.com/)
- [MySQL 8.0](https://dev.mysql.com/doc/)
- [SQLAlchemy](https://docs.sqlalchemy.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Dataset no Kaggle](https://www.kaggle.com/datasets/piterfm/fifa-football-world-cup)
- [dbt Expectations Package](https://github.com/calogica/dbt-expectations)

---

## 📄 Licença

Projeto pessoal para fins de estudo e portfólio. Sinta-se livre para usar como referência.

---

## 👨‍💻 Autor

**Sandro Luiz Mello**  
Data Engineer | Estudante de Pós-Graduação em Engenharia de Dados (PUC Minas)

📧 [GitHub](https://github.com/sandroluizmello) | 🔗 [LinkedIn](https://linkedin.com/in/sandroluizmello)

---

**Última atualização:** Julho 2026 - Fase 1 Analytics Views + Testes Automatizados + CI/CD Completos ✅