#!/bin/bash

# Script de Test Complet - Exercice 3 : Mattermost + PostgreSQL
# Valide tous les aspects du debugging et des corrections apportées

set +e  # Continue même en cas d'erreur pour compter tous les tests

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Fonction pour afficher le résultat d'un test
test_result() {
    local test_name=$1
    local result=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Test $TOTAL_TESTS: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} Test $TOTAL_TESTS: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   Tests Exercice 3 : Mattermost + PostgreSQL              ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# ============================================================================
# SECTION 1 : TESTS DE STRUCTURE DES FICHIERS
# ============================================================================
echo -e "${BOLD}${YELLOW}[1] Tests de Structure des Fichiers${NC}"

# Test 1.1 : Fichier docker-compose-buggy.yml existe
[ -f "docker-compose-buggy.yml" ]
test_result "docker-compose-buggy.yml existe" $?

# Test 1.2 : Fichier docker-compose.yml existe
[ -f "docker-compose.yml" ]
test_result "docker-compose.yml existe" $?

# Test 1.3 : Fichier .env existe
[ -f ".env" ]
test_result ".env existe" $?

# Test 1.4 : Fichier .env.example existe
[ -f ".env.example" ]
test_result ".env.example existe" $?

# Test 1.5 : Fichier .gitignore existe
[ -f ".gitignore" ]
test_result ".gitignore existe" $?

# Test 1.6 : Fichier analyse.md existe
[ -f "analyse.md" ]
test_result "analyse.md existe" $?

# Test 1.7 : Fichier comparaison.md existe
[ -f "comparaison.md" ]
test_result "comparaison.md existe" $?

# Test 1.8 : Fichier SYNTHESE.md existe
[ -f "SYNTHESE.md" ]
test_result "SYNTHESE.md existe" $?

# ============================================================================
# SECTION 2 : TESTS DE SYNTAXE YAML
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[2] Tests de Syntaxe YAML${NC}"

# Test 2.1 : docker-compose-buggy.yml est un YAML valide
docker compose -f docker-compose-buggy.yml config > /dev/null 2>&1
test_result "docker-compose-buggy.yml syntaxe valide" $?

# Test 2.2 : docker-compose.yml est un YAML valide
docker compose -f docker-compose.yml config > /dev/null 2>&1
test_result "docker-compose.yml syntaxe valide" $?

# Test 2.3 : Version directive absente dans docker-compose.yml
! grep -q "^version:" docker-compose.yml
test_result "Pas de directive 'version' dans docker-compose.yml" $?

# Test 2.4 : Version directive présente dans buggy (pour comparaison)
grep -q "^version:" docker-compose-buggy.yml
test_result "Directive 'version' présente dans buggy" $?

# ============================================================================
# SECTION 3 : TESTS DES VARIABLES D'ENVIRONNEMENT
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[3] Tests des Variables d'Environnement${NC}"

# Test 3.1 : .env contient POSTGRES_USER
grep -q "^POSTGRES_USER=" .env
test_result ".env contient POSTGRES_USER" $?

# Test 3.2 : .env contient POSTGRES_PASSWORD
grep -q "^POSTGRES_PASSWORD=" .env
test_result ".env contient POSTGRES_PASSWORD" $?

# Test 3.3 : .env contient POSTGRES_DB
grep -q "^POSTGRES_DB=" .env
test_result ".env contient POSTGRES_DB" $?

# Test 3.4 : .env contient MATTERMOST_PORT
grep -q "^MATTERMOST_PORT=" .env
test_result ".env contient MATTERMOST_PORT" $?

# Test 3.5 : .env contient MATTERMOST_SITE_URL
grep -q "^MATTERMOST_SITE_URL=" .env
test_result ".env contient MATTERMOST_SITE_URL" $?

# Test 3.6 : .env.example contient toutes les variables (masquées)
grep -q "POSTGRES_USER=" .env.example && \
grep -q "POSTGRES_PASSWORD=" .env.example && \
grep -q "POSTGRES_DB=" .env.example && \
grep -q "MATTERMOST_PORT=" .env.example && \
grep -q "MATTERMOST_SITE_URL=" .env.example
test_result ".env.example contient toutes les variables" $?

# Test 3.7 : .gitignore protège le fichier .env
grep -q "^\.env$" .gitignore
test_result ".gitignore contient .env" $?

