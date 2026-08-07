"""
Combina os dois modelos treinados (resultado + gols esperados) numa
função única e amigável: predict_matchup("Brazil", "Germany").

Uso:
    python predict.py "Brazil" "Germany"

Ou importando:
    from predict import predict_matchup
    resultado = predict_matchup("Brazil", "Germany")
"""

import sys

import joblib
import numpy as np
import pandas as pd

from data_prep import DEFAULT_GOALS_AGAINST, DEFAULT_GOALS_FOR, DEFAULT_WIN_RATE
from db import get_engine
from train_goals_model import expected_goals, scoreline_probability_matrix

MODELS_DIR = "models"


def _load_artifacts():
    result_model = joblib.load(f"{MODELS_DIR}/result_model.joblib")
    result_scaler = joblib.load(f"{MODELS_DIR}/result_scaler.joblib")
    feature_columns = joblib.load(f"{MODELS_DIR}/result_features.joblib")
    goals_model = joblib.load(f"{MODELS_DIR}/goals_model.joblib")
    goals_encoder = joblib.load(f"{MODELS_DIR}/goals_encoder.joblib")
    return result_model, result_scaler, feature_columns, goals_model, goals_encoder


def _latest_team_stats() -> pd.DataFrame:
    """Pega as estatísticas mais recentes conhecidas de cada seleção
    (usadas como 'estado atual' do time para prever confrontos futuros)."""
    engine = get_engine()
    
    # Query que já calcula as estatísticas por time (similar ao data_prep,
    # mas agregado direto no banco sem montar o dataset inteiro)
    query = """
        with team_stats as (
            select
                home_team_name as team_name,
                sum(case when home_team_score > away_team_score then 1 else 0 end) as wins,
                sum(case when home_team_score = away_team_score then 1 else 0 end) as draws,
                count(*) as total_matches,
                avg(home_team_score) as avg_goals_for,
                avg(away_team_score) as avg_goals_against
            from fct_matches
            where home_team_score is not null and away_team_score is not null
            group by home_team_name
            
            union all
            
            select
                away_team_name as team_name,
                sum(case when away_team_score > home_team_score then 1 else 0 end) as wins,
                sum(case when away_team_score = home_team_score then 1 else 0 end) as draws,
                count(*) as total_matches,
                avg(away_team_score) as avg_goals_for,
                avg(home_team_score) as avg_goals_against
            from fct_matches
            where home_team_score is not null and away_team_score is not null
            group by away_team_name
        )
        select
            team_name,
            sum(wins) as total_wins,
            sum(draws) as total_draws,
            sum(total_matches) as total_matches,
            avg(avg_goals_for) as avg_goals_for,
            avg(avg_goals_against) as avg_goals_against
        from team_stats
        group by team_name
    """
    
    df = pd.read_sql(query, engine)
    df['win_rate'] = df['total_wins'] / df['total_matches']
    df['matches_played'] = df['total_matches']
    
    return df.set_index('team_name')[['win_rate', 'avg_goals_for', 'avg_goals_against', 'matches_played']]


def predict_matchup(team_a: str, team_b: str, neutral_ground: bool = True) -> dict:
    """Prevê o confronto entre team_a e team_b.

    Retorna probabilidades de vitória/empate/derrota (perspectiva do
    team_a) e o placar mais provável segundo o modelo de gols esperados.
    """
    result_model, result_scaler, feature_columns, goals_model, goals_encoder = _load_artifacts()
    latest_stats = _latest_team_stats()

    def _get_stats(team_name: str) -> dict:
        if team_name in latest_stats.index:
            row = latest_stats.loc[team_name]
            return {
                "win_rate": row["win_rate"],
                "avg_goals_for": row["avg_goals_for"],
                "avg_goals_against": row["avg_goals_against"],
                "matches_played": row["matches_played"],
            }
        # Time sem histórico na base: usa valores neutros
        return {
            "win_rate": DEFAULT_WIN_RATE,
            "avg_goals_for": DEFAULT_GOALS_FOR,
            "avg_goals_against": DEFAULT_GOALS_AGAINST,
            "matches_played": 0,
        }

    stats_a = _get_stats(team_a)
    stats_b = _get_stats(team_b)

    features = pd.DataFrame([{
        "diff_win_rate": stats_a["win_rate"] - stats_b["win_rate"],
        "diff_avg_goals_for": stats_a["avg_goals_for"] - stats_b["avg_goals_for"],
        "diff_avg_goals_against": stats_a["avg_goals_against"] - stats_b["avg_goals_against"],
        "diff_experience": stats_a["matches_played"] - stats_b["matches_played"],
        "diff_is_host": 0,  # confronto hipotético: assume nenhum dos dois é o país-sede
    }])[feature_columns]

    features_scaled = result_scaler.transform(features)
    proba = result_model.predict_proba(features_scaled)[0]
    proba_by_class = dict(zip(result_model.classes_, proba))

    # Modelo de gols esperados (em campo neutro, is_home=0 pros dois)
    is_home_flag = 0 if neutral_ground else 1
    lambda_a = expected_goals(goals_model, goals_encoder, team_a, team_b, is_home=is_home_flag)
    lambda_b = expected_goals(goals_model, goals_encoder, team_b, team_a, is_home=0)

    score_matrix = scoreline_probability_matrix(lambda_a, lambda_b)
    most_likely_idx = np.unravel_index(np.argmax(score_matrix), score_matrix.shape)
    most_likely_score = f"{most_likely_idx[0]}x{most_likely_idx[1]}"
    most_likely_prob = float(score_matrix[most_likely_idx])

    return {
        "team_a": team_a,
        "team_b": team_b,
        "prob_team_a_win": round(float(proba_by_class.get("HOME_WIN", 0)), 3),
        "prob_draw": round(float(proba_by_class.get("DRAW", 0)), 3),
        "prob_team_b_win": round(float(proba_by_class.get("AWAY_WIN", 0)), 3),
        "expected_goals_team_a": round(lambda_a, 2),
        "expected_goals_team_b": round(lambda_b, 2),
        "most_likely_score": most_likely_score,
        "most_likely_score_probability": round(most_likely_prob, 3),
    }


def print_prediction(result: dict):
    print(f"\n⚽ {result['team_a']} vs {result['team_b']}")
    print("=" * 50)
    print(f"Vitória {result['team_a']}: {result['prob_team_a_win']:.1%}")
    print(f"Empate:              {result['prob_draw']:.1%}")
    print(f"Vitória {result['team_b']}: {result['prob_team_b_win']:.1%}")
    print(f"\nGols esperados: {result['team_a']} {result['expected_goals_team_a']:.2f} "
          f"x {result['expected_goals_team_b']:.2f} {result['team_b']}")
    print(f"Placar mais provável: {result['most_likely_score']} "
          f"(probabilidade: {result['most_likely_score_probability']:.1%})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print('Uso: python predict.py "Time A" "Time B"')
        sys.exit(1)

    team_a_arg, team_b_arg = sys.argv[1], sys.argv[2]
    prediction = predict_matchup(team_a_arg, team_b_arg)
    print_prediction(prediction)