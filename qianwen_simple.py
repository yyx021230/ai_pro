#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
调用阿里云 DashScope 千问模型（OpenAI 兼容模式）。
文档: https://help.aliyun.com/zh/model-studio/developer-reference/compatibility-of-openai-with-dashscope

使用前设置环境变量:
  export DASHSCOPE_API_KEY='sk-20eb938340634f69a4d5871e4b81e861'
"""

import json
import os
import sys
from typing import Optional

import requests

# 北京地域 OpenAI 兼容接口
DASHSCOPE_CHAT_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
# 千问 3.6 Plus（与控制台「模型」名称一致，需在百炼开通）
MODEL_QWEN_36_PLUS = "qwen3.6-plus"


def call_qianwen(
    prompt: str,
    api_key: Optional[str] = None,
    model: str = MODEL_QWEN_36_PLUS,
) -> str:
    """调用千问模型 (OpenAI 兼容 Chat Completions)."""
    key = api_key or os.environ.get("DASHSCOPE_API_KEY")
    if not key or not key.strip():
        return "错误: 未设置 API Key。请设置环境变量 DASHSCOPE_API_KEY 或传入 api_key 参数。"

    headers = {
        "Authorization": f"Bearer {key.strip()}",
        "Content-Type": "application/json",
    }

    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "top_p": 0.9,
    }

    try:
        response = requests.post(
            DASHSCOPE_CHAT_URL,
            headers=headers,
            json=data,
            timeout=120,
        )
        if response.status_code != 200:
            return f"API错误 (状态码 {response.status_code}): {response.text}"

        result = response.json()
        if "choices" in result and result["choices"]:
            return result["choices"][0]["message"]["content"]
        return f"未知响应结构: {json.dumps(result, ensure_ascii=False)}"

    except requests.RequestException as e:
        return f"网络错误: {e}"
    except Exception as e:
        return f"系统错误: {e}"


if __name__ == "__main__":
    key = os.environ.get("DASHSCOPE_API_KEY")
    if not key:
        print("请先设置: export DASHSCOPE_API_KEY='你的密钥'", file=sys.stderr)
        sys.exit(1)

    questions = ["你好，请用一两句话自我介绍一下。"]

    print("千问 API (compatible-mode) 测试 — 模型:", MODEL_QWEN_36_PLUS, "\n")

    for i, question in enumerate(questions, 1):
        print(f"问题 {i}: {question}")
        answer = call_qianwen(question, key)
        print(f"回答: {answer}")
        print("-" * 60)
