FROM golang:1.23.0-bookworm
# docker run -dit -v /Users/zen/Github/WhisperAndTrans:/data --name test golang:1.22.4-bookworm bash
LABEL authors="zen"
# 更换国内源
COPY sources.list /etc/apt/sources.list.d/debian.sources
# 更新软件
# 更新软件并安装依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip translate-shell ffmpeg ca-certificates \
    bsdmainutils sqlite3 gawk locales libfribidi-bin dos2unix p7zip-full \
    wget curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \

COPY badupcs_amd64.zip /root
COPY badupcs_arm64.zip /root

# 解压 BaiduPCS-Go
RUN 7z x /root/badupcs_amd64.zip  && \
    7z x /root/badupcs_arm64.zip  && \
    rm /root/badupcs_amd64.zip /root/badupcs_arm64.zip

RUN apt-get clean

# 安装 openai-whisper
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip install openai-whisper --break-system-packages --no-cache-dir

# 配置 Go 环境
RUN go env -w GO111MODULE=on && \
    go env -w GOBIN=/go/bin \

# 启动程序
#ENTRYPOINT ["go", "run","/app/main.go"]
CMD ["bash"]