#!/usr/bin/env bash
# Smoke test da Controladoria depois de cada publicação. Recebe o HEALTH_URL.
# Só leitura e sem login: a página abre e a API está de pé (responde 401
# sem sessão, como em 2026-11-16). Os testes funcionais (login, perfis,
# Provisões, Gente, N2/BOD, EBITDA) ficam no checklist do PR de promoção.
set -euo pipefail
base="${1%/}"
curl -fsS -o /dev/null --max-time 10 "$base/"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$base/api/health")
case "$code" in 200|401) ;; *) echo "API respondeu $code em /api/health"; exit 1 ;; esac
