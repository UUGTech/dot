# drover.nvim — herdrにコンテキストを送るNeovimプラグイン

## 背景

Neovim内でsidekick.nvimを使っていたが、sidekick.cli（mux backend連携）には「1ディレクトリ1session per CLI」の制約があり、herdrの複数agentパネル運用と噛み合わない。herdr自体はsocket API経由でagent操作が可能なCLI（`herdr agent list/send/focus/start`など）を持っているため、これを直接叩く独立プラグインを新設する。

sidekick.nvimが提供していた「バッファ/ファイル/選択範囲をエージェントに送る」体験のうち、herdrのagentパネル運用に必要な部分だけを、sidekickに依存せず再実装する。

## 調査結果（既存プラグインの有無）

- sidekick.nvim本家には`mux.backend`として`tmux`/`zellij`のみ対応。herdrは非対応。
- ただし `folke/sidekick.nvim` に **PR #333「feat(mux): herdr support」**（`rmarganti/sidekick.nvim` の `herdr` ブランチ、2026-06-25オープン、CI green、mergeable、未レビュー）が存在し、herdrをmux backendとして追加する実装がある。
- 今回はsidekickの制約（1dir1session/CLI）そのものを避けたいため、このPRやsidekick.cli自体には依存しない方針とした。単なる参考実装として設計時に読んだ。

## スコープ

### 対象

- herdr上の既存agentパネルへ、以下3種のコンテキストを送る:
  - 現在ファイルの参照（`@relative/path`、行番号なし）
  - ビジュアル選択範囲の生テキスト
  - 開いている全バッファ（buflisted かつ実ファイル）の`@relative/path`一覧
- 送信先はtelescopeピッカーで毎回選択（「現在のターゲット」を記憶する仕組みは持たない）。
- 送信先に既存agentが無い/新規を選んだ場合、`herdr agent start`で新規agentパネルを起動してから送信。
- テキストは流し込むだけで、Enter（送信）はユーザーが手動で行う。自動送信はしない。

### 非対象（YAGNI）

- NES（Next Edit Suggestion）、prompt library、diagnostics/quickfix/textobjectコンテキスト — sidekick.nvim側の機能。今回は範囲外。
- tmux/zellijバックエンド対応 — herdr専用。
- 「現在のターゲット」を固定して使い続けるモード — 毎回ピッカーで選ぶ方式のみ。

## 名前

`drover.nvim`（drover = 家畜の群れを追う人。herdr(herd)のテーマに合わせた命名）。

将来的に独立リポジトリとして切り出せる品質・構造を意識するが、今回はこのdotfilesリポジトリ内に配置する。

配置とロード方式は、lazy.nvim経由（`plugins/drover.lua`でdir参照）ではなく、既存の`config/nvim/lua/text_objects.lua`と同じパターンを踏襲する: `config/nvim/lua/drover/`配下にモジュールを置き、`config/nvim/init.lua`から`require("drover").setup()`を直接呼ぶ。setup自体はキーマップ登録のみでtelescopeを即時には必要としない（telescopeは実際に送信操作が呼ばれた時点で`picker.lua`が遅延requireする）ため、lazy.nvimの`dir=`機構を使う理由がない。既存の踏み跡に従う方がシンプルで確実。

- `config/nvim/init.lua` — `require("drover").setup()`の呼び出しを追加
- `config/nvim/lua/drover/` — プラグイン本体

## アーキテクチャ

```
lua/drover/
  init.lua      -- setup(opts)、keymapのバインド
  herdr.lua     -- herdr CLIの薄いラッパー（JSON decode含む）
  context.lua   -- 送信テキストの構築（file / selection / buffers）
  picker.lua    -- telescopeピッカー（既存agent一覧 + "+ New session"）
  send.lua      -- 上記を束ねる: context取得 → picker表示 → focus + send
  tests/        -- plenary.nvimによるcontext.luaの単体テスト
```

### herdr.lua

