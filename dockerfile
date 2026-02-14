# 第一阶段：使用 Golang 编译 BaiduPCS
FROM golang:latest AS builder1
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

COPY BaiduPCS-Go /BaiduPCS-Go
WORKDIR /BaiduPCS-Go

# 合并检查、更新依赖和构建操作
RUN ls && go vet && go mod tidy && go mod vendor && go build -o BaiduPCS main.go

# 第二阶段：使用 Golang 编译 tdl
FROM golang:latest AS builder2
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

COPY tdl-go /tdl-go
WORKDIR /tdl-go

# 合并检查、更新依赖和构建操作
RUN ls && go vet && go mod tidy && go build -o tdl main.go

# 第三阶段：使用 Golang 编译 VideoDualEmbed
FROM golang:latest AS builder3
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

COPY VideoDualEmbed /VideoDualEmbed
WORKDIR /VideoDualEmbed

# 合并检查、更新依赖和构建操作
RUN ls && go vet && go mod tidy && go build -o vde main.go

# 最终阶段：构建运行环境
FROM golang:latest
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 配置软件源
RUN sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/' \
    /etc/apt/sources.list.d/debian.sources

# 更新系统并安装基础依赖
RUN apt update && \
    apt full-upgrade -y && \
    # 基础系统工具
    apt install -y --no-install-recommends \
        python3 python3-pip \
        ca-certificates \
        bsdmainutils \
        sqlite3 \
        gawk \
        locales \
        wget \
        curl \
        gnupg && \
    # 多媒体处理工具
    apt install -y --no-install-recommends \
        ffmpeg \
        mediainfo \
        libavif-bin && \
    # 文本处理和转换工具
    apt install -y --no-install-recommends \
        translate-shell \
        libfribidi-bin \
        dos2unix \
        p7zip-full && \
    # 开发工具
    apt install -y --no-install-recommends \
        build-essential \
        npm && \
    # 系统监控工具
    apt install -y --no-install-recommends \
        htop \
        btop && \
    # 下载工具
    apt install -y --no-install-recommends \
        axel \
        aria2 && \
    # 编辑器和服务器
    apt install -y --no-install-recommends \
        nano \
        openssh-server && \
    # 中文字体
    apt install -y --no-install-recommends \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        fonts-noto-cjk && \
    # 清理缓存
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 安装 Node.js 工具
RUN npm install -g deno && \
    deno --version

# 复制编译好的二进制文件
COPY --from=builder1 /BaiduPCS-Go/BaiduPCS /usr/local/bin/BaiduPCS
COPY --from=builder2 /tdl-go/tdl /usr/local/bin/tdl
COPY --from=builder3 /VideoDualEmbed/vde /usr/local/bin/vde

# 安装 Python 依赖
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED || true && \
    pip install --break-system-packages --no-cache-dir openai-whisper && \
    pip install --break-system-packages --no-cache-dir -U --pre yt-dlp[default]

# 配置 Go 环境变量
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GOBIN=/go/bin

# 配置中文语言支持
RUN apt update && \
    apt install -y --no-install-recommends locales && \
    echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    # 清理缓存
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 配置国内镜像源
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple

# 设置环境变量
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    PATH="$PATH:/usr/local/go/bin"

# 配置 SSH 服务
RUN echo "root:123456" | chpasswd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# 更新 apt 缓存
RUN apt update

# 启动 SSH 服务
WORKDIR /
ENTRYPOINT ["service", "ssh", "start", "-D"]
