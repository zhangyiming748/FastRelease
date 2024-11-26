# 第一阶段：使用 Golang 1.18 编译文件
#docker run -dit --name baidu -v C:\Users\zen\Github\FastRelease:/data golang:1.18.10-bullseye bash
FROM golang:1.18.10-bullseye AS builder
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 更换完整源
#COPY debian.sources /etc/apt/sources.list.d/debian.sources
#RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
ENV PATH=$PATH:/go/bin
RUN apt update
RUN apt install zip build-essential -y
RUN go env -w GOBIN=/go/bin
# RUN go install github.com/josephspurrier/goversioninfo@latest

# 设置工作目录（这里假设Go程序将放在/app目录下进行编译和后续运行等操作，可按需修改）
WORKDIR /app

COPY BaiduPCS-Go /app/BaiduPCS-Go

WORKDIR /app/BaiduPCS-Go
RUN ls
RUN go vet
RUN go mod tidy
RUN go mod vendor
RUN go build -o BaiduPCS main.go

FROM golang:1.23.3-bookworm

LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 更换完整源
COPY debian.sources /etc/apt/sources.list.d/debian.sources

# 更新软件包并安装依赖
RUN apt update && \
    apt install -y --no-install-recommends \
    python3 python3-pip translate-shell ffmpeg ca-certificates \
    bsdmainutils sqlite3 gawk locales libfribidi-bin dos2unix p7zip-full \
    wget curl build-essential mediainfo openssh-server nano axel aria2 htop btop && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 复制文件
COPY danmaku2ass/danmaku2ass.py /usr/local/bin/danmaku2ass

# 从第一阶段复制编译好的二进制文件到最终镜像中
COPY --from=builder /app/BaiduPCS-Go/BaiduPCS /usr/local/bin/BaiduPCS

# 设置权限
RUN chmod a+rwx /usr/local/bin/danmaku2ass

# 安装 openai-whisper 和 yt-dlp
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip install --no-cache-dir openai-whisper yt-dlp

# 配置 Go 环境
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GOBIN=/go/bin

# 中文支持
RUN apt update && \
    apt install -y --no-install-recommends locales && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8

# 天朝特色：更换源
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    pip install -i https://mirrors.ustc.edu.cn/pypi/simple pip -U && \
    pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple

# 设置环境变量
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置 root 密码
RUN echo "root:123456" | chpasswd

# 允许 root 登录 SSH
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# 设置其他环境变量
ENV PATH="$PATH:/usr/local/go/bin"

# 启动 SSH 服务
WORKDIR /
ENTRYPOINT ["service", "ssh", "start", "-D"]
