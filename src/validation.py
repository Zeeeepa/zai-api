#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Schema Validation Module for Z.AI Web Interface
Validates requests, responses, signatures, and headers
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

try:
    import jsonschema
    from jsonschema import validate, ValidationError as JSONSchemaValidationError
    JSONSCHEMA_AVAILABLE = True
except ImportError:
    JSONSCHEMA_AVAILABLE = False
    print("[WARNING] jsonschema not installed. Run: pip install jsonschema")

from .signature import decode_jwt_payload, generate_signature, extract_user_id_from_token
from .helpers import debug_log, error_log


class ValidationSeverity(Enum):
    """Validation error severity levels"""
    CRITICAL = "critical"  # Blocks request
    ERROR = "error"        # Should be fixed
    WARNING = "warning"    # Recommended fix
    INFO = "info"          # Informational


@dataclass
class ValidationResult:
    """Result of validation operation"""
    valid: bool
    errors: List[Dict[str, Any]]
    warnings: List[Dict[str, Any]]
    info: List[Dict[str, Any]]
    
    def __bool__(self):
        return self.valid
    
    def has_errors(self) -> bool:
        return len(self.errors) > 0
    
    def has_warnings(self) -> bool:
        return len(self.warnings) > 0
    
    def get_all_messages(self) -> List[str]:
        """Get all validation messages as strings"""
        messages = []
        for error in self.errors:
            messages.append(f"❌ ERROR: {error['message']}")
        for warning in self.warnings:
            messages.append(f"⚠️  WARNING: {warning['message']}")
        for info in self.info:
            messages.append(f"ℹ️  INFO: {info['message']}")
        return messages


class ValidationError(Exception):
    """Base validation error"""
    def __init__(self, message: str, field_path: str = None, severity: ValidationSeverity = ValidationSeverity.ERROR):
        self.message = message
        self.field_path = field_path
        self.severity = severity
        super().__init__(message)


class SchemaValidationError(ValidationError):
    """Schema validation error"""
    pass


class SignatureValidationError(ValidationError):
    """Signature validation error"""
    pass


class HeaderValidationError(ValidationError):
    """Header validation error"""
    pass


class TokenValidationError(ValidationError):
    """Token validation error"""
    pass


def load_schema(schema_name: str) -> Optional[Dict[str, Any]]:
    """Load JSON schema from schemas directory"""
    schema_path = Path(__file__).parent.parent / "schemas" / f"{schema_name}.json"
    
    if not schema_path.exists():
        error_log(f"Schema file not found: {schema_path}")
        return None
    
    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        error_log(f"Failed to load schema {schema_name}: {e}")
        return None


def validate_zai_request(request_data: Dict[str, Any]) -> ValidationResult:
    """
    Validate Z.AI web interface request
    
    Args:
        request_data: Complete request dict with 'body' and 'config'
        
    Returns:
        ValidationResult with errors, warnings, and info
    """
    errors = []
    warnings = []
    info = []
    
    if not JSONSCHEMA_AVAILABLE:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "jsonschema library not available",
            "field": "system"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Load schema
    schema = load_schema("zai_web_request")
    if not schema:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "Could not load zai_web_request schema",
            "field": "schema"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Validate against JSON schema
    try:
        validate(instance=request_data, schema=schema["definitions"]["CompleteRequest"])
        info.append({
            "severity": ValidationSeverity.INFO.value,
            "message": "Request structure is valid",
            "field": "structure"
        })
    except JSONSchemaValidationError as e:
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Schema validation failed: {e.message}",
            "field": ".".join(str(p) for p in e.path) if e.path else "root",
            "expected": str(e.schema.get("type")) if hasattr(e, "schema") else None
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Additional validation checks
    body = request_data.get("body", {})
    config = request_data.get("config", {})
    
    # Check model ID is valid
    valid_models = ["0727-360B-API", "0727-106B-API", "glm-4.5v", "GLM-4-6-API-V1"]
    if body.get("model") not in valid_models:
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Invalid model ID: {body.get('model')}",
            "field": "body.model",
            "expected": valid_models
        })
    
    # Check messages not empty
    if not body.get("messages"):
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": "Messages array is empty",
            "field": "body.messages"
        })
    
    # Check signature exists in headers
    headers = config.get("headers", {})
    if "X-Signature" not in headers:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "Missing X-Signature header",
            "field": "config.headers.X-Signature"
        })
    elif not re.match(r'^[a-f0-9]{64}$', headers["X-Signature"]):
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": "Invalid signature format (expected 64-char hex)",
            "field": "config.headers.X-Signature"
        })
    
    # Check Authorization header
    if "Authorization" not in headers:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "Missing Authorization header",
            "field": "config.headers.Authorization"
        })
    elif not headers["Authorization"].startswith("Bearer "):
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": "Authorization must start with 'Bearer '",
            "field": "config.headers.Authorization"
        })
    
    valid = len(errors) == 0
    return ValidationResult(valid=valid, errors=errors, warnings=warnings, info=info)


