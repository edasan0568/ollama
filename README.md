# Ollama (LLM) - Podman Setup

Podmanを使ってOllamaサーバーを起動し、LLMモデルを実行する構成です。

## ファイル構成

```
ollama/
├── Dockerfile    # Podman用コンテナイメージ定義
├── entrypoint.sh   # 起動スクリプト（モデル自動Pull含む）
├── Makefile        # 管理コマンド
└── README.md       # このファイル
```

## 前提条件

- [Podman](https://podman.io/) がインストール済みであること

## クイックスタート

```bash
# 1. イメージをビルド
make build

# 2. コンテナを起動（gemma4:e4b が自動でPullされます）
make start

# 3. 起動確認
make status

# 4. APIテスト
make test
```

## コマンド一覧

| コマンド | 説明 |
|---|---|
| `make build` | コンテナイメージをビルド |
| `make rebuild` | キャッシュなしで再ビルド |
| `make start` | コンテナをバックグラウンドで起動 |
| `make stop` | コンテナを停止 |
| `make restart` | コンテナを再起動 |
| `make down` | コンテナを停止・削除 |
| `make down-volumes` | コンテナ・ボリュームをすべて削除 |
| `make logs` | ログをフォロー表示 |
| `make status` | コンテナの状態確認 |
| `make pull` | モデルを手動でPull |
| `make list-models` | インストール済みモデル一覧 |
| `make run` | モデルをインタラクティブに実行 |
| `make test` | APIの疎通テスト |
| `make chat` | チャットAPIサンプル実行 |
| `make clean` | コンテナ・イメージを削除 |
| `make clean-all` | すべてのリソースを削除 |

## API エンドポイント

起動後、以下のエンドポイントが利用可能です：

- **Ollama API**: `http://localhost:11434`
- **モデル一覧**: `http://localhost:11434/api/tags`
- **チャット**: `http://localhost:11434/api/generate`

## チャットAPIの例

```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:e4b",
    "prompt": "日本語で自己紹介してください。",
    "stream": false
  }'
```

## GPU利用について

GPUを利用する場合は `Makefile` の以下行のコメントアウトを外してください。

```yaml
# device nvidia.com/gpu=all \
```