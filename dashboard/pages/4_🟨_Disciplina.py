import plotly.express as px
import streamlit as st

from db import run_query

st.set_page_config(page_title="Disciplina", page_icon="🟨", layout="wide")
st.title("🟨🟥 Disciplina por Seleção")

df = run_query("SELECT * FROM analytics_team_discipline ORDER BY total_cards DESC")

if df.empty:
    st.warning("Nenhum dado encontrado. Verifique se `dbt run` já foi executado.")
    st.stop()

top_n = st.slider("Top N seleções", 5, min(30, len(df)), min(15, len(df)))
df_top = df.head(top_n)

fig = px.bar(
    df_top,
    x="team_name",
    y=["yellow_cards", "red_cards_direct", "second_yellow_cards"],
    title="Cartões por Tipo",
    labels={
        "value": "Quantidade",
        "team_name": "Seleção",
        "variable": "Tipo de Cartão",
    },
    color_discrete_map={
        "yellow_cards": "#FFD700",
        "red_cards_direct": "#DC143C",
        "second_yellow_cards": "#FF8C00",
    },
)
st.plotly_chart(fig, use_container_width=True)

col1, col2 = st.columns(2)
with col1:
    fig2 = px.bar(
        df_top,
        x="avg_cards_per_match",
        y="team_name",
        orientation="h",
        title="Média de Cartões por Partida",
        labels={"avg_cards_per_match": "Cartões/Partida", "team_name": "Seleção"},
    )
    fig2.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig2, use_container_width=True)

with col2:
    fig3 = px.bar(
        df_top,
        x="avg_expulsions_per_match",
        y="team_name",
        orientation="h",
        title="Média de Expulsões por Partida",
        labels={"avg_expulsions_per_match": "Expulsões/Partida", "team_name": "Seleção"},
        color_discrete_sequence=["#DC143C"],
    )
    fig3.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig3, use_container_width=True)

st.subheader("📋 Tabela Completa")
st.dataframe(df, use_container_width=True, hide_index=True)
