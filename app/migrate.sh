# Leva o estado do nome antigo (llm-agent) para o nome jarvis. Carregado com "."
# pelos scripts de entrada; nao faz nada se nao houver o que migrar.
#
# A pasta antiga vira um link para a nova: um servidor antigo ainda em execucao
# (ate o proximo reinicio) e uma volta de versao em restart.sh continuam achando
# os arquivos. Se as duas pastas existirem, nada e movido nem misturado.
jarvis_migrate_state() {
  local base old new
  for base in "${XDG_CONFIG_HOME:-$HOME/.config}" "${XDG_DATA_HOME:-$HOME/.local/share}"; do
    old="$base/llm-agent"
    new="$base/jarvis"
    if [ -d "$old" ] && [ ! -L "$old" ] && [ ! -e "$new" ]; then
      if mv "$old" "$new" 2>/dev/null; then
        ln -s "$new" "$old" 2>/dev/null || true
      else
        echo "jarvis: nao consegui mover $old para $new." >&2
      fi
    fi
  done
  # Comando do Docker salvo pelo install.sh --docker, com o nome antigo da variavel.
  local config="${XDG_CONFIG_HOME:-$HOME/.config}/jarvis/config"
  if [ -f "$config" ] && grep -q '^LLM_AGENT_DOCKER=' "$config" 2>/dev/null; then
    sed -i 's/^LLM_AGENT_DOCKER=/JARVIS_DOCKER=/' "$config" 2>/dev/null || true
  fi
  return 0
}