# ============================================================================
# SECTION 4 : TESTS DE CONFIGURATION DES SERVICES
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[4] Tests de Configuration des Services${NC}"

# Test 4.1 : Service postgres défini
grep -q "postgres:" docker-compose.yml
test_result "Service postgres défini" $?

# Test 4.2 : Service mattermost défini
grep -q "mattermost:" docker-compose.yml
test_result "Service mattermost défini" $?

# Test 4.3 : PostgreSQL utilise l'image postgres:13
grep -A2 "postgres:" docker-compose.yml | grep -q "image: postgres:13"
test_result "PostgreSQL utilise postgres:13" $?

# Test 4.4 : Mattermost utilise l'image officielle
grep -A2 "mattermost:" docker-compose.yml | grep -q "image: mattermost/mattermost-team-edition"
test_result "Mattermost utilise l'image officielle" $?

# Test 4.5 : Container name postgres défini
grep -q "container_name: mattermost-postgres" docker-compose.yml
test_result "Container name postgres défini" $?

# Test 4.6 : Container name mattermost défini
grep -q "container_name: mattermost-app" docker-compose.yml
test_result "Container name mattermost défini" $?

# ============================================================================
# SECTION 5 : TESTS DES NETWORKS
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[5] Tests des Networks${NC}"

# Test 5.1 : Network mattermost-network défini
grep -q "mattermost-network:" docker-compose.yml
test_result "Network mattermost-network défini" $?

# Test 5.2 : Network avec driver bridge
grep -A1 "mattermost-network:" docker-compose.yml | grep -q "driver: bridge"
test_result "Network utilise driver bridge" $?

# Test 5.3 : PostgreSQL connecté au network
grep -A10 "postgres:" docker-compose.yml | grep -A2 "networks:" | grep -q "mattermost-network"
test_result "PostgreSQL connecté au network" $?

# Test 5.4 : Mattermost connecté au network
grep -A15 "mattermost:" docker-compose.yml | grep -A2 "networks:" | grep -q "mattermost-network"
test_result "Mattermost connecté au network" $?

# Test 5.5 : Pas de network dans buggy
! grep -q "networks:" docker-compose-buggy.yml
test_result "Pas de network dans buggy (bug identifié)" $?

# ============================================================================
# SECTION 6 : TESTS DES HEALTH CHECKS
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[6] Tests des Health Checks${NC}"

# Test 6.1 : Health check PostgreSQL présent
grep -A10 "postgres:" docker-compose.yml | grep -q "healthcheck:"
test_result "Health check PostgreSQL présent" $?

# Test 6.2 : Health check utilise pg_isready
grep -A12 "postgres:" docker-compose.yml | grep -q "pg_isready"
test_result "Health check utilise pg_isready" $?

# Test 6.3 : Health check Mattermost présent
grep -A20 "mattermost:" docker-compose.yml | grep -q "healthcheck:"
test_result "Health check Mattermost présent" $?

# Test 6.4 : Health check Mattermost utilise curl
grep -A22 "mattermost:" docker-compose.yml | grep -q "curl"
test_result "Health check Mattermost utilise curl" $?

# Test 6.5 : Health check teste l'API ping
grep -A22 "mattermost:" docker-compose.yml | grep -q "/api/v4/system/ping"
test_result "Health check teste /api/v4/system/ping" $?

# Test 6.6 : Pas de health check dans buggy pour postgres
! grep -A10 "postgres:" docker-compose-buggy.yml | grep -q "healthcheck:"
test_result "Pas de health check postgres dans buggy (bug)" $?

# Test 6.7 : Pas de health check dans buggy pour mattermost
! grep -A15 "mattermost:" docker-compose-buggy.yml | grep -q "healthcheck:"
test_result "Pas de health check mattermost dans buggy (bug)" $?

# ============================================================================
# SECTION 7 : TESTS DES DEPENDS_ON
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[7] Tests des Dépendances${NC}"

# Test 7.1 : Mattermost dépend de postgres
grep -A20 "mattermost:" docker-compose.yml | grep -q "depends_on:"
test_result "Mattermost a depends_on" $?

# Test 7.2 : Dépendance conditionnelle avec service_healthy
grep -A22 "mattermost:" docker-compose.yml | grep -A3 "depends_on:" | grep -q "condition: service_healthy"
test_result "Dépendance conditionnelle service_healthy" $?

