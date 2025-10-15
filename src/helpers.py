"""
Utility functions for the application
"""

import sys
import time
import logging
import structlog
from contextlib import contextmanager
from functools import wraps
from typing import Callable, Any, Optional
try:
    from .config import settings
except ImportError:
    from config import settings


# 配置structlog
def configure_structlog():
    """配置structlog日志系统"""
    processors = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=False),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]
    
    # 根据日志级别选择渲染器
    if settings.LOG_LEVEL == "debug":
        # 调试模式：使用彩色控制台输出
        processors.append(structlog.dev.ConsoleRenderer())
        log_level = logging.DEBUG
    elif settings.LOG_LEVEL == "info":
        # 信息模式：使用彩色控制台输出
        processors.append(structlog.dev.ConsoleRenderer())
        log_level = logging.INFO
    else:  # false
        # 禁用模式：使用JSON格式输出（但实际不会输出）
        processors.append(structlog.processors.JSONRenderer())
        log_level = logging.CRITICAL  # 只输出致命错误
    
    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(log_level),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(file=sys.stdout),
        cache_logger_on_first_use=True,
    )


# 初始化structlog
configure_structlog()

# 获取全局logger实例
_logger = structlog.get_logger()


def error_log(message: str, *args, **kwargs) -> None:
    """
    错误日志记录函数（所有级别都输出）
    
    Args:
        message: 日志消息
        *args: 消息格式化参数（兼容旧版）
        **kwargs: 额外的结构化上下文字段
    """
    # 格式化消息（兼容旧版用法）
    if args:
        formatted_message = message % args
    else:
        formatted_message = message
    
    # 使用structlog记录错误日志
    _logger.error(formatted_message, **kwargs)


def info_log(message: str, *args, **kwargs) -> None:
    """
    信息日志记录函数（info和debug级别输出）
    
    Args:
        message: 日志消息
        *args: 消息格式化参数（兼容旧版）
        **kwargs: 额外的结构化上下文字段
    """
    if settings.LOG_LEVEL in ["info", "debug"]:
        # 格式化消息（兼容旧版用法）
        if args:
            formatted_message = message % args
        else:
            formatted_message = message
        
        # 使用structlog记录信息日志
        _logger.info(formatted_message, **kwargs)


def debug_log(message: str, *args, **kwargs) -> None:
    """
    调试日志记录函数（仅debug级别输出）
    
    Args:
        message: 日志消息
        *args: 消息格式化参数（兼容旧版）
        **kwargs: 额外的结构化上下文字段
    """
    if settings.LOG_LEVEL == "debug":
        # 格式化消息（兼容旧版用法）
        if args:
            formatted_message = message % args
        else:
            formatted_message = message
        
        # 使用structlog记录调试日志
        _logger.debug(formatted_message, **kwargs)


def get_logger(name: str = None):
    """
    获取一个structlog logger实例
    
    Args:
        name: logger名称（可选）
        
    Returns:
        structlog BoundLogger实例
    """
    if name:
        return structlog.get_logger(name)
    return _logger


def log_http_request(method: str, url: str, headers: dict, body: Any = None, request_id: str = None) -> None:
    """
    记录详细的HTTP请求信息（用于调试405等错误）
    
    Args:
        method: HTTP方法 (GET, POST, etc.)
        url: 请求URL
        headers: 请求头字典
        body: 请求体（将被截断或隐藏敏感信息）
        request_id: 可选的请求ID用于追踪
    """
    import json
    
    # 隐藏敏感header
    safe_headers = headers.copy()
    sensitive_keys = ['authorization', 'cookie', 'x-auth-token', 'x-api-key']
    for key in list(safe_headers.keys()):
        if key.lower() in sensitive_keys:
            safe_headers[key] = '[REDACTED]'
    
    # 截断body（避免日志过大）
    safe_body = None
    if body is not None:
        try:
            body_str = json.dumps(body) if not isinstance(body, str) else body
            if len(body_str) > 500:
                safe_body = body_str[:500] + "... [truncated]"
            else:
                safe_body = body_str
        except:
            safe_body = str(body)[:500]
    
    info_log(
        "📤 Outgoing HTTP Request",
        request_id=request_id,
        method=method,
        url=url,
        headers=safe_headers,
        body_preview=safe_body
    )


