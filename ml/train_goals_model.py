"""
Treina um modelo de gols esperados (Expected Goals) via Regressão de
Poisson, estimando a "força de ataque" e "força de defesa" de cada
seleção. É a mesma ideia por trás de modelos clássicos de analytics de
futebol (ex: Dixon-Coles), numa versão simplificada.

Ideia central:
    gols_marcados(time) ~ Poisson(exp(intercepto + ataque[time] +
                                       defesa[adversário] + mando_de_campo))

A partir da força de ataque/defesa de dois times, dá pra estimar quantos
gols cada um deve marcar num confronto hipotético, e então construir uma
matriz de probabilidade de placar (ex: P(2x1), P(1x1), P(0x0)...).
"""

import os

import joblib
import numpy as np
import pandas as pd
from scipy.stats import poisson
from sklearn.linear_model import PoissonRegressor
from sklearn.preprocessing import OneHotEncoder

from db import get_engine

MODELS_DIR = "models"
MAX_GOALS_GRID = 6  # matriz de placar vai de 0 a 6 gols por time


def _load_team_match_goals() -> pd.DataFrame:
    engine = get_engine()
    query = """
        select
            home_team_name as team_name,
            away_team_name as opponent_name,
            home_team_score as goals_for,
            1 as is_home
        from fct_matches
        where home_team_score is not null and away_team_score is not null

        union all

        select
            away_team_name as team_name,
            home_team_name as opponent_name,
            away_team_score as goals_for,
            0 as is_home
        from fct_matches
        where home_team_score is not null and away_team_score is not null
    """
    return pd.read_sql(query, engine)


def train_goals_model():
    df = _load_team_match_goals()

    encoder = OneHotEncoder(handle_unknown="ignore", sparse_output=True)
    team_dummies = encoder.fit_transform(df[["team_name"]])
    opponent_dummies = encoder.transform(
        df[["opponent_name"]].rename(columns={"opponent_name": "team_name"})
    )

    from scipy.sparse import hstack
    X = hstack([team_dummies, opponent_dummies, df[["is_home"]].values])
    y = df["goals_for"].values

    # alpha regulariza times com poucas partidas (evita força de ataque
    # "explosiva" estimada com base em 1-2 jogos apenas)
    model = PoissonRegressor(alpha=1.0, max_iter=500)
    model.fit(X, y)

    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(model, f"{MODELS_DIR}/goals_model.joblib")
    joblib.dump(encoder, f"{MODELS_DIR}/goals_encoder.joblib")

    print(f"✅ Modelo de gols esperados treinado com {len(df)} registros team-partida.")
    print(f"💾 Salvo em {MODELS_DIR}/goals_model.joblib")

    return model, encoder


def expected_goals(model, encoder, team_name: str, opponent_name: str, is_home: int) -> float:
    """Estima quantos gols `team_name` deve marcar contra `opponent_name`."""
    team_vec = encoder.transform(pd.DataFrame({"team_name": [team_name]}))
    opp_vec = encoder.transform(pd.DataFrame({"team_name": [opponent_name]}))

    from scipy.sparse import hstack
    X = hstack([team_vec, opp_vec, [[is_home]]])

    return float(model.predict(X)[0])


def scoreline_probability_matrix(lambda_home: float, lambda_away: float) -> np.ndarray:
    """Constrói a matriz P(placar_casa=i, placar_fora=j) assumindo gols
    independentes (simplificação padrão de modelos Poisson de futebol)."""
    home_probs = poisson.pmf(np.arange(MAX_GOALS_GRID + 1), lambda_home)
    away_probs = poisson.pmf(np.arange(MAX_GOALS_GRID + 1), lambda_away)
    return np.outer(home_probs, away_probs)


if __name__ == "__main__":
    model, encoder = train_goals_model()

    # Exemplo rápido de sanidade
    example_lambda_home = expected_goals(model, encoder, "Brazil", "Germany", is_home=0)
    example_lambda_away = expected_goals(model, encoder, "Germany", "Brazil", is_home=0)
    print(f"\n🔍 Exemplo: Brazil vs Germany (campo neutro)")
    print(f"   Gols esperados Brazil: {example_lambda_home:.2f}")
    print(f"   Gols esperados Germany: {example_lambda_away:.2f}")