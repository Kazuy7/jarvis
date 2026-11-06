#!/usr/bin/env bash
# Testa a migracao do nome antigo (llm-agent) para jarvis: pastas de estado,
# configuracao do Docker e imagem, com um "docker" falso.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config" XDG_DATA_HOME="$work/home/.local/share"
mkdir -p "$HOME"

failures=0
check() { # descricao esperado obtido
  if [ "$3" = "$2" ]; then
    echo "ok - $1"
  else
    echo "FAIL - $1"
    echo "  esperado: $2"
    echo "  obtido:   $3"
    failures=$((failures + 1))
  fi
}
migrate() { bash -c '. "$1/app/migrate.sh"; jarvis_migrate_state' _ "$repo"; }

mkdir -p "$XDG_CONFIG_HOME/llm-agent/ui" "$XDG_DATA_HOME/llm-agent/workspace"
echo tok >"$XDG_CONFIG_HOME/llm-agent/ui/token"
echo mem >"$XDG_DATA_HOME/llm-agent/workspace/arquivo"
echo "LLM_AGENT_DOCKER='sudo docker'" >"$XDG_CONFIG_HOME/llm-agent/config"

migrate
check "move a configuracao" tok "$(cat "$XDG_CONFIG_HOME/jarvis/ui/token")"
check "move os dados" mem "$(cat "$XDG_DATA_HOME/jarvis/workspace/arquivo")"
check "a pasta antiga vira link para a nova" "$XDG_CONFIG_HOME/jarvis" "$(readlink "$XDG_CONFIG_HOME/llm-agent")"
check "renomeia a variavel do Docker" "JARVIS_DOCKER='sudo docker'" "$(cat "$XDG_CONFIG_HOME/jarvis/config")"

migrate
check "rodar de novo nao muda nada" tok "$(cat "$XDG_CONFIG_HOME/llm-agent/ui/token")"

# As duas pastas existem: nao mistura nem apaga.
rm "$XDG_CONFIG_HOME/llm-agent"
mkdir -p "$XDG_CONFIG_HOME/llm-agent"
echo antigo >"$XDG_CONFIG_HOME/llm-agent/token"
migrate
check "com as duas pastas, mantem a antiga" antigo "$(cat "$XDG_CONFIG_HOME/llm-agent/token")"
check "com as duas pastas, mantem a nova" tok "$(cat "$XDG_CONFIG_HOME/jarvis/ui/token")"

# Imagem com o nome antigo: ganha o nome novo, sem reconstruir.
rm -f "$XDG_CONFIG_HOME/jarvis/config" # o arquivo teria prioridade sobre o docker falso
fake="$work/fake-docker"
cat >"$fake" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE_LOG"
case "$1 $2" in
  "image inspect")
    [ "$3" = "local/llm-agent-safe:latest" ] && [ ! -e "$FAKE_LOG.tagged" ] && exit 0
    [ "$3" = "local/jarvis-safe:latest" ] && [ -e "$FAKE_LOG.tagged" ] && exit 0
    exit 1
    ;;
  "image tag") touch "$FAKE_LOG.tagged" ;;
  "container inspect") exit 1 ;;
esac
exit 0
EOF
chmod +x "$fake"
proj="$work/projeto"
mkdir -p "$proj"
run() { (cd "$proj" && JARVIS_DOCKER="$fake" JARVIS_NO_UPDATE_CHECK=1 FAKE_LOG="$work/log" "$repo/jarvis" zsh </dev/null >/dev/null 2>&1); }
mkdir -p "$HOME/.codex" "$HOME/.claude"
touch "$HOME/.claude.json"

run
check "da o nome novo a imagem antiga" 1 "$(grep -c '^image tag local/llm-agent-safe:latest local/jarvis-safe:latest$' "$work/log")"
check "tira o nome antigo da imagem" 1 "$(grep -c '^image rm local/llm-agent-safe:latest$' "$work/log")"
run
check "nao repete a troca" 1 "$(grep -c '^image tag' "$work/log")"

[ "$failures" -eq 0 ] && echo "todos os testes passaram" || { echo "$failures falha(s)"; exit 1; }