def log_http_response(status_code: int, headers: dict, body: Any = None, request_id: str = None, error: bool = False) -> None:
    """
    记录详细的HTTP响应信息（用于调试405等错误）
    
    Args:
        status_code: HTTP状态码
        headers: 响应头字典
        body: 响应体（将被截断）
        request_id: 可选的请求ID用于追踪
        error: 是否为错误响应
    """
    # 截断body
    safe_body = None
    if body is not None:
        body_str = body if isinstance(body, str) else str(body)
        if len(body_str) > 1000:
            safe_body = body_str[:1000] + "... [truncated]"
        else:
            safe_body = body_str
    
    log_func = error_log if error or status_code >= 400 else info_log
    log_func(
        "📥 HTTP Response Received",
        request_id=request_id,
        status_code=status_code,
        is_error=status_code >= 400,
        headers=dict(headers) if headers else {},
        body_preview=safe_body
    )


def validate_http_request(url: str, headers: dict, method: str = "POST") -> list:
    """
    验证HTTP请求的URL和headers是否正确（用于调试405等错误）
    
    Args:
        url: 请求URL
        headers: 请求头字典
        method: HTTP方法
        
    Returns:
        问题列表（空列表表示无问题）
    """
    issues = []
    
    # 验证URL
    if not url:
        issues.append("❌ URL is empty")
    elif not url.startswith(("http://", "https://")):
        issues.append(f"❌ URL does not start with http:// or https://: {url}")
    elif "chat.z.ai" not in url:
        issues.append(f"⚠️  URL does not contain chat.z.ai: {url}")
    
    # 验证HTTP方法
    if method.upper() != "POST":
        issues.append(f"❌ HTTP method is not POST: {method}")
    
    # 验证必需的headers
    required_headers = {
        "content-type": "application/json",
        "accept": "*/*"
    }
    
    headers_lower = {k.lower(): v for k, v in headers.items()}
    
    for req_header, expected_value in required_headers.items():
        if req_header not in headers_lower:
            issues.append(f"❌ Missing required header: {req_header}")
        elif expected_value and expected_value not in headers_lower[req_header].lower():
            issues.append(f"⚠️  Header {req_header} may have wrong value: {headers_lower[req_header]}")
    
    # 检查建议的headers
    recommended_headers = ["user-agent", "origin", "referer"]
    for rec_header in recommended_headers:
        if rec_header not in headers_lower:
            issues.append(f"⚠️  Missing recommended header: {rec_header}")
    
    # 检查可疑的header值
    for key, value in headers.items():
        if not value or value.strip() == "":
            issues.append(f"⚠️  Empty header value for: {key}")
    
    return issues


# ============================================================================
# 性能追踪工具
# ============================================================================

@contextmanager
def perf_timer(operation_name: str, log_result: bool = True, threshold_ms: float = 0):
    """
    性能计时上下文管理器
    
    Args:
        operation_name: 操作名称
        log_result: 是否记录结果到日志
        threshold_ms: 仅记录超过此阈值的操作（毫秒），0表示记录所有
        
    Yields:
        包含elapsed_ms的字典，可在上下文中使用
        
    Example:
        with perf_timer("token_decode") as timer:
            result = decode_token(token)
        print(f"耗时: {timer['elapsed_ms']:.2f}ms")
    """
    timer_dict = {"elapsed_ms": 0, "elapsed_s": 0}
    start_time = time.perf_counter()
    
    try:
        yield timer_dict
    finally:
        elapsed_s = time.perf_counter() - start_time
        elapsed_ms = elapsed_s * 1000
        timer_dict["elapsed_ms"] = elapsed_ms
        timer_dict["elapsed_s"] = elapsed_s
        
        if log_result and elapsed_ms >= threshold_ms:
            debug_log(
                f"⏱️ {operation_name}",
                elapsed_ms=f"{elapsed_ms:.2f}ms",
                elapsed_s=f"{elapsed_s:.4f}s"
            )


def perf_track(operation_name: Optional[str] = None, log_result: bool = True, threshold_ms: float = 0):
    """
    性能追踪装饰器
    
    Args:
        operation_name: 操作名称，默认使用函数名
        log_result: 是否记录结果到日志
        threshold_ms: 仅记录超过此阈值的操作（毫秒），0表示记录所有
        
    Example:
        @perf_track("decode_jwt")
        def decode_token(token):
            ...
    """
    def decorator(func: Callable) -> Callable:
        op_name = operation_name or func.__name__
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs) -> Any:
            with perf_timer(op_name, log_result, threshold_ms) as timer:
                result = func(*args, **kwargs)
            return result
        
        @wraps(func)
        async def async_wrapper(*args, **kwargs) -> Any:
            with perf_timer(op_name, log_result, threshold_ms) as timer:
                result = await func(*args, **kwargs)
            return result
        
        # 根据函数类型返回相应的wrapper
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper
    
    return decorator
