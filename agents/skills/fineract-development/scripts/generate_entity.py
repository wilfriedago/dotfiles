#!/usr/bin/env python3
"""Generate Fineract entity, repository, and repository wrapper classes."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import (parse_fields, to_snake_case, to_camel_case, collect_imports,
                   write_file, package_to_path)


def generate_entity(entity_name: str, package: str, fields: list) -> str:
    table_name = f"m_{to_snake_case(entity_name)}"
    imports = collect_imports(fields)
    imports_block = "\n".join(imports) + "\n" if imports else ""
    var_name = to_camel_case(entity_name)

    field_declarations = []
    constructor_params = []
    constructor_assignments = []

    for fname, ftype in fields:
        col_name = to_snake_case(fname)
        if ftype == "BigDecimal":
            ann = f'    @Column(name = "{col_name}", precision = 19, scale = 6)'
        elif ftype == "String":
            ann = f'    @Column(name = "{col_name}", length = 255)'
        elif ftype in ("boolean", "Boolean"):
            ann = f'    @Column(name = "{col_name}", nullable = false)'
        else:
            ann = f'    @Column(name = "{col_name}")'

        field_declarations.append(f"{ann}\n    private {ftype} {fname};")
        constructor_params.append(f"final {ftype} {fname}")
        constructor_assignments.append(f"        this.{fname} = {fname};")

    fields_str = "\n\n".join(field_declarations)
    params_str = ",\n            ".join(constructor_params)
    assigns_str = "\n".join(constructor_assignments)

    # Generate update method
    update_checks = []
    for fname, ftype in fields:
        json_method = "stringValueOfParameterNamed" if ftype == "String" \
            else "bigDecimalValueOfParameterNamed" if ftype == "BigDecimal" \
            else "booleanPrimitiveValueOfParameterNamed" if ftype in ("boolean",) \
            else "integerValueOfParameterNamed" if ftype in ("Integer", "int") \
            else "longValueOfParameterNamed" if ftype in ("Long", "long") \
            else "stringValueOfParameterNamed"

        if ftype in ("boolean",):
            update_checks.append(f"""        if (command.isChangeInBooleanParameterNamed("{fname}", this.{fname})) {{
            final {ftype} newValue = command.{json_method}("{fname}");
            actualChanges.put("{fname}", newValue);
            this.{fname} = newValue;
        }}""")
        elif ftype == "String":
            update_checks.append(f"""        if (command.isChangeInStringParameterNamed("{fname}", this.{fname})) {{
            final String newValue = command.{json_method}("{fname}");
            actualChanges.put("{fname}", newValue);
            this.{fname} = newValue;
        }}""")
        elif ftype == "BigDecimal":
            update_checks.append(f"""        if (command.isChangeInBigDecimalParameterNamed("{fname}", this.{fname})) {{
            final BigDecimal newValue = command.{json_method}("{fname}");
            actualChanges.put("{fname}", newValue);
            this.{fname} = newValue;
        }}""")

    updates_str = "\n\n".join(update_checks)

    # Generate fromJson field extraction
    fromJson_extractions = []
    fromJson_args_list = []
    for fname, ftype in fields:
        if ftype == "String":
            fromJson_extractions.append(f'        final String {fname} = command.stringValueOfParameterNamed("{fname}");')
        elif ftype == "BigDecimal":
            fromJson_extractions.append(f'        final BigDecimal {fname} = command.bigDecimalValueOfParameterNamed("{fname}");')
        elif ftype in ("boolean",):
            fromJson_extractions.append(f'        final boolean {fname} = command.booleanPrimitiveValueOfParameterNamed("{fname}");')
        elif ftype in ("Integer", "int"):
            fromJson_extractions.append(f'        final Integer {fname} = command.integerValueOfParameterNamed("{fname}");')
        elif ftype in ("Long", "long"):
            fromJson_extractions.append(f'        final Long {fname} = command.longValueOfParameterNamed("{fname}");')
        else:
            fromJson_extractions.append(f'        final String {fname} = command.stringValueOfParameterNamed("{fname}");')
        fromJson_args_list.append(fname)
    fromJson_str = "\n".join(fromJson_extractions)
    fromJson_args = ", ".join(fromJson_args_list)

    # Generate getters
    getter_lines = []
    for fname, ftype in fields:
        getter_name = f"get{fname[0].upper()}{fname[1:]}"
        if ftype == "boolean":
            getter_name = f"is{fname[0].upper()}{fname[1:]}"
        getter_lines.append(f"    public {ftype} {getter_name}() {{ return this.{fname}; }}")
    getters_str = "\n\n".join(getter_lines)

    return f"""package {package}.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
{imports_block}import java.util.LinkedHashMap;
import java.util.Map;
import org.apache.fineract.infrastructure.core.api.JsonCommand;
import org.apache.fineract.infrastructure.core.domain.AbstractPersistableCustom;

