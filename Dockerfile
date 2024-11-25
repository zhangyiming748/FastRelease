FROM golang:1.23.2-bookworm

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
    wget curl build-essential mediainfo openssh-server nano axel aria2 htop btop bash-completion && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 复制文件
COPY baidupcs_amd64.zip /root/
COPY baidupcs_arm64.zip /root/
COPY danmaku2ass/danmaku2ass.py /usr/local/bin/danmaku2ass

# 设置权限
RUN chmod a+rwx /usr/local/bin/danmaku2ass

# 安装 openai-whisper 和 yt-dlp
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip install --no-cache-dir openai-whisper yt-dlp

# 配置 Go 环境
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GOBIN=/go/bin

# 安装gvm
RUN bash -c " \
    export GVM_ROOT='/usr/local/gvm'; \
    \curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash; \
    source $GVM_ROOT/scripts/gvm; \
    gvm install go1.18; \
    gvm use go1.18; \
    "
# 复制BaiduPCS仓库
COPY BaiduPCS /root/BaiduPCS
WORKDIR /root/BaiduPCS
RUN source $GVM_ROOT/scripts/gvm \
    && gvm use go1.18 \
    && go build -o /usr/local/bin/BaiduPCS main.go
RUN source $GVM_ROOT/scripts/gvm \
    && gvm use go1.23.3
    
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

# 配置终端代码补全
RUN echo "source /etc/bash_completion" >> ~/.bashrc

# 启动 SSH 服务
WORKDIR /
ENTRYPOINT ["service", "ssh", "start", "-D"]
