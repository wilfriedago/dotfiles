#!/usr/bin/env python3
"""Generate Fineract read service with JDBC RowMapper."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import (parse_fields, to_snake_case, to_camel_case, collect_imports,
                   write_file, package_to_path)

JDBC_GETTER = {
    "String": "rs.getString",
    "BigDecimal": "rs.getBigDecimal",
    "Long": "rs.getLong",
    "long": "rs.getLong",
    "Integer": "rs.getInt",
    "int": "rs.getInt",
    "boolean": "rs.getBoolean",
    "Boolean": "rs.getBoolean",
    "LocalDate": "rs.getObject(\"{col}\", LocalDate.class",
    "LocalDateTime": "rs.getObject(\"{col}\", LocalDateTime.class",
}


def generate_read_interface(entity_name: str, package: str) -> str:
    return f"""package {package}.service;

import java.util.Collection;
import {package}.data.{entity_name}Data;

public interface {entity_name}ReadPlatformService {{

    {entity_name}Data retrieveOne(Long id);

    Collection<{entity_name}Data> retrieveAll();
}}
"""


def generate_read_impl(entity_name: str, package: str, fields: list,
                       table_name: str, table_alias: str) -> str:
    var_name = to_camel_case(entity_name)
    imports = collect_imports(fields)
    imports_block = "\n".join(imports) + "\n" if imports else ""

    # Schema select columns
    select_cols = [f"{table_alias}.id AS id"]
    for fname, ftype in fields:
        col = to_snake_case(fname)
        select_cols.append(f"{table_alias}.{col} AS {fname}")

    schema_str = ', "\n                + "'.join(select_cols)

    # RowMapper mappings using setter chaining (@Accessors(chain = true))
    mapper_lines = [f"            final {entity_name}Data data = new {entity_name}Data();"]
    mapper_lines.append('            data.setId(rs.getLong("id"));')
    for fname, ftype in fields:
        getter = JDBC_GETTER.get(ftype, "rs.getString")
        setter = f"set{fname[0].upper()}{fname[1:]}"
        if ftype in ("LocalDate", "LocalDateTime"):
            mapper_lines.append(f'            data.{setter}(rs.getObject("{fname}", {ftype}.class));')
        else:
            mapper_lines.append(f'            data.{setter}({getter}("{fname}"));')

    mapper_str = "\n".join(mapper_lines)

    return f"""package {package}.service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
{imports_block}import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.apache.fineract.infrastructure.security.service.PlatformSecurityContext;
import {package}.data.{entity_name}Data;
import {package}.exception.{entity_name}NotFoundException;

@Service
public class {entity_name}ReadPlatformServiceImpl
        implements {entity_name}ReadPlatformService {{

    private final JdbcTemplate jdbcTemplate;
    private final PlatformSecurityContext context;
    private final {entity_name}Mapper mapper = new {entity_name}Mapper();

    public {entity_name}ReadPlatformServiceImpl(
            final JdbcTemplate jdbcTemplate,
            final PlatformSecurityContext context) {{
        this.jdbcTemplate = jdbcTemplate;
        this.context = context;
    }}

    @Override
    public {entity_name}Data retrieveOne(final Long id) {{
        this.context.authenticatedUser();
        final String sql = "SELECT " + this.mapper.schema() + " WHERE {table_alias}.id = ?";
        try {{
            return this.jdbcTemplate.queryForObject(sql, this.mapper, id);
        }} catch (final EmptyResultDataAccessException e) {{
            throw new {entity_name}NotFoundException(id);
        }}
    }}

    @Override
    public Collection<{entity_name}Data> retrieveAll() {{
        this.context.authenticatedUser();
        final String sql = "SELECT " + this.mapper.schema() + " ORDER BY {table_alias}.id";
        return this.jdbcTemplate.query(sql, this.mapper);
    }}

    private static final class {entity_name}Mapper implements RowMapper<{entity_name}Data> {{

        public String schema() {{
            return " {schema_str} "
                + "FROM {table_name} {table_alias} ";
        }}

        @Override
        public {entity_name}Data mapRow(final ResultSet rs, final int rowNum)
                throws SQLException {{
{mapper_str}
            return data;
        }}
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract read service")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--fields", required=True)
    parser.add_argument("--table-name", help="DB table name (default: m_<snake_entity>)")
    parser.add_argument("--table-alias", help="SQL alias (default: first 2 chars)")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    fields = parse_fields(args.fields)
    table_name = args.table_name or f"m_{to_snake_case(args.entity_name)}"
    table_alias = args.table_alias or to_snake_case(args.entity_name)[:2]

    interface_code = generate_read_interface(args.entity_name, args.package)
    impl_code = generate_read_impl(args.entity_name, args.package, fields,
                                    table_name, table_alias)

    pkg_path = package_to_path(args.package)
    if args.output_dir:
        write_file(args.output_dir,
                   f"{pkg_path}/service/{args.entity_name}ReadPlatformService.java",
                   interface_code)
        write_file(args.output_dir,
                   f"{pkg_path}/service/{args.entity_name}ReadPlatformServiceImpl.java",
                   impl_code)
    else:
        print(interface_code)
        print(impl_code)


if __name__ == "__main__":
    main()
