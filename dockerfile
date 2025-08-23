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
RUN ls && go vet && go mod tidy  && go build -o tdl main.go

# 第三阶段：构建最终镜像
FROM golang:latest
LABEL authors="zen"

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 更换完整源
COPY debian.sources /etc/apt/sources.list.d/debian.sources

# 更新软件包、安装依赖并清理无用文件
RUN apt update 
RUN apt full-upgrade -y
RUN apt install -y --no-install-recommends python3 python3-pip python3-distutils
RUN apt install -y --no-install-recommends translate-shell
RUN apt install -y --no-install-recommends ffmpeg
RUN apt install -y --no-install-recommends ca-certificates
RUN apt install -y --no-install-recommends bsdmainutils
RUN apt install -y --no-install-recommends sqlite3
RUN apt install -y --no-install-recommends gawk
RUN apt install -y --no-install-recommends locales
RUN apt install -y --no-install-recommends libfribidi-bin
RUN apt install -y --no-install-recommends dos2unix
RUN apt install -y --no-install-recommends p7zip-full
RUN apt install -y --no-install-recommends wget
RUN apt install -y --no-install-recommends curl
RUN apt install -y --no-install-recommends build-essential
RUN apt install -y --no-install-recommends mediainfo
RUN apt install -y --no-install-recommends openssh-server
RUN apt install -y --no-install-recommends nano
RUN apt install -y --no-install-recommends axel
RUN apt install -y --no-install-recommends aria2
RUN apt install -y --no-install-recommends htop
RUN apt install -y --no-install-recommends btop
RUN apt install -y --no-install-recommends fonts-wqy-microhei
RUN apt install -y --no-install-recommends fonts-wqy-zenhei
RUN apt install -y --no-install-recommends fonts-noto-cjk

# 从第一阶段复制编译好的二进制文件到最终图像中
COPY --from=builder1 /BaiduPCS-Go/BaiduPCS /usr/local/bin/BaiduPCS

# 从第二阶段复制编译好的二进制文件到最终图像中
COPY --from=builder2 /tdl-go/tdl /usr/local/bin/tdl

# 安装 openai-whisper 和 yt-dlp
RUN rm /usr/lib/python3.11/EXTERNALLY-MANAGED || true && \
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
    update-locale LANG=zh_CN.UTF-8 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*


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

# 重新构建apt缓存
RUN apt update 

# 启动 SSH 服务
WORKDIR /
ENTRYPOINT ["service", "ssh", "start", "-D"]
