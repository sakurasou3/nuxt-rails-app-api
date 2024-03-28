# baseimage
# 参考：https://blog.cloud-acct.com/posts/u-rails-dockerfile/#%E3%83%99%E3%83%BC%E3%82%B9%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%81%AEruby%E3%83%90%E3%83%BC%E3%82%B8%E3%83%A7%E3%83%B3%E3%82%92%E8%AA%BF%E3%81%B9%E3%82%8B%E6%89%8B%E9%A0%86
FROM ruby:3.3.0-alpine

# ARG ... Dockerファイル内でのみ使用するもの
# ENV ... コンテナ内でも利用するもの

# .env => docker-compose.yml => Dockerfile(このファイル)を経由して値を受け取る
ARG WORKDIR
# ruby:3.3.0-alpineに入っているパッケージを除く
# https://github.com/docker-library/ruby/blob/7ac7122778cc764cd50271807efe2e94775b2c21/3.3/alpine3.19/Dockerfile
ARG RUNTIME_PACKAGES="nodejs tzdata postgresql-dev postgresql git"
ARG DEV_PACKAGES="build-base curl-dev"

# Dockerfile、コンテナから参照可能な環境変数を定義
ENV HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# 作業ディレクトリを定義
WORKDIR ${HOME}

# Dockerfilte内で指定できる命令は5つ(RUN, COPY, ADD, ENTORYPOINT, CMD)
# ホストPCのファイル(ここではGemfile*)をコンテナ内の作業ディレクトリにコピー
# COPY コピー元（ホスト） コピー先(コンテナ)
# コピー元（ホスト）...Dockerfileがあるディレクトリ以下を指定する必要がある
# コピー先（コンテナ）...作業ディレクトリからの絶対/相対パス
COPY Gemfile* ./

# apk...Alpine Linexコマンド。多分apt-getの代わり
# update...パッケージの最新リストを取得
# upgrade...インストールパッケージを最新にする
# add...パッケージ(RUNTIME_PACKAGES)のインストールを実行
# --no-cache...パッケージをキャッシュしない（Dockerイメージの軽量化）
# --virtual...仮想パッケージ化してDEV_PACKAGESインストール
# bundle install -j4...j4=jobs-4の略。Gemインストールを最大4つ並列インストールする
# apk del build-dependencies...パッケージを削除（Dockerイメージの軽量化）
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    apk add --no-cache gcompat && \
    bundle install -j4 && \
    apk del build-dependencies

COPY . .

# コンテナ内で実行するコマンドを定義
# -b...バインド。プロセスを指定したIPアドレス(0.0.0.0)に紐付けする。
# 外部のブラウザからRailsへのアクセスを許容する
# docker-compose.ymlに移動
# CMD ["rails", "server", "-b", "0.0.0.0"]