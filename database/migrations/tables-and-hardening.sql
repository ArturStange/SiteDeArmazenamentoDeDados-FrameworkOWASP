--Execute como Superusuário
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- Revogar acesso público ao schema padrão (Hardening básico)
REVOKE ALL ON SCHEMA public FROM public;

-- Criação do usuário restrito para a aplicação web
CREATE ROLE web_app_user WITH LOGIN PASSWORD '@AaBbCc1234567890!@#$%*0987654321cCbBaA@';

-- Criação de um schema isolado para a aplicação
CREATE SCHEMA app_schema AUTHORIZATION postgres;

-- Conceder apenas o uso do schema para o usuário da aplicação
GRANT USAGE ON SCHEMA app_schema TO web_app_user;

SET search_path TO app_schema;

-- Tabela de Papéis (RBAC)
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Identidade Administrativa/Usuários
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- O PHP vai inserir o hash Argon2id aqui
    mfa_secret VARCHAR(255), -- Para armazenar a semente do TOTP
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Exemplo para Dados Críticos
CREATE TABLE sensitive_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    document_title VARCHAR(100) NOT NULL,
    encrypted_payload TEXT NOT NULL, -- O PHP deve enviar o dado já criptografado (AES-256-GCM)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Auditoria (Append-Only)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(255) DEFAULT current_user, 
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Função de Trigger genérica para capturar mudanças
CREATE OR REPLACE FUNCTION log_table_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (table_name, action, record_id, old_data)
        VALUES (TG_TABLE_NAME::TEXT, TG_OP, OLD.id, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (table_name, action, record_id, old_data, new_data)
        VALUES (TG_TABLE_NAME::TEXT, TG_OP, NEW.id, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (table_name, action, record_id, new_data)
        VALUES (TG_TABLE_NAME::TEXT, TG_OP, NEW.id, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- Roda com privilégios de quem criou a função (postgres)

-- Aplicando o Trigger nas tabelas críticas
CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_table_changes();

CREATE TRIGGER sensitive_records_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON sensitive_records
FOR EACH ROW EXECUTE FUNCTION log_table_changes();

-- Ativar RLS nas tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensitive_records ENABLE ROW LEVEL SECURITY;

-- Política: Usuários só podem ver e editar seu próprio registro na tabela 'users'
CREATE POLICY users_isolation_policy ON users
    USING (id = current_setting('app.current_user_id', true)::UUID);

-- Política: Usuários só podem ver e editar seus próprios registros críticos
CREATE POLICY sensitive_records_isolation_policy ON sensitive_records
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- Conceder permissões operacionais estritas ao usuário web
GRANT SELECT ON app_schema.roles TO web_app_user;
GRANT SELECT, INSERT, UPDATE ON app_schema.users TO web_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_schema.sensitive_records TO web_app_user;

-- Nunca UPDATE ou DELETE. Isso garante a imutabilidade pelo lado do cliente conectado.
GRANT INSERT ON app_schema.audit_logs TO web_app_user;