# Test 7.3 : Buggy utilise depends_on simple (bug)
grep -A15 "mattermost:" docker-compose-buggy.yml | grep -A2 "depends_on:" | grep -q "postgres" && \
! grep -A15 "mattermost:" docker-compose-buggy.yml | grep -q "condition:"
test_result "Buggy utilise depends_on simple (bug identifié)" $?

# ============================================================================
# SECTION 8 : TESTS DES VARIABLES D'ENVIRONNEMENT SERVICES
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[8] Tests des Variables d'Environnement Services${NC}"

# Test 8.1 : PostgreSQL utilise ${POSTGRES_USER}
grep -A15 "postgres:" docker-compose.yml | grep -q "\${POSTGRES_USER}"
test_result "PostgreSQL utilise \${POSTGRES_USER}" $?

# Test 8.2 : PostgreSQL utilise ${POSTGRES_PASSWORD}
grep -A15 "postgres:" docker-compose.yml | grep -q "\${POSTGRES_PASSWORD}"
test_result "PostgreSQL utilise \${POSTGRES_PASSWORD}" $?

# Test 8.3 : PostgreSQL utilise ${POSTGRES_DB}
grep -A15 "postgres:" docker-compose.yml | grep -q "\${POSTGRES_DB}"
test_result "PostgreSQL utilise \${POSTGRES_DB}" $?

# Test 8.4 : Mattermost datasource utilise variables
grep -A25 "mattermost:" docker-compose.yml | grep "MM_SQLSETTINGS_DATASOURCE" | grep -q "\${POSTGRES_USER}"
test_result "Mattermost datasource utilise variables" $?

# Test 8.5 : Connection string a sslmode parameter
grep -A25 "mattermost:" docker-compose.yml | grep "MM_SQLSETTINGS_DATASOURCE" | grep -q "sslmode="
test_result "Connection string contient sslmode" $?

# Test 8.6 : Connection string a connect_timeout
grep -A25 "mattermost:" docker-compose.yml | grep "MM_SQLSETTINGS_DATASOURCE" | grep -q "connect_timeout="
test_result "Connection string contient connect_timeout" $?

# Test 8.7 : Buggy a credentials hardcodés (bug)
grep -A15 "mattermost:" docker-compose-buggy.yml | grep "MM_SQLSETTINGS_DATASOURCE" | grep -q "password@"
test_result "Buggy a credentials hardcodés (bug identifié)" $?

# Test 8.8 : Port Mattermost utilise variable
grep -A25 "mattermost:" docker-compose.yml | grep "ports:" -A1 | grep -q "\${MATTERMOST_PORT}"
test_result "Port Mattermost utilise \${MATTERMOST_PORT}" $?

# Test 8.9 : Buggy a port hardcodé (bug)
grep -A15 "mattermost:" docker-compose-buggy.yml | grep "ports:" -A1 | grep -q '"8065:8065"'
test_result "Buggy a port hardcodé (bug identifié)" $?

# ============================================================================
# SECTION 9 : TESTS DES VOLUMES
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[9] Tests des Volumes${NC}"

# Test 9.1 : Volume postgres_data défini
grep -q "postgres_data:" docker-compose.yml
test_result "Volume postgres_data défini" $?

# Test 9.2 : Volume mattermost_data défini
grep -q "mattermost_data:" docker-compose.yml
test_result "Volume mattermost_data défini" $?

# Test 9.3 : Volume mattermost_logs défini
grep -q "mattermost_logs:" docker-compose.yml
test_result "Volume mattermost_logs défini" $?

# Test 9.4 : Volume mattermost_plugins défini
grep -q "mattermost_plugins:" docker-compose.yml
test_result "Volume mattermost_plugins défini" $?

# Test 9.5 : Volume mattermost_config défini
grep -q "mattermost_config:" docker-compose.yml
test_result "Volume mattermost_config défini" $?

# Test 9.6 : Volumes utilisent driver local
grep -A1 "postgres_data:" docker-compose.yml | grep -q "driver: local"
test_result "Volumes utilisent driver: local" $?

# Test 9.7 : Mattermost monte volume config
grep -A25 "mattermost:" docker-compose.yml | grep "volumes:" -A5 | grep -q "mattermost_config:/mattermost/config"
test_result "Mattermost monte volume config" $?

# Test 9.8 : Buggy n'a pas volume config (bug)
! grep -A15 "mattermost:" docker-compose-buggy.yml | grep "volumes:" -A4 | grep -q "/mattermost/config"
test_result "Buggy n'a pas volume config (bug identifié)" $?

