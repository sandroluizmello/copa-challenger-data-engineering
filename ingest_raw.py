import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

def main():

    # 1. Carrega as variáveis do arquivo .env local
    load_dotenv()

    # Monta a string de conexão para o MySQL local (Docker exposto na porta 3306)
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")

    # Monta a string de conexão base limpa
    connection_string = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/raw"
    
    # Criamos o engine passando o plugin de senha dentro de connect_args
    engine = create_engine(
        connection_string,
        connect_args={"auth_plugin": "mysql_native_password"}
    )

    # 2. Dicionário mapeando o arquivo CSV para o nome desejado da tabela na RAW
    datasets = {
        "world_cup.csv": "world_cup",
        "fifa_ranking_2022-10-06.csv": "fifa_ranking",
        "matches_1930_2022.csv": "matches",
    }

    print("🚀 Iniciando a ingestão dos dados brutos para o MySQL (Schema: raw)...")

    for file_name, table_name in datasets.items():
        # Caminho dinâmico para buscar os arquivos dentro da estrutura do seu projeto
        file_path = os.path.join("data", "raw", file_name)

        if not os.path.exists(file_path):
            print(f"⚠️ Arquivo não encontrado: {file_path}. Pulando ...")
            continue

        print(f"📦 Lendo {file_name}...")
        # Lê o CSV usando pandas
        df = pd.read_csv(file_path)

        print(f"📥 Gravando tabela 'raw.{table_name}' ({len(df)} linhas)...")
        # O parâmetro if_exists='replace' reconstrói a tabela fielmente caso ela já exista
        # index=False garante que o índice do pandas não vire uma coluna no banco

        df.to_sql(table_name, con=engine, if_exists='replace', index=False)

        print(f"✅ Tabela 'raw.{table_name}' populada com sucesso!\n")
    
    print("🏁 Processo de ingestão concluído com sucesso!")

if __name__ == "__main__":
    main()