<?php
declare(strict_types=1);

namespace App\Core;

use PDO;
use PDOException;

class Database {
    private PDO $pdo;

    public function __construct() {
        // As credenciais devem vir do $_ENV (carregadas pelo vlucas/phpdotenv no bootstrap)
        $dsn = "pgsql:host={$_ENV['DB_HOST']};dbname={$_ENV['DB_NAME']};options='-c client_encoding=utf8'";
        
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // Falha fechada (fail-closed)
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false, // Força Prepared Statements reais no driver
        ];

        try {
            $this->pdo = new PDO($dsn, $_ENV['DB_USER'], $_ENV['DB_PASS'], $options);
            
            // INTEGRAÇÃO COM A FASE 1 (RLS - Row Level Security)
            if (isset($_SESSION['user_id'])) {
                $stmt = $this->pdo->prepare("SET LOCAL app.current_user_id = :user_id");
                $stmt->execute(['user_id' => $_SESSION['user_id']]);
            }
        } catch (PDOException $e) {
            // Tratamento fail-closed (RF-04): Impede vazamento de stack trace
            error_log("Erro de Conexão DB: " . $e->getMessage());
            die("Erro crítico de infraestrutura. A equipe foi notificada.");
        }
    }

    public function getConnection(): PDO {
        return $this->pdo;
    }
}