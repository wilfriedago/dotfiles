"""Shared utilities for Fineract code generators."""

import os
import re
from typing import List, Tuple


def parse_fields(fields_str: str) -> List[Tuple[str, str]]:
    """Parse 'name:Type,desc:Type' into [(name, type), ...]."""
    if not fields_str:
        return []
    result = []
    for f in fields_str.split(","):
        f = f.strip()
        if ":" not in f:
            raise ValueError(f"Invalid field format: '{f}'. Expected 'name:Type'")
        name, typ = f.split(":", 1)
        # Handle optional length spec like String:100
        typ = typ.split(":")[0]
        result.append((name.strip(), typ.strip()))
    return result


def parse_fields_with_length(fields_str: str) -> List[Tuple[str, str, str]]:
    """Parse 'name:Type:length' into [(name, type, length), ...]."""
    if not fields_str:
        return []
    result = []
    for f in fields_str.split(","):
        parts = [p.strip() for p in f.strip().split(":")]
        if len(parts) < 2:
            raise ValueError(f"Invalid field: '{f}'. Expected 'name:Type[:length]'")
        name = parts[0]
        typ = parts[1]
        length = parts[2] if len(parts) > 2 else None
        result.append((name, typ, length))
    return result


def to_snake_case(name: str) -> str:
    """PascalCase/camelCase to snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()


def to_upper_snake(name: str) -> str:
    """PascalCase to UPPER_SNAKE_CASE."""
    return to_snake_case(name).upper()


def to_camel_case(name: str) -> str:
    """PascalCase to camelCase."""
    if not name:
        return name
    return name[0].lower() + name[1:]


def package_to_path(package: str) -> str:
    """Convert Java package to directory path."""
    return package.replace(".", "/")


def write_file(output_dir: str, sub_path: str, content: str):
    """Write content to output_dir/sub_path, creating dirs as needed."""
    full_path = os.path.join(output_dir, sub_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    print(f"  Generated: {full_path}")


def java_type_to_jpa_column(java_type: str, length: str = None) -> str:
    """Return @Column annotation snippet for a Java type."""
    if java_type == "String":
        ln = length or "255"
        return f'@Column(name = "{{col}}", length = {ln})'
    elif java_type == "BigDecimal":
        return '@Column(name = "{col}", precision = 19, scale = 6)'
    elif java_type in ("boolean", "Boolean"):
        return '@Column(name = "{col}", nullable = false)'
    elif java_type in ("LocalDate", "LocalDateTime"):
        return '@Column(name = "{col}")'
    elif java_type in ("Integer", "int", "Long", "long"):
        return '@Column(name = "{col}")'
    else:
        return '@Column(name = "{col}")'


def java_type_imports(java_type: str) -> str:
    """Return import statement for a Java type, or empty string."""
    imports = {
        "BigDecimal": "import java.math.BigDecimal;",
        "LocalDate": "import java.time.LocalDate;",
        "LocalDateTime": "import java.time.LocalDateTime;",
        "Set": "import java.util.Set;",
        "List": "import java.util.List;",
        "Map": "import java.util.Map;",
    }
    return imports.get(java_type, "")


def collect_imports(fields: List[Tuple[str, str]]) -> List[str]:
    """Collect unique Java imports for field types."""
    seen = set()
    result = []
    for _, typ in fields:
        imp = java_type_imports(typ)
        if imp and imp not in seen:
            seen.add(imp)
            result.append(imp)
    return sorted(result)