# ============================================================================
# SECTION 10 : TESTS DES RESTART POLICIES
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[10] Tests des Restart Policies${NC}"

# Test 10.1 : PostgreSQL a restart policy
grep -A18 "postgres:" docker-compose.yml | grep -q "restart:"
test_result "PostgreSQL a restart policy" $?

# Test 10.2 : PostgreSQL restart unless-stopped
grep -A18 "postgres:" docker-compose.yml | grep -q "restart: unless-stopped"
test_result "PostgreSQL restart: unless-stopped" $?

# Test 10.3 : Mattermost a restart policy
grep -A30 "mattermost:" docker-compose.yml | grep -q "restart:"
test_result "Mattermost a restart policy" $?

# Test 10.4 : Mattermost restart unless-stopped
grep -A30 "mattermost:" docker-compose.yml | grep -q "restart: unless-stopped"
test_result "Mattermost restart: unless-stopped" $?

# Test 10.5 : Buggy n'a pas restart pour postgres
! grep -A12 "postgres:" docker-compose-buggy.yml | grep -q "restart:"
test_result "Buggy n'a pas restart postgres (bug identifié)" $?

# Test 10.6 : Buggy n'a pas restart pour mattermost
! grep -A15 "mattermost:" docker-compose-buggy.yml | grep -q "restart:"
test_result "Buggy n'a pas restart mattermost (bug identifié)" $?

# ============================================================================
# SECTION 11 : TESTS DE SÉCURITÉ
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[11] Tests de Sécurité${NC}"

# Test 11.1 : .env n'est pas dans Git
grep -q "^\.env$" .gitignore
test_result ".env protégé dans .gitignore" $?

# Test 11.2 : Pas de password en clair dans docker-compose.yml
! grep -i "password.*=" docker-compose.yml | grep -v "\${" | grep -q "password"
test_result "Pas de password en clair dans docker-compose.yml" $?

# Test 11.3 : .env.example n'a pas de vraies valeurs sensibles
! grep -q "mattermost_secure_password" .env.example
test_result ".env.example n'a pas de vraies valeurs" $?

# Test 11.4 : Buggy a credentials exposés
grep -q "POSTGRES_PASSWORD=password" docker-compose-buggy.yml
test_result "Buggy a credentials exposés (bug identifié)" $?

# ============================================================================
# SECTION 12 : TESTS DE DOCUMENTATION
# ============================================================================
echo -e "\n${BOLD}${YELLOW}[12] Tests de Documentation${NC}"

# Test 12.1 : analyse.md contient au moins 10 bugs
bug_count=$(grep -c "^## .* Bug #" analyse.md 2>/dev/null || echo "0")
[ "$bug_count" -ge 10 ]
test_result "analyse.md contient >= 10 bugs documentés" $?

# Test 12.2 : analyse.md contient section Symptômes
grep -q "### Symptômes" analyse.md
test_result "analyse.md contient sections Symptômes" $?

# Test 12.3 : analyse.md contient section Solution
grep -q "### Solution" analyse.md
test_result "analyse.md contient sections Solution" $?

# Test 12.4 : comparaison.md existe et non vide
[ -s "comparaison.md" ]
test_result "comparaison.md existe et non vide" $?

# Test 12.5 : SYNTHESE.md existe et non vide
[ -s "SYNTHESE.md" ]
test_result "SYNTHESE.md existe et non vide" $?

# Test 12.6 : README.md existe
[ -f "README.md" ]
test_result "README.md existe" $?

# ============================================================================
# RÉSUMÉ DES TESTS
# ============================================================================
echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║                    RÉSUMÉ DES TESTS                        ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "Tests totaux     : ${BOLD}$TOTAL_TESTS${NC}"
echo -e "Tests réussis    : ${GREEN}${BOLD}$PASSED_TESTS${NC}"
echo -e "Tests échoués    : ${RED}${BOLD}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}✓ TOUS LES TESTS SONT PASSÉS !${NC}"
    echo -e "${GREEN}${BOLD}✓ Exercice 3 validé à 100%${NC}\n"
    exit 0
else
    PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "\n${YELLOW}⚠ Taux de réussite : $PERCENTAGE%${NC}"
    echo -e "${RED}Certains tests ont échoué. Vérifiez les corrections.${NC}\n"
    exit 1
fi
