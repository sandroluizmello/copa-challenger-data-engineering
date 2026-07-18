FROM python:3.10-slim

# Instala dependências do sistema necessárias para compilar pacotes se necessário
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /workspace

# Copia o requirements.txt da raiz do projeto (graças ao contexto: .. no compose)
COPY requirements.txt .

# Instala as dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Instala especificamente o adaptador do dbt para MySQL
RUN pip install --no-cache-dir dbt-core dbt-mysql

# Mantém o container aberto em modo de espera
CMD ["bash"]