import plotly.express as px
import streamlit as st

from db import run_query

st.set_page_config(page_title="Histórico das Copas", page_icon="🌍", layout="wide")
st.title("🌍 Histórico das Copas do Mundo")

# Usa analytics_world_cup_summary (tem avg_goals_per_match, total_attendance)
df = run_query(
    "SELECT * FROM analytics_world_cup_summary ORDER BY world_cup_id"
)

if df.empty:
    st.warning("Nenhum dado encontrado. Verifique se `dbt run` já foi executado.")
    st.stop()

fig = px.line(
    df,
    x="world_cup_id",
    y="avg_goals_per_match",
    markers=True,
    title="Média de Gols por Partida ao Longo das Copas",
    labels={"world_cup_id": "Copa", "avg_goals_per_match": "Média de Gols/Partida"},
)
st.plotly_chart(fig, use_container_width=True)

col1, col2 = st.columns(2)

with col1:
    # Pega dados de campeões de analytics_world_cup_champions_history
    champions_df = run_query(
        "SELECT champion_country FROM analytics_world_cup_champions_history ORDER BY world_cup_id"
    )
    if not champions_df.empty:
        titles = champions_df["champion_country"].value_counts().reset_index()
        titles.columns = ["Seleção", "Títulos"]
        fig2 = px.bar(
            titles,
            x="Títulos",
            y="Seleção",
            orientation="h",
            title="Títulos por Seleção",
            color="Títulos",
            color_continuous_scale="YlOrRd",
        )
        fig2.update_layout(yaxis={"categoryorder": "total ascending"}, coloraxis_showscale=False)
        st.plotly_chart(fig2, use_container_width=True)

with col2:
    fig3 = px.bar(
        df,
        x="world_cup_id",
        y="total_attendance",
        title="Público Total por Edição",
        labels={"world_cup_id": "Copa", "total_attendance": "Público Total"},
    )
    st.plotly_chart(fig3, use_container_width=True)

st.subheader("📋 Detalhes por Edição")
st.dataframe(df, use_container_width=True, hide_index=True)