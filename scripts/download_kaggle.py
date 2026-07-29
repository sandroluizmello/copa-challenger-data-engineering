import os
import sys
import subprocess
from pathlib import Path
from dotenv import load_dotenv

DATASET = "piterfm/fifa-football-world-cup"
DATA_DIR = Path("data/raw")

def carregar_configuracoes():
    """Garante a leitura do token de API do Kaggle."""
    env_path = Path(".env")
    load_dotenv(dotenv_path=env_path)

    token = os.getenv('KAGGLE_API_TOKEN')
    if not token:
        raise EnvironmentError(
            "❌ KAGGLE_API_TOKEN não configurado!\n"
            "Configure no .env (local) ou como secret do repositório (CI/CD)."
        )
    os.environ['KAGGLE_API_TOKEN'] = token

    # Fallback de compatibilidade para a lib 'kaggle' legada
    kaggle_dir = Path.home() / ".kaggle"
    kaggle_dir.mkdir(parents=True, exist_ok=True)
    
    # Garante a criação do access_token (novo formato)
    access_token_file = kaggle_dir / "access_token"
    if not access_token_file.exists():
        access_token_file.write_text(token)
        access_token_file.chmod(0o600)

def main():
    """Download e descompactação do dataset Copa do Mundo do Kaggle."""
    carregar_configuracoes()
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print(f"📥 Baixando dataset '{DATASET}' do Kaggle...")

    kaggle_bin = Path(sys.executable).parent / "kaggle"

    # Injeta a variável explicitamente na execução do subprocesso
    env = os.environ.copy()
    env["KAGGLE_API_TOKEN"] = os.getenv("KAGGLE_API_TOKEN", "")

    subprocess.run(
        [
            str(kaggle_bin), "datasets", "download",
            "-d", DATASET,
            "-p", str(DATA_DIR),
            "--unzip",
        ],
        check=True,
        env=env,
    )

    print(f"✅ Download e descompactação concluídos em {DATA_DIR}")

    print("\n📂 Arquivos disponíveis:")
    for arquivo in DATA_DIR.glob("*.csv"):
        size_mb = arquivo.stat().st_size / (1024 * 1024)
        print(f"   • {arquivo.name} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    main()