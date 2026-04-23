# 🛡️ Sistema Web Seguro (SWS) - Plataforma de Dados Críticos

[![OWASP ASVS 5.0](https://img.shields.io/badge/OWASP%20ASVS-N%C3%ADvel%202-blue.svg)](https://owasp.org/www-project-application-security-verification-standard/)
[![NIST CSF 2.0](https://img.shields.io/badge/NIST-CSF%202.0-green.svg)](https://www.nist.gov/cyberframework)
[![PHP 8.3](https://img.shields.io/badge/PHP-8.3+-777BB4.svg)](https://php.net/)

## 📖 Sobre o Projeto
O **Sistema Web Seguro** é uma aplicação backend/frontend projetada sob medida para o armazenamento, gestão e auditoria de dados críticos. A arquitetura foi desenvolvida desde o início com foco em *Security by Design*, adotando práticas robustas de gerenciamento de identidade, controle de acesso administrativo e isolamento de banco de dados.

O sistema mitiga ativamente os riscos apontados no **OWASP Top 10 2025**, segue os protocolos de verificação do **ASVS 5.0** e integra as estratégias de resiliência e monitoramento do **NIST Cybersecurity Framework 2.0**.

## 🛠️ Arquitetura e Tecnologias
* **Backend:** PHP 8.3+ (Strict Types habilitado).
* **Banco de Dados:** PostgreSQL 15+ com Row-Level Security (RLS) e conexões blindadas via PDO.
* **Frontend:** HTML5, CSS3, JavaScript (com restrições de CSP rigorosas).
* **Criptografia:** Argon2id (Hashing de Senhas), AES-256-GCM (Criptografia em Repouso).

## 🏗️ Cronograma e Entregáveis
* [ ] **Fase 1:** Modelagem e Endurecimento (Hardening) do BD: Desenho do schema
PostgreSQL, criação de usuários de banco com privilégios mínimos, implementação
de Row-Level Security (RLS) e Triggers de auditoria imutável.
* [ ] **Fase 2:** Motor de Identidade e Sessão: Desenvolvimento em PHP da autenticação,
MFA, gestão de sessão e da verificação rigorosa de papéis administrativos no
back-end.
* [ ] **Fase 3:** Lógica de Negócios e Criptografia: Implementação do CRUD utilizando o
PDO de forma estrita, criptografando colunas sensíveis antes da inserção e validando
todas as entradas.
* [ ] **Fase 4:** Verificação e Resposta (ASVS & NIST): Análise estática de código (SAST),
análise de dependências e testes de penetração cobrindo os cenários do OWASP
ASVS Nível 2.

## 🔒 Pilares de Segurança Implementados
- **Gestão de Identidade:** Sistema de RBAC validado inteiramente no backend a cada requisição; proteção contra manipulação de exibição de identidade na interface.
- **Proteção de Dados:** Uso irrestrito de *Prepared Statements* para evitar SQL Injection. Dados sensíveis no banco são anonimizados ou criptografados.
- **Gerenciamento de Segredos:** Nenhuma credencial está *hardcoded*. O sistema utiliza arquivos `.env` estritamente controlados fora do diretório público (`public_html`).
- **Resiliência de Sessão:** Cookies emitidos com flags `HttpOnly`, `Secure` e `SameSite=Strict`.
- **Prevenção de Anomalias:** Tratamento global de exceções (*fail-closed*) para evitar vazamento de infraestrutura em erros de runtime.

## 🚀 Instalação e Configuração (Ambiente de Desenvolvimento)

### Pré-requisitos
- PHP >= 8.3 com extensões `pdo_pgsql`, `sodium` e `mbstring`.
- PostgreSQL >= 15.
- Composer.

### Passos
1. **Clone o repositório:**
   ```bash
   git clone [https://github.com/sua-org/sistema-web-seguro.git](https://github.com/sua-org/sistema-web-seguro.git)
   cd sistema-web-seguro

2. **Instale as dependências protegidas:**
   ```bash
   composer install --no-dev --optimize-autoloader

3. **Configure as Variáveis de Ambiente:**
   ```bash
   cp .env.example .env

4. **Provisionamento do Banco de Dados:**
   ```bash
   Execute os scripts de migração que configuram as tabelas e os roles restritos de banco de dados na pasta /database/migrations

5. **Inicie o Servidor:**
   ```bash
    Certifique-se de apontar o Document Root do seu servidor web (Nginx/Apache) estritamente para a pasta /public. Nenhuma outra pasta deve ser acessível via web.

## 🛡️ Diretrizes para Contribuição (Código Seguro)

Desenvolvedores devem aderir ao manual de segurança interno do projeto antes de abrir um Pull Request:

1. Valide todo input usando allow-lists.

2. Nunca concatene variáveis em consultas SQL; utilize os métodos base da classe Database (PDO Wrapper).

3. Qualquer alteração em lógicas de permissão (RBAC) exige aprovação dupla de revisão (Code Review).

4. Utilize as ferramentas de análise estática configuradas no projeto antes do commit.

## 📜 Licença

Distribuído sob licenciamento restrito de uso corporativo. Protegido sob os termos e condições da organização.
