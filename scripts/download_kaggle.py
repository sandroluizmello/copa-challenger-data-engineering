import os
import shutil
from pathlib import Path
from dotenv import load_dotenv

DATASET = "piterfm/fifa-football-world-cup"
DATA_DIR = Path("data/raw")

# ============================================================
# PASSO 1: CARREGAR AS CONFIGURAÇÕES ANTES DO KAGGLE
# ============================================================
def carregar_configuracoes():
    """Carrega as variáveis de ambiente do arquivo .env."""
    env_path = Path(".env")
    
    load_dotenv(dotenv_path=env_path)
    
    # Coleta o token e garante que esteja disponível para o SDK do Kaggle
    token = os.getenv('KAGGLE_API_TOKEN')
    if not token:
        raise EnvironmentError(
            "❌ KAGGLE_API_TOKEN não configurado!\n"
            "Configure no .env ou como variável de ambiente."
        )
    
    # Injeta no environment para o SDK do Kaggle usar
    os.environ['KAGGLE_API_TOKEN'] = token

# Executa o carregamento das variáveis ANTES de importar Kaggle
carregar_configuracoes()

# ============================================================
# PASSO 2: SÓ AGORA IMPORTAMOS O KAGGLE (com token já disponível)
# ============================================================
from kaggle.api.kaggle_api_extended import KaggleApi


def main():
    """Download e descompactação do dataset Copa do Mundo do Kaggle."""
    
    # Criar diretório se não existir
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    try:
        print(f"📥 Baixando dataset '{DATASET}' do Kaggle...")
        
        # Instanciar e autenticar com o Kaggle API
        api = KaggleApi()
        api.authenticate()
        print("✅ Autenticado no Kaggle")
        
        # Fazer download e descompactar
        api.dataset_download_files(DATASET, path=str(DATA_DIR), unzip=True)
        print(f"✅ Download e descompactação concluídos em {DATA_DIR}")
        
        # Listar arquivos baixados
        print("\n📂 Arquivos disponíveis:")
        for arquivo in DATA_DIR.glob("*.csv"):
            size_mb = arquivo.stat().st_size / (1024 * 1024)
            print(f"   • {arquivo.name} ({size_mb:.2f} MB)")
        
    except Exception as e:
        print(f"❌ Erro durante o download: {e}")
        raise


if __name__ == "__main__":
    main()