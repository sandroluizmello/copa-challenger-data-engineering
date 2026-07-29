-- =====================================================
-- Copa Challenger - Script de Inicialização do MySQL
-- Executado automaticamente na primeira subida do container
-- 
-- Cria apenas os schemas. As tabelas raw serão criadas
-- após análise dos CSVs do Kaggle.
-- =====================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- =====================================================
-- Schemas (arquitetura ELT)
-- =====================================================
CREATE SCHEMA IF NOT EXISTS raw;      -- Dados brutos (como chegam)
CREATE SCHEMA IF NOT EXISTS staging;  -- Limpeza e padronização
CREATE SCHEMA IF NOT EXISTS marts;    -- Modelos finais (fatos e dimensões)

-- =====================================================
-- Permissões
-- =====================================================
-- Cria o usuário explicitamente (idempotente) para que o script
-- funcione tanto localmente (onde o container MySQL já pode ter
-- criado o usuário via MYSQL_USER/MYSQL_PASSWORD) quanto no CI
-- (onde só MYSQL_ROOT_PASSWORD é definido e o usuário não existe
-- ainda). Sem isso, o GRANT falha com erro 1410 no MySQL 8.0,
-- que não permite mais criar usuário implicitamente via GRANT.
CREATE USER IF NOT EXISTS 'dbt_user'@'%' IDENTIFIED BY 'dbt_password_123';
GRANT ALL PRIVILEGES ON *.* TO 'dbt_user'@'%';
FLUSH PRIVILEGES;

-- =====================================================
-- Status
-- =====================================================
SELECT 'Copa Challenger - schemas criados com sucesso!' AS status;
SELECT 'Aguardando análise dos CSVs para criar tabelas raw...' AS proximo_passo;