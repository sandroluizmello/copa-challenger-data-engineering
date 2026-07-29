import os
from pathlib import Path
from dotenv import load_dotenv

DATASET = "piterfm/fifa-football-world-cup"
DATA_DIR = Path("data/raw")

# ============================================================
# PASSO 1: CARREGAR O TOKEN ANTES DE IMPORTAR O KAGGLE
# ============================================================
def carregar_configuracoes():
    """Carrega KAGGLE_API_TOKEN do .env (local) ou do ambiente (CI/CD).

    Este é o método de API Token novo do Kaggle (recomendado oficialmente
    sobre o método legado de username+key). Veja:
    https://www.kaggle.com/settings > API Tokens
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

# Executa ANTES de importar o Kaggle (o import já autentica automaticamente)
carregar_configuracoes()

# ============================================================
# PASSO 2: IMPORTAR O KAGGLE (autentica sozinho, consumindo o token)
# ============================================================
# IMPORTANTE: `import kaggle` já autentica automaticamente usando
# KAGGLE_API_TOKEN e remove o token do ambiente em seguida. Por isso,
# usamos a instância já pronta `kaggle.api` — criar uma NOVA instância
# KaggleApi() e chamar .authenticate() de novo falha, pois o token já
# foi consumido pelo import (bug conhecido: Kaggle/kaggle-cli#882).
import kaggle


def main():
    """Download e descompactação do dataset Copa do Mundo do Kaggle."""

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    try:
        print(f"📥 Baixando dataset '{DATASET}' do Kaggle...")

        api = kaggle.api  # já autenticado no momento do import, não recriar

        api.dataset_download_files(DATASET, path=str(DATA_DIR), unzip=True)
        print(f"✅ Download e descompactação concluídos em {DATA_DIR}")

        print("\n📂 Arquivos disponíveis:")
        for arquivo in DATA_DIR.glob("*.csv"):
            size_mb = arquivo.stat().st_size / (1024 * 1024)
            print(f"   • {arquivo.name} ({size_mb:.2f} MB)")

    except Exception as e:
        print(f"❌ Erro durante o download: {e}")
        raise


if __name__ == "__main__":
    main()