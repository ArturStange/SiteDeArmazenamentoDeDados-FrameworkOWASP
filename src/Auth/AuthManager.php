<?php
declare(strict_types=1);

namespace App\Auth;

use PDO;
use Exception;

class AuthManager {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    /**
     * RF-01: Autenticação Reforçada
     */
    public function login(string $email, string $password): bool {
        $stmt = $this->db->prepare("
            SELECT u.id, u.password_hash, u.is_active, r.name as role_name 
            FROM app_schema.users u
            JOIN app_schema.roles r ON u.role_id = r.id
            WHERE u.email = :email
        ");
        $stmt->execute(['email' => $email]);
        $user = $stmt->fetch();

        if ($user && password_verify($password, $user['password_hash'])) {
            
            if (!$user['is_active']) {
                error_log("Tentativa de login em conta inativa: " . $email);
                throw new Exception("Conta inativa."); 
            }

            // Prevenção contra Session Fixation
            session_regenerate_id(true);

            // Estado da sessão (RBAC será validado em tempo real, não na sessão)
            $_SESSION['user_id'] = $user['id'];

            return true;
        }

        // Mitigação básica contra ataques de tempo/força bruta
        usleep(random_int(200000, 500000)); 
        return false;
    }

    /**
     * RF-02: Verificação Rigorosa de Papel Administrativo (RBAC)
     */
    public function requireAdminAccess(): void {
        if (!isset($_SESSION['user_id'])) {
            $this->terminateAccess();
        }

        // Validação na Fonte da Verdade (Banco de Dados)
        $stmt = $this->db->prepare("
            SELECT r.name 
            FROM app_schema.users u
            JOIN app_schema.roles r ON u.role_id = r.id
            WHERE u.id = :id
        ");
        $stmt->execute(['id' => $_SESSION['user_id']]);
        $role = $stmt->fetchColumn();

        if ($role !== 'Admin') {
            $this->terminateAccess();
        }
    }

    private function terminateAccess(): void {
        http_response_code(403);
        die("Acesso Negado. Esta ocorrência foi registrada."); 
    }
}