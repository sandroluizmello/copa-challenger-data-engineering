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

    NOTA TÉCNICA: o pacote `kaggle` se autentica automaticamente no
    momento do `import kaggle`, usando a variável KAGGLE_API_TOKEN caso
    ela já esteja no ambiente. Por isso ela precisa estar setada
    ANTES do import — é o que essa função garante.

    IMPORTANTE: não usamos mais o binário `kaggle` via subprocess.
    O comando `datasets download` do CLI passa por um client interno
    (`build_kaggle_client`) que só lê credenciais no formato legado
    (`username` + `key`) e NÃO reconhece KAGGLE_API_TOKEN — é um bug
    conhecido do próprio kaggle-cli (o token é consumido no
    `kaggle/__init__.py`, mas esse client novo nunca olha pra ele).
    Chamando a lib Python diretamente (`kaggle.api`), usamos a
    instância que já vem autenticada corretamente pelo token.
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

    # O import precisa vir DEPOIS de carregar_configuracoes(), porque
    # é no momento do import que o pacote lê KAGGLE_API_TOKEN e
    # autentica `kaggle.api` automaticamente.
    import kaggle
    api = kaggle.api

    api.dataset_download_files(
        DATASET,
        path=str(DATA_DIR),
        unzip=True,
    )

    print(f"✅ Download e descompactação concluídos em {DATA_DIR}")

    print("\n📂 Arquivos disponíveis:")
    for arquivo in DATA_DIR.glob("*.csv"):
        size_mb = arquivo.stat().st_size / (1024 * 1024)
        print(f"   • {arquivo.name} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()