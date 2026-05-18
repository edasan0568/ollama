#!/bin/bash
set -e

MODEL="${OLLAMA_MODEL:-gemma4:e4b}"

echo "==> Ollamaサーバーをバックグラウンドで起動中..."
ollama serve &
OLLAMA_PID=$!

# サーバーの起動を待機
echo "==> Ollamaサーバーの起動を待機中..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done

echo "==> モデル '${MODEL}' をPull中..."
ollama pull "${MODEL}"

echo "==> モデル '${MODEL}' の準備完了"
echo "==> Ollamaサーバーが起動しています (PID: ${OLLAMA_PID})"

# フォアグラウンドでOllamaプロセスを維持
wait ${OLLAMA_PID}
