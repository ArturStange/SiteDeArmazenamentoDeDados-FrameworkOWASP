<?php
declare(strict_types=1);

// Blindagem dos Cookies de Sessão (Requisito OWASP ASVS)
ini_set('session.cookie_httponly', '1'); // Impede acesso via JavaScript (XSS)
ini_set('session.cookie_secure', '1');   // Exige HTTPS
ini_set('session.cookie_samesite', 'Strict'); // Mitiga CSRF
ini_set('session.use_strict_mode', '1'); // Rejeita IDs de sessão não inicializados pelo servidor

// Nome customizado para não expor a tecnologia 
session_name('__Host-AppSession'); 

session_start();