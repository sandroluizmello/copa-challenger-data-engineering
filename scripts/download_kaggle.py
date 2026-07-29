import os
import sys
import subprocess
from pathlib import Path
from dotenv import load_dotenv

DATASET = "piterfm/fifa-football-world-cup"
DATA_DIR = Path("data/raw")

# ============================================================
# PASSO 1: CARREGAR O TOKEN ANTES DE CHAMAR O KAGGLE
# ============================================================
def carregar_configuracoes():
    """Carrega KAGGLE_API_TOKEN do .env (local) ou do ambiente (CI/CD).

    NOTA TÉCNICA: usamos o CLI do kaggle via subprocess (não a lib
    Python kaggle.api.kaggle_api_extended diretamente), porque o
    suporte ao novo API Token (KAGGLE_API_TOKEN) é documentado
    oficialmente para o CLI (>= 1.8.0), e chamar o binário evita
    inconsistências entre versões da lib Python.
    """
    env_path = Path(".env")
    load_dotenv(dotenv_path=env_path)

    token = os.getenv('KAGGLE_API_TOKEN')
    if not token:
        raise EnvironmentError(
            "❌ KAGGLE_API_TOKEN não configurado!\n"
            "Configure no .env (local) ou como secret do repositório (CI/CD).\n"
            "Gere em: https://www.kaggle.com/settings > API Tokens > Generate New Token"
        )
    os.environ['KAGGLE_API_TOKEN'] = token


def main():
    """Download e descompactação do dataset Copa do Mundo do Kaggle."""

    carregar_configuracoes()
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print(f"📥 Baixando dataset '{DATASET}' do Kaggle...")

    # Usa o binário 'kaggle' instalado no MESMO venv/ambiente do
    # interpretador Python que está rodando este script (evita depender
    # do PATH do sistema, que não inclui automaticamente venvs isolados).
    kaggle_bin = Path(sys.executable).parent / "kaggle"

    subprocess.run(
        [
            str(kaggle_bin), "datasets", "download",
            "-d", DATASET,
            "-p", str(DATA_DIR),
            "--unzip",
        ],
        check=True,
    )

    print(f"✅ Download e descompactação concluídos em {DATA_DIR}")

    print("\n📂 Arquivos disponíveis:")
    for arquivo in DATA_DIR.glob("*.csv"):
        size_mb = arquivo.stat().st_size / (1024 * 1024)
        print(f"   • {arquivo.name} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()