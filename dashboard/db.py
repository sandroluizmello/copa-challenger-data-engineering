import os
from pathlib import Path

import pandas as pd
import streamlit as st
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Carrega o .env da raiz do projeto (um nível acima da pasta dashboard/)
load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")


def _build_connection_url() -> str:
    """Monta a URL de conexão a partir das variáveis de ambiente.

    Usa as mesmas variáveis já definidas em .env.example (DB_HOST, DB_PORT,
    DB_USER, DB_PASSWORD). O schema de leitura é sempre 'marts', onde vivem
    as analytics views.
    """
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "3306")
    user = os.getenv("DB_USER", "dbt_user")
    password = os.getenv("DB_PASSWORD", "dbt_password_123")

    return f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/marts"


@st.cache_resource(show_spinner=False)
def get_engine():
    """Cria (uma única vez, cacheado) o engine de conexão com o MySQL."""
    return create_engine(_build_connection_url(), pool_pre_ping=True)


@st.cache_data(ttl=600, show_spinner="Consultando o banco de dados...")
def run_query(sql: str) -> pd.DataFrame:
    """Executa uma query e retorna um DataFrame. Cacheado por 10 minutos."""
    engine = get_engine()
    return pd.read_sql(sql, engine)
