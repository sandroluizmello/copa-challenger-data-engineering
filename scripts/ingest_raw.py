import os
import logging
from typing import Dict
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from dotenv import load_dotenv

# =====================================================
# Configuração de logging
# =====================================================
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def build_engine() -> Engine:
    """Carrega variáveis de ambiente e cria o engine de conexão com o MySQL."""
    load_dotenv()

    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")

    missing = [
        name
        for name, value in [
            ("DB_USER", user),
            ("DB_PASSWORD", password),
            ("DB_HOST", host),
            ("DB_PORT", port),
        ]
        if not value
    ]
    if missing:
        raise EnvironmentError(
            f"Variáveis de ambiente ausentes: {', '.join(missing)}. Verifique seu arquivo .env"
        )

    connection_string = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/raw"

    engine = create_engine(
        connection_string, connect_args={"auth_plugin": "mysql_native_password"}
    )
    return engine


def validate_dataframe(df: pd.DataFrame, table_name: str) -> bool:
    """Faz validações básicas no dataframe antes de gravar no banco."""
    if df.empty:
        logger.error(f"❌ Dataframe vazio para a tabela '{table_name}'. Ingestão abortada.")
        return False

    null_counts = df.isnull().sum()
    columns_with_nulls = null_counts[null_counts > 0]
    if not columns_with_nulls.empty:
        logger.warning(
            f"⚠️  Valores nulos encontrados em '{table_name}':\n{columns_with_nulls}"
        )

    logger.info(
        f"🔎 Validação de '{table_name}': {len(df)} linhas, {len(df.columns)} colunas."
    )
    return True


def load_csv_to_mysql(
    engine: Engine, file_path: str, table_name: str, mode: str = "replace"
) -> bool:
    """
    Lê um CSV e grava na tabela correspondente no schema raw do MySQL.

    Args:
        engine: engine SQLAlchemy já configurado.
        file_path: caminho do arquivo CSV.
        table_name: nome da tabela de destino.
        mode: comportamento caso a tabela já exista ('replace', 'append', 'fail').

    Returns:
        True se a ingestão foi concluída com sucesso, False caso contrário.
    """
    if not os.path.exists(file_path):
        logger.warning(f"⚠️  Arquivo não encontrado: {file_path}. Pulando...")
        return False

    try:
        logger.info(f"📦 Lendo {file_path}...")
        df = pd.read_csv(file_path, encoding="utf-8")
    except pd.errors.ParserError as e:
        logger.error(f"❌ Erro ao interpretar o CSV '{file_path}': {e}")
        return False
    except UnicodeDecodeError as e:
        logger.error(f"❌ Erro de encoding ao ler '{file_path}': {e}")
        return False

    if not validate_dataframe(df, table_name):
        return False

    try:
        logger.info(f"📥 Gravando tabela 'raw.{table_name}' ({len(df)} linhas)...")
        df.to_sql(
            table_name,
            con=engine,
            if_exists=mode,  # 'replace', 'append' ou 'fail'
            index=False,
            chunksize=1000,
        )
        logger.info(f"✅ Tabela 'raw.{table_name}' populada com sucesso!\n")
        return True
    except Exception as e:
        logger.exception(f"❌ Erro ao gravar a tabela '{table_name}' no MySQL: {e}")
        return False


def main() -> None:
    engine = build_engine()

    # Dicionário mapeando o arquivo CSV para o nome desejado da tabela na RAW
    datasets: Dict[str, str] = {
        "world_cup.csv": "world_cup",
        "fifa_ranking_2022-10-06.csv": "fifa_ranking",
        "matches_1930_2022.csv": "matches",
    }

    logger.info("🚀 Iniciando a ingestão dos dados brutos para o MySQL (Schema: raw)...")

    results = {}
    for file_name, table_name in datasets.items():
        file_path = os.path.join("data", "raw", file_name)
        results[table_name] = load_csv_to_mysql(
            engine, file_path, table_name, mode="replace"
        )

    success_count = sum(1 for ok in results.values() if ok)
    total = len(results)

    if success_count == total:
        logger.info(f"🏁 Processo de ingestão concluído com sucesso! ({success_count}/{total})")
    else:
        logger.warning(
            f"🏁 Processo de ingestão concluído com falhas. ({success_count}/{total} tabelas carregadas)"
        )
        failed_tables = [name for name, ok in results.items() if not ok]
        logger.warning(f"Tabelas com falha: {', '.join(failed_tables)}")


if __name__ == "__main__":
    main()