def validate_zai_response(response_chunk: Dict[str, Any]) -> ValidationResult:
    """
    Validate Z.AI web interface response chunk
    
    Args:
        response_chunk: SSE chunk data
        
    Returns:
        ValidationResult
    """
    errors = []
    warnings = []
    info = []
    
    if not JSONSCHEMA_AVAILABLE:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "jsonschema library not available",
            "field": "system"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Load schema
    schema = load_schema("zai_web_response")
    if not schema:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "Could not load zai_web_response schema",
            "field": "schema"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Validate against JSON schema
    try:
        validate(instance=response_chunk, schema=schema["definitions"]["StreamingChunk"])
        info.append({
            "severity": ValidationSeverity.INFO.value,
            "message": "Response chunk structure is valid",
            "field": "structure"
        })
    except JSONSchemaValidationError as e:
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Schema validation failed: {e.message}",
            "field": ".".join(str(p) for p in e.path) if e.path else "root"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Additional checks
    chunk_type = response_chunk.get("type")
    if chunk_type == "chat:error":
        data = response_chunk.get("data", {})
        error_msg = data.get("error", {}).get("message", "Unknown error")
        warnings.append({
            "severity": ValidationSeverity.WARNING.value,
            "message": f"Error response: {error_msg}",
            "field": "data.error.message"
        })
    
    valid = len(errors) == 0
    return ValidationResult(valid=valid, errors=errors, warnings=warnings, info=info)


def validate_signature(
    token: str,
    request_id: str,
    timestamp: int,
    user_content: str,
    expected_signature: str,
    secret: str = None
) -> ValidationResult:
    """
    Validate Z.AI double HMAC-SHA256 signature
    
    Args:
        token: JWT token
        request_id: Request ID
        timestamp: Timestamp in milliseconds
        user_content: Last user message content
        expected_signature: Signature to validate against
        secret: Signing secret (default from env)
        
    Returns:
        ValidationResult
    """
    errors = []
    warnings = []
    info = []
    
    try:
        # Extract user_id from token
        user_id = extract_user_id_from_token(token)
        if user_id == "guest":
            warnings.append({
                "severity": ValidationSeverity.WARNING.value,
                "message": "Using guest user_id (token decode failed)",
                "field": "user_id"
            })
        
        # Generate signature
        computed_signature = generate_signature(
            message_text=user_content,
            request_id=request_id,
            timestamp_ms=timestamp,
            user_id=user_id,
            secret=secret
        )
        
        # Compare signatures
        if computed_signature == expected_signature:
            info.append({
                "severity": ValidationSeverity.INFO.value,
                "message": "Signature is valid",
                "field": "signature"
            })
        else:
            errors.append({
                "severity": ValidationSeverity.CRITICAL.value,
                "message": "Signature mismatch",
                "field": "signature",
                "expected": computed_signature,
                "actual": expected_signature
            })
        
        # Check timestamp validity (within 5-minute window)
        import time
        current_time = int(time.time() * 1000)
        time_diff = abs(current_time - timestamp)
        if time_diff > 300000:  # 5 minutes
            warnings.append({
                "severity": ValidationSeverity.WARNING.value,
                "message": f"Timestamp is {time_diff/1000:.0f}s old (>5min window)",
                "field": "timestamp"
            })
        
    except Exception as e:
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Signature validation failed: {str(e)}",
            "field": "signature"
        })
    
    valid = len(errors) == 0
    return ValidationResult(valid=valid, errors=errors, warnings=warnings, info=info)


