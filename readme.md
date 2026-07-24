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
 │  GOLD (Schema: marts) - STAR SCHEMA                     │
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
 │  • fct_match_cards       - Cartões (amarelo/vermelho)   │
 │  • fct_match_goals       - Gols marcados                │
 │  • fct_match_shoot_out_penalties - Penalidades          │
 │  • fct_match_substitutions      - Substituições         │
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
│fct_match_cards││fct_match_goals││fct_match_shoot_out_││fct_match_         │
│               ││               ││penalties           ││substitutions      │
└───────────────┘└───────────────┘└────────────────────┘└───────────────────┘
```

---

## 📁 Estrutura do Projeto

```
copa-challenger-data-engineering/
│
├── 📂 docker/                           # Orquestração de containers
│   ├── docker-compose.yml               # Define MySQL + dbt
│   └── Dockerfile                       # Imagem Python com dbt
│
├── 📂 database/                         # Banco de dados
│   └── init-scripts/
│       └── 01_init.sql                  # Cria schemas (raw, staging, marts)
│
├── 📂 dbt/                              # Transformações de dados
│   ├── dbt_project.yml                  # Config do projeto
│   ├── profiles.yml                     # Credenciais (env vars)
│   ├── schema.yml                       # Documentação de tabelas/testes
│   ├── models/
│   │   ├── staging/                     # Limpeza e validação
│   │   │   ├── stg_world_cups.sql
│   │   │   ├── stg_matches.sql
│   │   │   ├── stg_stadiums.sql
│   │   │   └── stg_teams.sql
│   │   └── marts/
│   │       ├── core/                    # Fatos e dimensões
│   │       │   ├── dim_teams.sql
│   │       │   ├── dim_world_cups.sql
│   │       │   ├── dim_stadiums.sql
│   │       │   ├── fct_matches.sql
│   │       │   ├── fct_match_cards.sql
│   │       │   ├── fct_match_goals.sql
│   │       │   ├── fct_match_shoot_out_penalties.sql
│   │       │   └── fct_match_substitutions.sql
│   │       └── analytics/               # Views de análise (próximo)
│   ├── tests/                           # Testes de qualidade (próximo)
│   ├── macros/                          # Funções SQL reutilizáveis (próximo)
│   └── seeds/                           # CSVs de referência (próximo)
│
├── 📂 data/                             # Datasets
│   └── raw/                             # CSVs do Kaggle (não versionado)
│       ├── world_cup.csv
│       ├── fifa_ranking_2022-10-06.csv
│       └── matches_1930_2022.csv
│
├── 📂 scripts/                          # Scripts utilitários
│   └── ingest_raw.py                    # Ingestão de CSVs → MySQL
│
├── requirements.txt                     # Dependências Python (versões fixadas)
├── requirements_curado.txt              # Dependências sem transitivas
├── .env.example                         # Template de variáveis
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
```

> ⚠️ **Aviso:** Credenciais apenas para **desenvolvimento local**. Nunca use em produção!

### 3️⃣ Baixar o Dataset do Kaggle

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
cd /workspace/..  # Sai da pasta dbt
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

# Executar as transformações (staging + marts)
dbt run

# Rodar testes de qualidade (quando implementados)
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
dbt list -s tag:daily             # Apenas modelos com tag 'daily'

# Executar transformações
dbt run                           # Todos os modelos
dbt run -s models/staging         # Apenas staging
dbt run -s models/marts           # Apenas marts
dbt run -s +my_model              # Dependências à frente de my_model
dbt run -s my_model+              # Dependências atrás de my_model

# Testes
dbt test                          # Todos os testes
dbt test -s models/staging        # Testes apenas de staging

# Documentação
dbt docs generate                 # Gera docs em target/manifest.json
dbt docs serve                    # Abre em http://localhost:8000

# Limpeza
dbt clean                         # Remove pasta target/

# Modo dry-run
dbt compile                       # Compila SQL sem executar
```

---

## 📊 Star Schema - Fatos e Dimensões Implementados

### 📌 Dimensões

| Tabela | Descrição | Campos Principais |
|--------|-----------|------------------|
| `dim_teams` | Informações dos times | team_id, team_name, country, confederation |
| `dim_world_cups` | Histórico das copas | world_cup_id, year, host_country, winner |
| `dim_stadiums` | Dados dos estádios | stadium_id, stadium_name, city, capacity |

### 📊 Tabelas de Fatos

| Tabela | Descrição | Função |
|--------|-----------|--------|
| `fct_matches` | Tabela central de partidas | Conecta todas as dimensões |
| `fct_match_cards` | Registros de cartões | Análise de disciplina (amarelo/vermelho) |
| `fct_match_goals` | Registros de gols | Análise de desempenho ofensivo |
| `fct_match_shoot_out_penalties` | Penalidades | Análise de decisões por pênaltis |
| `fct_match_substitutions` | Substituições | Análise de estratégia tática |

---

## 📈 Status do Projeto

- [x] Setup Docker (MySQL + dbt)
- [x] Schemas criados (raw, staging, marts)
- [x] Script de ingestão de dados (com logging e validações)
- [x] Projeto dbt estruturado
- [x] Modelos de staging (limpeza e validação)
- [x] **Modelos de marts - Star Schema completo** ⭐ NOVO
  - [x] dim_teams
  - [x] dim_world_cups
  - [x] dim_stadiums
  - [x] fct_matches
  - [x] fct_match_cards
  - [x] fct_match_goals
  - [x] fct_match_shoot_out_penalties
  - [x] fct_match_substitutions
- [ ] Views de análise (analytics)
- [ ] Testes automatizados (generic + singular)
- [ ] CI/CD (GitHub Actions)
- [ ] Dashboard (Streamlit)
- [ ] Modelo preditivo (Machine Learning)

---

## 🛠️ Stack Utilizada

| Componente | Tecnologia | Versão |
|-----------|-----------|--------|
| **Banco de Dados** | MySQL | 8.0 |
| **Transformação** | dbt Core | 1.6+ |
| **Container** | Docker | 20.10+ |
| **Python** | Python | 3.10 |
| **ORM** | SQLAlchemy | 2.0+ |
| **Dados** | Pandas | 3.0+ |

---

## 📝 Próximos Passos

1. **Views de análise** - Criar modelos no schema `analytics` para consultas comuns
2. **Testes automatizados** - Implementar testes genéricos e singulares no dbt
3. **Dashboard com Streamlit** - Visualizações dos dados de matches
4. **Modelo preditivo** - Prever resultado de partidas com sklearn
5. **CI/CD** - GitHub Actions para validar transformações
6. **Deployment** - Deploy em cloud (AWS/GCP/Azure)

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

---

## 📄 Licença

Projeto pessoal para fins de estudo e portfólio. Sinta-se livre para usar como referência.

---

## 👨‍💻 Autor

**Sandro Luiz Mello**  
Data Engineer | Estudante de Pós-Graduação em Engenharia de Dados (PUC Minas)

📧 [GitHub](https://github.com/sandroluizmello) | 🔗 [LinkedIn](https://linkedin.com/in/sandroluizmello)

---

**Última atualização:** Julho 2026 - Star Schema implementado