#!/usr/bin/env bash
#
# 批量下载：遍历网址文件，每行一个链接，执行 yt-dlp，每个链接最多重试 3 次
# 网址文件固定为 ytdlp.xtt
#
set -uo pipefail

URL_FILE="ytdlp.txt"
COOKIES="pornhub.cookies"
FORMAT="bestvideo+bestaudio/best"
MAX_RETRY=3

if [[ ! -f "$URL_FILE" ]]; then
  echo "找不到网址文件：$URL_FILE" >&2
  exit 1
fi

while IFS= read -r url || [[ -n "$url" ]]; do
  [[ -z "$url" ]] && continue          # 跳过空行

  echo "==============================="
  echo "下载：$url"

  for attempt in $(seq 1 "$MAX_RETRY"); do
    echo "第 $attempt/$MAX_RETRY 次尝试"
    if yt-dlp --cookies "$COOKIES" -f "$FORMAT" "$url"; then
      echo "成功：$url"
      break
    fi
    echo "失败，重试..."
    [[ "$attempt" -eq "$MAX_RETRY" ]] && echo "放弃：$url"
  done
done < "$URL_FILE"

echo "==============================="
echo "全部处理完成"
