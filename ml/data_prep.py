"""
Preparação de dados para o modelo preditivo.

PRINCÍPIO CENTRAL (evitar data leakage):
Para prever o resultado de uma partida, só podemos usar estatísticas dos
times ANTES daquela partida acontecer. Se usássemos o histórico completo
(incluindo jogos futuros em relação à partida analisada), o modelo teria
acesso a informação que não existiria no momento real da previsão -
isso infla a performance de forma artificial e o modelo não funcionaria
para jogos futuros de verdade.

Estratégia: para cada time, calculamos estatísticas EXPANDING (cumulativas)
ordenadas por data, e usamos um shift(1) para garantir que a partida atual
nunca contribui para as próprias features.
"""

import pandas as pd

from db import get_engine

# Times sem nenhum histórico anterior (primeira partida da carreira) ficam
# sem médias válidas. Preenchemos com esses valores "neutros" em vez de
# descartar a partida inteira (senão perderíamos toda a Copa de 1930).
DEFAULT_WIN_RATE = 0.33  # ~1/3 (empate/vitória/derrota equiprováveis)
DEFAULT_GOALS_FOR = 1.2
DEFAULT_GOALS_AGAINST = 1.2


def _load_raw_matches() -> pd.DataFrame:
    engine = get_engine()
    query = """
        select
            m.match_id,
            m.world_cup_id,
            m.match_date,
            m.home_team_id,
            m.home_team_name,
            m.away_team_id,
            m.away_team_name,
            m.home_team_score,
            m.away_team_score,
            wc.host_country
        from fct_matches m
        left join dim_world_cups wc on wc.world_cup_id = m.world_cup_id
        where m.home_team_score is not null
          and m.away_team_score is not null
        order by m.match_date
    """
    return pd.read_sql(query, engine)


def _build_team_match_history(matches: pd.DataFrame) -> pd.DataFrame:
    """Transforma o dataframe wide (1 linha/partida) em long (1 linha por
    time por partida), com o resultado da perspectiva daquele time."""

    home = matches.rename(
        columns={
            "home_team_id": "team_id",
            "home_team_name": "team_name",
            "away_team_id": "opponent_id",
            "away_team_name": "opponent_name",
            "home_team_score": "goals_for",
            "away_team_score": "goals_against",
        }
    ).copy()
    home["is_home"] = 1

    away = matches.rename(
        columns={
            "away_team_id": "team_id",
            "away_team_name": "team_name",
            "home_team_id": "opponent_id",
            "home_team_name": "opponent_name",
            "away_team_score": "goals_for",
            "home_team_score": "goals_against",
        }
    ).copy()
    away["is_home"] = 0

    cols = [
        "match_id", "world_cup_id", "match_date", "team_id", "team_name",
        "opponent_id", "opponent_name", "goals_for", "goals_against",
        "is_home", "host_country",
    ]
    long_df = pd.concat([home[cols], away[cols]], ignore_index=True)

    long_df["result_points"] = long_df.apply(
        lambda r: 3 if r["goals_for"] > r["goals_against"]
        else (1 if r["goals_for"] == r["goals_against"] else 0),
        axis=1,
    )
    long_df["is_win"] = (long_df["goals_for"] > long_df["goals_against"]).astype(int)

    return long_df.sort_values(["team_id", "match_date"])


def _add_pre_match_rolling_stats(long_df: pd.DataFrame) -> pd.DataFrame:
    """Calcula, para cada time, médias EXPANDING deslocadas em 1 partida
    (ou seja: 'como o time vinha jogando ANTES desta partida')."""

    long_df = long_df.sort_values(["team_id", "match_date"]).copy()
    grouped = long_df.groupby("team_id")

    # shift(1) garante que a partida atual não entra na própria média
    long_df["matches_played_before"] = grouped.cumcount()
    long_df["win_rate_before"] = grouped["is_win"].transform(
        lambda s: s.shift(1).expanding().mean()
    )
    long_df["avg_goals_for_before"] = grouped["goals_for"].transform(
        lambda s: s.shift(1).expanding().mean()
    )
    long_df["avg_goals_against_before"] = grouped["goals_against"].transform(
        lambda s: s.shift(1).expanding().mean()
    )

    long_df["win_rate_before"] = long_df["win_rate_before"].fillna(DEFAULT_WIN_RATE)
    long_df["avg_goals_for_before"] = long_df["avg_goals_for_before"].fillna(DEFAULT_GOALS_FOR)
    long_df["avg_goals_against_before"] = long_df["avg_goals_against_before"].fillna(DEFAULT_GOALS_AGAINST)

    return long_df


def build_training_dataset() -> pd.DataFrame:
    """Monta o dataset final, 1 linha por partida, com features de
    pré-jogo para os dois times e o rótulo (resultado da partida).
    """
    matches = _load_raw_matches()
    long_df = _build_team_match_history(matches)
    long_df = _add_pre_match_rolling_stats(long_df)

    stats_cols = [
        "match_id", "team_id", "matches_played_before",
        "win_rate_before", "avg_goals_for_before", "avg_goals_against_before",
    ]
    home_stats = long_df[long_df["is_home"] == 1][stats_cols].rename(
        columns=lambda c: f"home_{c}" if c not in ("match_id",) else c
    )
    away_stats = long_df[long_df["is_home"] == 0][stats_cols].rename(
        columns=lambda c: f"away_{c}" if c not in ("match_id",) else c
    )

    features = matches.merge(home_stats, on="match_id").merge(away_stats, on="match_id")

    # Feature de "mando de campo real": o time é o país-sede daquela Copa?
    features["home_is_host"] = (
        features["home_team_name"] == features["host_country"]
    ).astype(int)
    features["away_is_host"] = (
        features["away_team_name"] == features["host_country"]
    ).astype(int)

    # Features de diferença (mais informativas para o modelo que valores
    # absolutos separados, e reduzem dimensionalidade)
    features["diff_win_rate"] = features["home_win_rate_before"] - features["away_win_rate_before"]
    features["diff_avg_goals_for"] = features["home_avg_goals_for_before"] - features["away_avg_goals_for_before"]
    features["diff_avg_goals_against"] = features["home_avg_goals_against_before"] - features["away_avg_goals_against_before"]
    features["diff_experience"] = features["home_matches_played_before"] - features["away_matches_played_before"]
    features["diff_is_host"] = features["home_is_host"] - features["away_is_host"]

    # Rótulo: resultado da partida (da perspectiva do time da casa)
    def _label(row):
        if row["home_team_score"] > row["away_team_score"]:
            return "HOME_WIN"
        elif row["home_team_score"] < row["away_team_score"]:
            return "AWAY_WIN"
        return "DRAW"

    features["result"] = features.apply(_label, axis=1)

    return features


FEATURE_COLUMNS = [
    "diff_win_rate",
    "diff_avg_goals_for",
    "diff_avg_goals_against",
    "diff_experience",
    "diff_is_host",
]


if __name__ == "__main__":
    df = build_training_dataset()
    print(f"✅ Dataset construído: {len(df)} partidas, {df['result'].nunique()} classes")
    print(df["result"].value_counts(normalize=True).round(3))
    print("\nAmostra das features:")
    print(df[FEATURE_COLUMNS + ["result"]].head(10))