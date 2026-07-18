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
GRANT ALL PRIVILEGES ON *.* TO 'dbt_user'@'%';
FLUSH PRIVILEGES;

-- =====================================================
-- Status
-- =====================================================
SELECT 'Copa Challenger - schemas criados com sucesso!' AS status;
SELECT 'Aguardando análise dos CSVs para criar tabelas raw...' AS proximo_passo;