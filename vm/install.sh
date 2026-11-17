#!/usr/bin/env bash
# Instala o bmc-publicador numa VM da BMC. Rode como root, na pasta deste arquivo:
#   bash install.sh
# Instala PAUSADO: nenhum serviço é publicado até a TI rodar
#   bmc-publicador verificar   e   bmc-publicador retomar <id>
# Não mexe em container nenhum. Não cria segredos (a TI coloca os arquivos).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
say()  { printf '\n==> %s\n' "$*"; }
fail() { printf '\nERRO: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "rode como root"
command -v docker >/dev/null || fail "docker não encontrado"
docker compose version >/dev/null 2>&1 || fail "docker compose v2 não encontrado"

say "Pacotes (curl, jq, openssl, util-linux)"
missing=""
for c in curl jq openssl flock; do command -v "$c" >/dev/null || missing="$missing $c"; done
if [ -n "$missing" ]; then
  echo "faltando:$missing"
  if command -v apt-get >/dev/null; then apt-get install -y curl jq openssl util-linux; else dnf install -y curl jq openssl util-linux; fi   # Debian (AGENT-01) ou Oracle Linux (HMG-01)
fi

say "Arquivos"
install -m 0755 -o root -g root "$DIR/bmc-publicador" /usr/local/sbin/bmc-publicador
install -d -m 0750 /etc/bmc-publicador /etc/bmc-publicador/servicos /etc/bmc-publicador/smoke
install -d -m 0700 /etc/bmc-publicador/segredos
install -d -m 0750 /var/lib/bmc-publicador /var/log/bmc-publicador /srv/bmc
[ -f /etc/bmc-publicador/publicador.conf ] ||
  install -m 0640 "$DIR/etc/publicador.conf.example" /etc/bmc-publicador/publicador.conf
for f in "$DIR"/etc/servicos/*.conf.example; do
  dst="/etc/bmc-publicador/servicos/$(basename "$f" .example).exemplo"   # .exemplo não é lido
  install -m 0640 "$f" "$dst"
done
install -m 0750 "$DIR/etc/smoke/"*.sh /etc/bmc-publicador/smoke/
install -m 0644 "$DIR/systemd/bmc-publicador.service" "$DIR/systemd/bmc-publicador.timer" /etc/systemd/system/

say "Logrotate do registro (mantém 12 meses)"
cat >/etc/logrotate.d/bmc-publicador <<'EOF'
/var/log/bmc-publicador/publicacoes.jsonl {
  monthly
  rotate 12
  compress
  missingok
  notifempty
  copytruncate
}
EOF

systemctl daemon-reload
cat <<EOF

Instalado (timer AINDA DESLIGADO). Próximos passos (CHECKLIST.md, fase 4):
  1. Ajustar /etc/bmc-publicador/publicador.conf (ORG, App, PAT).
  2. Colocar os segredos em /etc/bmc-publicador/segredos/ (0600):
       github-app.pem   ghcr.token
  3. Renomear o(s) /etc/bmc-publicador/servicos/*.conf.exemplo → .conf e ajustar.
  4. Copiar o compose para /srv/bmc/<id>/compose.yml.
  5. Para cada serviço:  bmc-publicador pausar <id>
  6. bmc-publicador verificar
  7. systemctl enable --now bmc-publicador.timer
EOF
