# ⚽ Copa Challenger - Data Engineering

Projeto de data engineering usando o dataset [FIFA World Cup (Kaggle)](https://www.kaggle.com/datasets/piterfm/fifa-football-world-cup), com **MySQL** como banco de dados e **dbt** para as transformações.

---

## 🎯 Sobre o Projeto

Construir um pequeno **Data Warehouse** das Copas do Mundo, aplicando boas práticas de engenharia de dados:

- Ingestão de dados brutos (raw) no MySQL
- Transformações organizadas e versionadas com **dbt**
- Testes automatizados de qualidade de dados
- Documentação gerada automaticamente

**Stack:** MySQL 8.0 + dbt Core + Docker

---

## 🏗️ Arquitetura

```
Kaggle (CSV)
     │
     ▼
MySQL — schema raw        (dados brutos)
     │
     ▼  dbt run
MySQL — schema staging    (dados limpos)
     │
     ▼  dbt run
MySQL — schema marts      (fatos, dimensões e análises)
```

---

## 📁 Estrutura do Projeto

```
copa-challenger-data-engineering/
│
├── docker/                     # Tudo relacionado a containers
│   ├── docker-compose.yml       # Orquestra MySQL + dbt
│   └── Dockerfile               # Imagem do container dbt
│
├── database/                   # Scripts e artefatos do banco de dados
│   └── init-scripts/
│       └── 01_init.sql           # Cria schemas (raw, staging, marts)
│
├── dbt/                        # Projeto dbt completo
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── schema.yml
│   ├── models/
│   │   ├── staging/               # Limpeza dos dados brutos
│   │   └── marts/
│   │       ├── core/               # Fatos e dimensões
│   │       └── analytics/          # Views de análise
│   ├── tests/singular/            # Testes SQL customizados
│   ├── macros/                    # Funções SQL reutilizáveis
│   └── seeds/                     # CSVs de referência
│
├── data/
│   └── raw/                    # CSVs do Kaggle (não versionados)
│
├── requirements.txt             # Dependências Python
├── .env.example                 # Template de variáveis de ambiente
├── .gitignore
├── .dockerignore                # Fica na raiz — ver nota abaixo
└── README.md
```

> `.dockerignore` fica na **raiz** (não dentro de `docker/`), porque o contexto de build do container aponta para a raiz do repositório — é lá que o Docker procura esse arquivo.

---

## 🚀 Como Rodar

### Pré-requisitos
- Docker e Docker Compose instalados
- Conta no Kaggle (para baixar o dataset)

### Passos

```bash
# 1. Clonar o repositório
git clone https://github.com/sandroluizmello/copa-challenger-data-engineering.git
cd copa-challenger-data-engineering

# 2. Criar arquivo de variáveis de ambiente
cp .env.example .env

# 3. Baixar o dataset do Kaggle e colocar em data/raw/
#    https://www.kaggle.com/datasets/piterfm/fifa-football-world-cup

# 4. Subir os containers (repare no -f, pois o compose está em docker/)
docker-compose -f docker/docker-compose.yml up -d

# 5. Aguardar o MySQL iniciar (~20s) e testar a conexão do dbt
docker-compose -f docker/docker-compose.yml exec dbt dbt debug
```

> 💡 Dica: se preferir não digitar `-f docker/docker-compose.yml` toda vez, rode os comandos de dentro da pasta `docker/` (`cd docker && docker-compose up -d`), ou defina `export COMPOSE_FILE=docker/docker-compose.yml` na sua sessão do terminal.

### Comandos dbt úteis

```bash
docker-compose -f docker/docker-compose.yml exec dbt bash

# dentro do container, working directory já é /workspace = pasta dbt/
dbt run              # Executa as transformações
dbt test             # Roda os testes de qualidade
dbt docs generate    # Gera a documentação
dbt docs serve       # Abre a documentação em localhost:8000
```

---

## 🔌 Credenciais (ambiente local)

| Variável | Valor padrão |
|---|---|
| Host | `mysql` |
| Porta | `3306` |
| Database | `copa_challenger` |
| Usuário | `dbt_user` |
| Senha | `dbt_password_123` |

> ⚠️ Credenciais apenas para desenvolvimento local. Não usar em produção.

---

## 📌 Status do Projeto

- [x] Setup do Docker (MySQL + dbt), separado em `docker/`
- [x] Schemas criados (raw, staging, marts)
- [x] Projeto dbt organizado em `dbt/`
- [ ] **Próximo:** Analisar CSVs do Kaggle
- [ ] Criar tabelas raw com base na análise dos CSVs
- [ ] Modelos de staging (limpeza)
- [ ] Modelos de marts (fatos e dimensões)
- [ ] Views de análise
- [ ] Testes de qualidade de dados

---

## 📝 Licença

Projeto pessoal para fins de estudo e portfólio.