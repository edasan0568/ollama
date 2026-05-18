FROM docker.io/ollama/ollama:latest

# モデルを事前にPullするためのエントリーポイントスクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ollamaのデータディレクトリ
VOLUME ["/root/.ollama"]

# Ollama APIポート
EXPOSE 11434

ENTRYPOINT ["/entrypoint.sh"]
