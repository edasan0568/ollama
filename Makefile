# ==============================================================================
# Ollama - Podman Management Makefile
# ==============================================================================

IMAGE_NAME  := ollama-gemma4
IMAGE_TAG   := latest
CONTAINER   := ollama
VOLUME      := ollama_data
PORT        := 11434
API_URL     := http://localhost:$(PORT)

# コマンドライン第2引数をモデル名として受け取る (例: make start llama3.2)
# 引数なしの場合はデフォルト値を使用
_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ifneq ($(_ARGS),)
  MODEL := $(_ARGS)
else
  MODEL ?= gemma4:e4b
endif

# 引数として渡されたモデル名（コロンを含む場合など）を
# makeがターゲットとして解釈してエラーになるのを防ぐためのダミールール
%:
	@:

.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# ヘルプ
# ------------------------------------------------------------------------------
.PHONY: help
help: ## このヘルプを表示する
	@echo ""
	@echo "  Ollama - Podman管理コマンド一覧"
	@echo "  ============================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  引数:"
	@echo "    MODEL   使用するモデル名 (デフォルト: gemma4:e4b)"
	@echo ""
	@echo "  例:"
	@echo "    make start llama3.2"
	@echo "    make run   phi4"
	@echo "    make pull  mistral"
	@echo "    make rm    qwen3:14b"
	@echo "    make start           # デフォルト: gemma4:e4b"
	@echo ""

# ------------------------------------------------------------------------------
# ビルド
# ------------------------------------------------------------------------------
.PHONY: build
build: ## Containerイメージをビルドする
	@echo "==> イメージをビルド中: $(IMAGE_NAME):$(IMAGE_TAG)"
	podman build -t $(IMAGE_NAME):$(IMAGE_TAG) .

.PHONY: rebuild
rebuild: ## キャッシュなしでイメージを再ビルドする
	@echo "==> キャッシュなしで再ビルド中: $(IMAGE_NAME):$(IMAGE_TAG)"
	podman build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) .

# ------------------------------------------------------------------------------
# 起動 / 停止
# ------------------------------------------------------------------------------
.PHONY: start
start: ## コンテナをバックグラウンドで起動する
	@echo "==> コンテナを起動中..."
	podman run -d \
		--name $(CONTAINER) \
		-p $(PORT):11434 \
		-v $(VOLUME):/root/.ollama \
		-e OLLAMA_MODEL=$(MODEL) \
		--device nvidia.com/gpu=all \
		--restart unless-stopped \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "==> 起動完了。API: $(API_URL)"

.PHONY: stop
stop: ## コンテナを停止する
	@echo "==> コンテナを停止中..."
	podman stop $(CONTAINER)

.PHONY: restart
restart: ## コンテナを再起動する
	@echo "==> コンテナを再起動中..."
	podman restart $(CONTAINER)

.PHONY: down
down: ## コンテナを停止して削除する
	@echo "==> コンテナを停止・削除中..."
	-podman stop $(CONTAINER)
	-podman rm $(CONTAINER)

.PHONY: down-volumes
down-volumes: down ## コンテナとボリュームをすべて削除する（モデルデータも消去）
	@echo "==> ボリュームを削除中（モデルデータも削除されます）..."
	-podman volume rm $(VOLUME)

# ------------------------------------------------------------------------------
# ログ / 状態確認
# ------------------------------------------------------------------------------
.PHONY: logs
logs: ## コンテナのログをフォローする
	podman logs -f $(CONTAINER)

.PHONY: status
status: ## コンテナの状態を確認する
	podman ps -a --filter name=$(CONTAINER)

.PHONY: ps
ps: status ## statusのエイリアス

# ------------------------------------------------------------------------------
# モデル操作
# ------------------------------------------------------------------------------
.PHONY: pull
pull: ## コンテナ内でモデルを手動Pull（起動済みの場合）
	@echo "==> モデル '$(MODEL)' をPull中..."
	podman exec $(CONTAINER) ollama pull $(MODEL)

.PHONY: list-models
list-models: ## インストール済みモデル一覧を表示する
	@echo "==> インストール済みモデル一覧:"
	podman exec $(CONTAINER) ollama list

.PHONY: run
run: ## コンテナ内でモデルをインタラクティブに実行する
	@echo "==> モデル '$(MODEL)' を実行中..."
	podman exec -it $(CONTAINER) ollama run $(MODEL)

.PHONY: rm
rm: ## コンテナ内のモデルを削除する
	@echo "==> モデル '$(MODEL)' を削除中..."
	podman exec $(CONTAINER) ollama rm $(MODEL)

# ------------------------------------------------------------------------------
# APIテスト
# ------------------------------------------------------------------------------
.PHONY: test
test: ## APIの疎通テストを行う
	@echo "==> APIテスト中 ($(API_URL))..."
	@curl -sf $(API_URL)/api/tags | python3 -m json.tool || \
		echo "エラー: APIに接続できません。コンテナが起動しているか確認してください。"

.PHONY: chat
chat: ## チャットAPIサンプルリクエストを送信する
	@echo "==> チャットAPIテスト中..."
	curl -s $(API_URL)/api/generate \
		-H "Content-Type: application/json" \
		-d '{"model":"$(MODEL)","prompt":"Hello! Who are you?","stream":false}' \
		| python3 -m json.tool

# ------------------------------------------------------------------------------
# クリーンアップ
# ------------------------------------------------------------------------------
.PHONY: clean
clean: down ## コンテナとイメージを削除する
	@echo "==> イメージを削除中..."
	-podman rmi $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: clean-all
clean-all: down-volumes clean ## すべてのリソースを削除する（ボリューム含む）
	@echo "==> すべてのリソースを削除しました"
