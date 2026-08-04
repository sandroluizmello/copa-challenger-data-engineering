import streamlit as st

from db import run_query

st.set_page_config(
    page_title="Copa Challenger - Dashboard",
    page_icon="⚽",
    layout="wide",
)

st.title("⚽ Copa Challenger - Dashboard")
st.caption("Análise histórica das Copas do Mundo FIFA — Star Schema + dbt")


def _fmt_int(value) -> str:
    """Formata número inteiro com separador de milhar no padrão brasileiro."""
    return f"{int(value):,}".replace(",", ".")


kpis_df = run_query("SELECT * FROM analytics_dashboard_main_kpis")

if kpis_df.empty:
    st.warning("Nenhum dado encontrado em `analytics_dashboard_main_kpis`. "
               "Verifique se `dbt run` já foi executado.")
    st.stop()

kpis = kpis_df.iloc[0]

col1, col2, col3, col4 = st.columns(4)
col1.metric("🏆 Copas do Mundo", _fmt_int(kpis["total_world_cups"]))
col2.metric("⚽ Partidas", _fmt_int(kpis["total_matches"]))
col3.metric("🥅 Gols Marcados", _fmt_int(kpis["total_goals"]))
col4.metric("📊 Média Gols/Partida", f"{kpis['avg_goals_per_match']:.2f}")

col5, col6, col7, col8 = st.columns(4)
col5.metric("👥 Público Total", _fmt_int(kpis["total_attendance"]))
col6.metric("👥 Média Público/Partida", _fmt_int(kpis["avg_attendance_per_match"]))
col7.metric(
    "🌍 Mais Participações",
    kpis["team_most_appearances"],
    f"{int(kpis['most_appearances_count'])} copas",
)
col8.metric(
    "👑 Mais Títulos",
    kpis["team_most_titles"],
    f"{int(kpis['most_titles_count'])} títulos",
)

st.divider()

col_scorer, col_teams = st.columns(2)
with col_scorer:
    st.subheader("⚽ Maior Artilheiro da História")
    st.metric(kpis["top_scorer_name"], f"{int(kpis['top_scorer_goals'])} gols")

with col_teams:
    st.subheader("🌎 Seleções no Histórico")
    st.metric("Total de seleções que já disputaram uma Copa", _fmt_int(kpis["total_teams"]))

st.divider()
st.info(
    "👈 Use o menu à esquerda para navegar entre as análises: "
    "**Desempenho por Time**, **Histórico das Copas**, **Artilheiros**, "
    "**Disciplina** e **Evolução dos Times**."
)
