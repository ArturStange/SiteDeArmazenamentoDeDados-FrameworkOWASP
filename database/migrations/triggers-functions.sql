SET search_path TO app_schema;

-- 1. Criação da Função do Gatilho (A Lógica de Captura).
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Aplicação dos Gatilhos nas Tabelas Críticas

-- Gatilho para a tabela de Usuários
CREATE OR REPLACE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_table_changes();

CREATE OR REPLACE TRIGGER sensitive_records_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON sensitive_records
FOR EACH ROW EXECUTE FUNCTION log_table_changes();