`vim.system`で`herdr`バイナリを呼び出し、JSON応答をデコードするだけの薄いラッパー。socket APIを直接叩くことはしない（herdrのCLI自体が安定したJSON出力を提供しているため、再発明する理由がない）。

提供する関数:
- `list_agents()` — `herdr agent list` の結果をデコードして返す
- `send(target, text)` — `herdr agent send <target> <text>`（literal、Enterなし）
- `focus(target)` — `herdr agent focus <target>`
- `start(name, argv, opts)` — `herdr agent start <name> --cwd <cwd> -- <argv>`

### context.lua

3つの純粋関数（バッファ/選択状態から文字列を組み立てるだけ）:
- `current_file()` → `@relative/path`（cwd相対、行番号なし）
- `visual_selection()` → 選択範囲の生テキストのみ（ファイル参照は含めない。必要なら`current_file()`と組み合わせて呼ぶ）
- `open_buffers()` → buflistedかつ実ファイルの全バッファを`@relative/path`一覧に変換

### picker.lua

`herdr.list_agents()`の結果をtelescope pickerで表示。列は既存の`agent-picker.sh`に準拠（状態・agent名・cwd）。先頭に`+ New session`エントリを追加する。

### send.lua

公開関数: `send_file()` / `send_selection()` / `send_buffers()`。

処理フロー:
1. `context`から送信テキストを生成
2. `picker.pick(on_choice)`でターゲットを選択させる
3a. 既存agentを選んだ場合:
   - `herdr agent focus <target>`
   - `herdr pane zoom <target> --off`（ズーム解除。既存の`agent-picker.sh`と同じ配慮）
   - `herdr agent send <target> <text>`
3b. `+ New session`を選んだ場合:
   - agent名を選択（`opts.agents`から）
   - `herdr agent start <name> --cwd <対象バッファのcwd> -- <argv>`
   - 新規pane_idの出現を短時間ポーリング（`herdr agent list`）で待つ
   - focus + send

## 設定スキーマ

```lua
---@class drover.Opts
---@field keys? table<string, false|string>  -- action名 -> キー。falseでバインド解除
---@field agents? string[]                    -- "+ New session" で選べるagent名
---@field agent_cmd? table<string,string[]>   -- agent名 -> herdr agent start に渡すargv
local defaults = {
  keys = {
    send_file = "<leader>hf",
    send_selection = "<leader>hv",
    send_buffers = "<leader>hb",
  },
  agents = { "claude", "codex", "opencode" },
  agent_cmd = {
    claude = { "claude" },
    codex = { "codex" },
    opencode = { "opencode" },
  },
}
```

キーマップは`<leader>h*`（herdr）に寄せ、sidekick.nvimの`<leader>a*`と衝突しない。sidekick.nvim自体は残置してよく、`cli.mux`機能を使うかどうかは別途判断する（NESなど無関係な機能には影響しない）。

## 未解決の技術リスク（実装最初のスパイクで検証する）

複数行テキスト（`open_buffers()`の結果など）を`herdr agent send`で送ったとき、埋め込まれた改行が「Enterキー押下」として解釈され、CLI側で行ごとに実行/送信されてしまう可能性がある。

設計時に検証を試みたが、対象paneが未フォーカス/未レンダリング状態だと`herdr pane read`が空を返し、決定的な確認ができなかった。実際にCLIが動いているpaneに対して手動で複数行テキストを送り、挙動を確認する必要がある。

もし改行がEnterとして解釈される実装であれば、「Enterは自動で押さない」という要件と矛盾するため、代替策（bracketed paste相当のエスケープ付与など）を検討する。この検証は実装計画の最初のタスクとして明記する。

## テスト方針

- `context.lua`の3関数はplenary.nvimのbustedスタイルで単体テスト可能（cwd相対パス化、複数行インデント補正などを対象）。
- `herdr.lua` / `picker.lua` / `send.lua`はCLI呼び出しが本質のため単体テストの価値は薄く、手動確認を中心にする。実装計画に「実際のherdr paneに対する動作確認」ステップを含める。
