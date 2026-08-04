import plotly.express as px
import streamlit as st

from db import run_query

st.set_page_config(page_title="Artilheiros", page_icon="⚽", layout="wide")
st.title("⚽ Ranking de Artilheiros")

df = run_query("SELECT * FROM analytics_top_scorers ORDER BY total_goals DESC")

if df.empty:
    st.warning("Nenhum dado encontrado. Verifique se `dbt run` já foi executado.")
    st.stop()

top_n = st.slider("Top N artilheiros", 5, min(50, len(df)), min(20, len(df)))
df_top = df.head(top_n)

fig = px.bar(
    df_top,
    x="total_goals",
    y="scorer_name",
    orientation="h",
    color="team_name",
    title=f"Top {top_n} Artilheiros da História",
    labels={"total_goals": "Gols", "scorer_name": "Jogador", "team_name": "Seleção"},
)
fig.update_layout(yaxis={"categoryorder": "total ascending"})
st.plotly_chart(fig, use_container_width=True)

st.caption(
    "⚠️ Nomes extraídos por parsing de texto das timelines — grafias "
    "diferentes do mesmo jogador podem aparecer como registros separados."
)

st.subheader("📋 Tabela Completa")
st.dataframe(df, use_container_width=True, hide_index=True)
