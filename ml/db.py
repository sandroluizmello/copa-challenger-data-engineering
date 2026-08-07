import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine

# Carrega o .env da raiz do projeto (um nível acima da pasta ml/)
load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")


def get_engine():
    """Cria o engine de conexão com o MySQL (schema marts)."""
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "3306")
    user = os.getenv("DB_USER", "dbt_user")
    password = os.getenv("DB_PASSWORD", "dbt_password_123")

    url = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/marts"
    return create_engine(url, pool_pre_ping=True)