<?php
declare(strict_types=1);

namespace App\Models;

use PDO;
use Exception;

class UserModel {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    /**
     * Cria um novo usuário utilizando o algoritmo Argon2id
     */
    public function createUser(string $email, string $plainPassword, string $roleId): string {
        // Gera o hash de segurança máxima (Requisito OWASP)
        $passwordHash = password_hash($plainPassword, PASSWORD_ARGON2ID, [
            'memory_cost' => 65536, // 64 MB
            'time_cost'   => 4,     // Iterações
            'threads'     => 2,
        ]);

        $stmt = $this->db->prepare("
            INSERT INTO app_schema.users (email, password_hash, role_id) 
            VALUES (:email, :hash, :role_id)
            RETURNING id
        ");

        $stmt->execute([
            'email'   => $email,
            'hash'    => $passwordHash,
            'role_id' => $roleId
        ]);

        return $stmt->fetchColumn(); // Retorna o UUID gerado pelo banco
    }
}