@Entity
@Table(name = "{table_name}")
public class {entity_name} extends AbstractPersistableCustom<Long> {{

{fields_str}

    protected {entity_name}() {{
        // JPA
    }}

    public {entity_name}({params_str}) {{
{assigns_str}
    }}

    public static {entity_name} fromJson(JsonCommand command) {{
{fromJson_str}
        return new {entity_name}({fromJson_args});
    }}

    public Map<String, Object> update(JsonCommand command) {{
        final Map<String, Object> actualChanges = new LinkedHashMap<>();

{updates_str}

        return actualChanges;
    }}

    // Getters
{getters_str}
}}
"""


def generate_repository(entity_name: str, package: str) -> str:
    return f"""package {package}.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface {entity_name}Repository
        extends JpaRepository<{entity_name}, Long>,
                JpaSpecificationExecutor<{entity_name}> {{

    Optional<{entity_name}> findByName(String name);
}}
"""


def generate_repository_wrapper(entity_name: str, package: str) -> str:
    var_name = to_camel_case(entity_name)
    return f"""package {package}.domain;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import {package}.exception.{entity_name}NotFoundException;

@Component
@RequiredArgsConstructor
public class {entity_name}RepositoryWrapper {{

    private final {entity_name}Repository repository;

    public {entity_name} findOneWithNotFoundDetection(final Long id) {{
        return repository.findById(id)
            .orElseThrow(() -> new {entity_name}NotFoundException(id));
    }}

    public void saveAndFlush(final {entity_name} entity) {{
        repository.saveAndFlush(entity);
    }}

    public void save(final {entity_name} entity) {{
        repository.save(entity);
    }}

    public void delete(final {entity_name} entity) {{
        repository.delete(entity);
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract entity, repository, and wrapper")
    parser.add_argument("--entity-name", required=True, help="PascalCase entity name")
    parser.add_argument("--package", required=True, help="Java package")
    parser.add_argument("--fields", required=True, help="Comma-separated name:Type pairs")
    parser.add_argument("--output-dir", help="Output directory (default: stdout)")
    args = parser.parse_args()

    fields = parse_fields(args.fields)
    entity_code = generate_entity(args.entity_name, args.package, fields)
    repo_code = generate_repository(args.entity_name, args.package)
    wrapper_code = generate_repository_wrapper(args.entity_name, args.package)

    if args.output_dir:
        pkg_path = package_to_path(args.package)
        write_file(args.output_dir, f"{pkg_path}/domain/{args.entity_name}.java", entity_code)
        write_file(args.output_dir, f"{pkg_path}/domain/{args.entity_name}Repository.java", repo_code)
        write_file(args.output_dir, f"{pkg_path}/domain/{args.entity_name}RepositoryWrapper.java", wrapper_code)
    else:
        print("// === Entity ===")
        print(entity_code)
        print("// === Repository ===")
        print(repo_code)
        print("// === Repository Wrapper ===")
        print(wrapper_code)


if __name__ == "__main__":
    main()
