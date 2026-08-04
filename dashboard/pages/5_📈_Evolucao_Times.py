import plotly.express as px
import streamlit as st

from db import run_query

st.set_page_config(page_title="Evolução dos Times", page_icon="📈", layout="wide")
st.title("📈 Evolução de Desempenho ao Longo do Tempo")
st.caption("Compara a performance de cada seleção entre a Copa atual e a anterior em que participou.")

df = run_query(
    "SELECT * FROM analytics_team_evolution_over_time ORDER BY team_name, world_cup_id"
)

if df.empty:
    st.warning("Nenhum dado encontrado. Verifique se `dbt run` já foi executado.")
    st.stop()

teams = sorted(df["team_name"].unique())
default_teams = teams[:3] if len(teams) >= 3 else teams
selected = st.multiselect("Selecione as seleções para comparar", teams, default=default_teams)

if not selected:
    st.info("Selecione ao menos uma seleção para ver o gráfico.")
    st.stop()

df_filtered = df[df["team_name"].isin(selected)]

fig = px.line(
    df_filtered,
    x="world_cup_id",
    y="win_rate_pct",
    color="team_name",
    markers=True,
    title="Evolução da Taxa de Vitória por Copa",
    labels={
        "world_cup_id": "Copa",
        "win_rate_pct": "Taxa de Vitória (%)",
        "team_name": "Seleção",
    },
)
st.plotly_chart(fig, use_container_width=True)

fig2 = px.line(
    df_filtered,
    x="world_cup_id",
    y="goal_difference",
    color="team_name",
    markers=True,
    title="Evolução do Saldo de Gols por Copa",
    labels={
        "world_cup_id": "Copa",
        "goal_difference": "Saldo de Gols",
        "team_name": "Seleção",
    },
)
st.plotly_chart(fig2, use_container_width=True)

st.subheader("🏷️ Tendência (última Copa vs. anterior)")
trend_summary = (
    df_filtered.sort_values("world_cup_id")
    .groupby("team_name")
    .tail(1)[["team_name", "world_cup_id", "trend_label", "win_rate_pct"]]
)
st.dataframe(trend_summary, use_container_width=True, hide_index=True)

st.subheader("📋 Tabela Completa")
st.dataframe(df_filtered, use_container_width=True, hide_index=True)