def validate_headers(headers: Dict[str, str], check_browser_like: bool = True) -> ValidationResult:
    """
    Validate HTTP headers for Z.AI requests
    
    Args:
        headers: HTTP headers dict
        check_browser_like: Whether to validate browser-like headers
        
    Returns:
        ValidationResult
    """
    errors = []
    warnings = []
    info = []
    
    # Required headers
    required_headers = [
        "Authorization",
        "Content-Type",
        "Origin",
        "Referer",
        "User-Agent",
        "X-Fe-Version",
        "X-Signature"
    ]
    
    for header in required_headers:
        if header not in headers:
            errors.append({
                "severity": ValidationSeverity.CRITICAL.value,
                "message": f"Missing required header: {header}",
                "field": f"headers.{header}"
            })
    
    # Validate header values
    if "Origin" in headers and headers["Origin"] != "https://chat.z.ai":
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Invalid Origin: {headers['Origin']}",
            "field": "headers.Origin",
            "expected": "https://chat.z.ai"
        })
    
    if "Referer" in headers:
        if not headers["Referer"].startswith("https://chat.z.ai"):
            errors.append({
                "severity": ValidationSeverity.ERROR.value,
                "message": f"Invalid Referer: {headers['Referer']}",
                "field": "headers.Referer",
                "expected": "https://chat.z.ai/*"
            })
    
    if "Content-Type" in headers and headers["Content-Type"] != "application/json":
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Invalid Content-Type: {headers['Content-Type']}",
            "field": "headers.Content-Type",
            "expected": "application/json"
        })
    
    # Browser-like checks
    if check_browser_like:
        if "User-Agent" in headers:
            ua = headers["User-Agent"]
            if not any(browser in ua for browser in ["Chrome", "Firefox", "Safari", "Edge"]):
                warnings.append({
                    "severity": ValidationSeverity.WARNING.value,
                    "message": "User-Agent doesn't look browser-like",
                    "field": "headers.User-Agent"
                })
        
        # Check for sec-ch-ua headers (modern browsers)
        if "sec-ch-ua" not in headers and "Sec-Ch-Ua" not in headers:
            warnings.append({
                "severity": ValidationSeverity.WARNING.value,
                "message": "Missing sec-ch-ua header (expected in modern browsers)",
                "field": "headers.sec-ch-ua"
            })
    
    valid = len(errors) == 0
    return ValidationResult(valid=valid, errors=errors, warnings=warnings, info=info)


def validate_token(token: str) -> ValidationResult:
    """
    Validate JWT token format and content
    
    Args:
        token: JWT token string
        
    Returns:
        ValidationResult
    """
    errors = []
    warnings = []
    info = []
    
    if not token:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": "Token is empty",
            "field": "token"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Check JWT format (3 parts separated by dots)
    parts = token.split(".")
    if len(parts) != 3:
        errors.append({
            "severity": ValidationSeverity.CRITICAL.value,
            "message": f"Invalid JWT format (expected 3 parts, got {len(parts)})",
            "field": "token"
        })
        return ValidationResult(valid=False, errors=errors, warnings=warnings, info=info)
    
    # Try to decode payload
    try:
        payload = decode_jwt_payload(token)
        if not payload:
            errors.append({
                "severity": ValidationSeverity.ERROR.value,
                "message": "Failed to decode JWT payload",
                "field": "token.payload"
            })
        else:
            info.append({
                "severity": ValidationSeverity.INFO.value,
                "message": "Token decoded successfully",
                "field": "token"
            })
            
            # Check for user_id fields
            user_id_fields = ["id", "user_id", "uid", "sub"]
            has_user_id = any(field in payload for field in user_id_fields)
            if not has_user_id:
                warnings.append({
                    "severity": ValidationSeverity.WARNING.value,
                    "message": f"No user_id field found in token (tried: {user_id_fields})",
                    "field": "token.payload"
                })
            
            # Check expiration
            if "exp" in payload:
                import time
                current_time = int(time.time())
                if payload["exp"] < current_time:
                    errors.append({
                        "severity": ValidationSeverity.CRITICAL.value,
                        "message": "Token has expired",
                        "field": "token.exp",
                        "expired_at": payload["exp"],
                        "current_time": current_time
                    })
    except Exception as e:
        errors.append({
            "severity": ValidationSeverity.ERROR.value,
            "message": f"Token validation failed: {str(e)}",
            "field": "token"
        })
    
    valid = len(errors) == 0
    return ValidationResult(valid=valid, errors=errors, warnings=warnings, info=info)


def print_validation_result(result: ValidationResult, title: str = "Validation Result"):
    """Pretty print validation result"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"✅ Valid: {result.valid}")
    print(f"❌ Errors: {len(result.errors)}")
    print(f"⚠️  Warnings: {len(result.warnings)}")
    print(f"ℹ️  Info: {len(result.info)}")
    
    if result.errors:
        print(f"\n❌ ERRORS:")
        for error in result.errors:
            print(f"  • {error['message']}")
            if 'field' in error:
                print(f"    Field: {error['field']}")
    
    if result.warnings:
        print(f"\n⚠️  WARNINGS:")
        for warning in result.warnings:
            print(f"  • {warning['message']}")
            if 'field' in warning:
                print(f"    Field: {warning['field']}")
    
    if result.info:
        print(f"\nℹ️  INFO:")
        for info_item in result.info:
            print(f"  • {info_item['message']}")
    
    print(f"{'='*60}\n")

