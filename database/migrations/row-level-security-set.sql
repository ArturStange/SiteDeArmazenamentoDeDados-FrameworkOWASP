SET search_path TO app_schema;

-- 1. Ativar RLS nas tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensitive_records ENABLE ROW LEVEL SECURITY;

-- 2. Políticas de Isolamento (RLS)
DROP POLICY IF EXISTS users_isolation_policy ON users;
CREATE POLICY users_isolation_policy ON users
    USING (id = current_setting('app.current_user_id', true)::UUID);

-- Usuários só podem ver e editar seus próprios registros críticos
DROP POLICY IF EXISTS sensitive_records_isolation_policy ON sensitive_records;
CREATE POLICY sensitive_records_isolation_policy ON sensitive_records
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- 3. Definição Final de Permissões (Privilégio Mínimo)
-- Revogando acessos amplos por segurança antes de conceder os específicos
REVOKE ALL ON ALL TABLES IN SCHEMA app_schema FROM web_app_user;

-- Conceder permissões operacionais estritas ao usuário web
GRANT SELECT ON app_schema.roles TO web_app_user;
GRANT SELECT, INSERT, UPDATE ON app_schema.users TO web_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_schema.sensitive_records TO web_app_user;

GRANT INSERT ON app_schema.audit_logs TO web_app_user;