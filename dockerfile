# 最终阶段：构建运行环境
FROM debian:trixie
LABEL authors="zen"
ARG TARGETARCH
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
# baidupcs固定连接不可更改
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /tmp/BaiduPCS.zip "https://github.com/qjfoidnh/BaiduPCS-Go/releases/download/v4.0.1/BaiduPCS-Go-v4.0.1-linux-amd64.zip" && \
      cd /tmp && unzip -o BaiduPCS.zip && \
      find /tmp -name "BaiduPCS-Go" -type f -executable -exec mv {} /usr/local/bin/BaiduPCS \;; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /tmp/BaiduPCS.zip "https://github.com/qjfoidnh/BaiduPCS-Go/releases/latest/download/BaiduPCS-Go-linux-arm64.zip" && \
      cd /tmp && unzip -o BaiduPCS.zip && \
      find /tmp -name "BaiduPCS-Go" -type f -executable -exec mv {} /usr/local/bin/BaiduPCS \;; \
    fi && \
    chmod +x /usr/local/bin/BaiduPCS && \
    rm -rf /tmp/BaiduPCS.zip /tmp/BaiduPCS-Go*
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /tmp/tdl.tar.gz "https://github.com/iyear/tdl/releases/latest/download/tdl_Linux_64bit.tar.gz" && \
      tar -xzf /tmp/tdl.tar.gz -C /tmp tdl && \
      mv /tmp/tdl /usr/local/bin/tdl; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /tmp/tdl.tar.gz "https://github.com/iyear/tdl/releases/latest/download/tdl_Linux_arm64.tar.gz" && \
      tar -xzf /tmp/tdl.tar.gz -C /tmp tdl && \
      mv /tmp/tdl /usr/local/bin/tdl; \
    fi && \
    chmod +x /usr/local/bin/tdl && \
    rm -f /tmp/tdl.tar.gz
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /usr/local/bin/vde "https://github.com/zhangyiming748/VideoDualEmbed/releases/latest/download/vde_linux_amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /usr/local/bin/vde "https://github.com/zhangyiming748/VideoDualEmbed/releases/latest/download/vde_linux_arm64"; \
    fi && \
    chmod +x /usr/local/bin/vde
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /usr/local/bin/vbc "https://github.com/zhangyiming748/VideoBatchCut/releases/latest/download/vbc_linux_amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /usr/local/bin/vbc "https://github.com/zhangyiming748/VideoBatchCut/releases/latest/download/vbc_linux_arm64"; \
    fi && \
    chmod +x /usr/local/bin/vbc
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /usr/local/bin/my-tdl "https://github.com/zhangyiming748/FastTdl/releases/latest/download/my-tdl_linux_amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /usr/local/bin/my-tdl "https://github.com/zhangyiming748/FastTdl/releases/latest/download/my-tdl_linux_arm64"; \
    fi && \
    chmod +x /usr/local/bin/my-tdl

RUN if [ "$TARGETARCH" = "amd64" ]; then \
      wget -O /usr/local/bin/avmerge "https://github.com/zhangyiming748/AVmerger/releases/latest/download/avmerge_linux_amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      wget -O /usr/local/bin/avmerge "https://github.com/zhangyiming748/AVmerger/releases/latest/download/avmerge_linux_arm64"; \
    fi && \
    chmod +x /usr/local/bin/avmerge


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
