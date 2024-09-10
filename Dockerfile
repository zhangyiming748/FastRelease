FROM golang:1.23.1-bookworm

LABEL authors="zen"

# 更换国内源

COPY sources.list /etc/apt/sources.list.d/debian.sources

# 更新软件并安装依赖
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    python3 python3-pip translate-shell ffmpeg ca-certificates \
    bsdmainutils sqlite3 gawk locales libfribidi-bin dos2unix p7zip-full \
    wget curl build-essential
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# 复制BaiduPCS-Go

COPY baidupcs_amd64.zip /root
COPY baidupcs_arm64.zip /root
COPY danmaku2ass/danmaku2ass.py /usr/local/bin
RUN chmod a+rwx /usr/local/bin/danmaku2ass
WORKDIR /root

# 解压 BaiduPCS-Go

RUN ls -al
RUN 7z x baidupcs_amd64.zip
RUN 7z x baidupcs_arm64.zip
RUN rm baidupcs_amd64.zip
RUN rm baidupcs_arm64.zip

# 安装 openai-whisper

RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED
RUN pip install openai-whisper yt-dlp --break-system-packages --no-cache-dir

# 配置 Go 环境

RUN go env -w GO111MODULE=on
RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go env -w GOBIN=/go/bin

# 启动程序

CMD ["bash"]
