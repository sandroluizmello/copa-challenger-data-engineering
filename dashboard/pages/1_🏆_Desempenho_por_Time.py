import plotly.express as px
import streamlit as st

from db import run_query

st.set_page_config(page_title="Desempenho por Time", page_icon="🏆", layout="wide")
st.title("🏆 Desempenho Histórico por Seleção")
st.caption("Agrega o desempenho de cada seleção em TODAS as Copas que disputou.")

df = run_query("SELECT * FROM analytics_team_overall_performance ORDER BY win_rate_pct DESC")

if df.empty:
    st.warning("Nenhum dado encontrado. Verifique se `dbt run` já foi executado.")
    st.stop()

min_matches = st.slider(
    "Filtrar: mínimo de partidas jogadas",
    min_value=1,
    max_value=int(df["total_matches"].max()),
    value=10,
)
df_filtered = df[df["total_matches"] >= min_matches]

st.caption(f"Mostrando {len(df_filtered)} de {len(df)} seleções.")

col1, col2 = st.columns(2)

with col1:
    top_n = st.slider("Top N por taxa de vitória", 5, min(30, len(df_filtered)), min(15, len(df_filtered)))
    df_top = df_filtered.head(top_n)
    fig = px.bar(
        df_top,
        x="win_rate_pct",
        y="team_name",
        orientation="h",
        title="Taxa de Vitória (%)",
        labels={"win_rate_pct": "Taxa de Vitória (%)", "team_name": "Seleção"},
        color="win_rate_pct",
        color_continuous_scale="Blues",
    )
    fig.update_layout(yaxis={"categoryorder": "total ascending"}, coloraxis_showscale=False)
    st.plotly_chart(fig, use_container_width=True)

with col2:
    fig2 = px.scatter(
        df_filtered,
        x="avg_goals_for_per_match",
        y="avg_goals_against_per_match",
        size="total_matches",
        color="win_rate_pct",
        hover_name="team_name",
        title="Ataque vs Defesa (tamanho = partidas, cor = taxa de vitória)",
        labels={
            "avg_goals_for_per_match": "Gols marcados / partida",
            "avg_goals_against_per_match": "Gols sofridos / partida",
            "win_rate_pct": "Taxa de Vitória (%)",
        },
        color_continuous_scale="RdYlGn",
    )
    st.plotly_chart(fig2, use_container_width=True)

st.subheader("📋 Tabela Completa")
st.dataframe(df_filtered, use_container_width=True, hide_index=True)
