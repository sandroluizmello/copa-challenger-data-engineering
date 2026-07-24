FROM python:3.10-slim

# Instala dependências do sistema necessárias para compilar pacotes se necessário
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Cria usuário não-root para rodar a aplicação (boa prática de segurança)
RUN useradd -m -u 1000 dbtuser

# Define o diretório de trabalho dentro do container
WORKDIR /workspace

# Copia o requirements.txt da raiz do projeto (graças ao contexto: .. no compose)
COPY requirements.txt .

# Instala as dependências do Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Instala especificamente o adaptador do dbt para MySQL
RUN pip install --no-cache-dir dbt-core dbt-mysql

# Ajusta o dono da pasta de trabalho para o usuário não-root
RUN chown -R dbtuser:dbtuser /workspace

# A partir daqui, o container roda com um usuário sem privilégios de root
USER dbtuser

# Mantém o container aberto em modo de espera
CMD ["bash"]