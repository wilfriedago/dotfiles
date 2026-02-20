#!/usr/bin/env python3
"""Generate Fineract Liquibase XML changelog for a new entity table."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import (parse_fields_with_length, to_snake_case, to_upper_snake,
                   write_file)

TYPE_MAP = {
    "String": lambda l: f"VARCHAR({l or 255})",
    "BigDecimal": lambda l: "DECIMAL(19,6)",
    "Long": lambda l: "BIGINT",
    "long": lambda l: "BIGINT",
    "Integer": lambda l: "INT",
    "int": lambda l: "INT",
    "boolean": lambda l: "TINYINT(1)",
    "Boolean": lambda l: "TINYINT(1)",
    "LocalDate": lambda l: "DATE",
    "LocalDateTime": lambda l: "DATETIME",
}


def generate_liquibase(entity_name: str, table_name: str, fields: list,
                       author: str) -> str:
    columns_xml = []

    # Primary key
    columns_xml.append("""            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>""")

    for fname, ftype, length in fields:
        col_name = to_snake_case(fname)
        type_fn = TYPE_MAP.get(ftype, lambda l: f"VARCHAR({l or 255})")
        db_type = type_fn(length)

        nullable = "true"
        extras = ""
        if ftype in ("boolean", "Boolean"):
            nullable = "false"
            extras = ' defaultValueNumeric="0"'

        columns_xml.append(f"""            <column name="{col_name}" type="{db_type}"{extras}>
                <constraints nullable="{nullable}"/>
            </column>""")

    # Audit columns
    columns_xml.extend([
        """            <column name="created_by" type="BIGINT"/>""",
        """            <column name="created_on_utc" type="DATETIME"/>""",
        """            <column name="last_modified_by" type="BIGINT"/>""",
        """            <column name="last_modified_on_utc" type="DATETIME"/>""",
    ])

    columns_str = "\n".join(columns_xml)

    # Permissions
    entity_upper = to_upper_snake(entity_name).replace("_", "")
    permissions = []
    for action in ["CREATE", "READ", "UPDATE", "DELETE"]:
        permissions.append(f"""        <insert tableName="m_permission">
            <column name="grouping" value="portfolio"/>
            <column name="code" value="{action}_{entity_upper}"/>
            <column name="entity_name" value="{entity_upper}"/>
            <column name="action_name" value="{action}"/>
            <column name="can_maker_checker" valueBoolean="false"/>
        </insert>""")

    permissions_str = "\n".join(permissions)

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.3.xsd">

    <changeSet author="{author}" id="1">
        <createTable tableName="{table_name}">
{columns_str}
        </createTable>
    </changeSet>

    <changeSet author="{author}" id="2">
{permissions_str}
    </changeSet>

</databaseChangeLog>
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract Liquibase changelog")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--table-name", help="DB table name (default: m_<snake_entity>)")
    parser.add_argument("--fields", required=True,
                        help="name:Type[:length] pairs, comma-separated")
    parser.add_argument("--author", default="fineract", help="Changelog author")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    table_name = args.table_name or f"m_{to_snake_case(args.entity_name)}"
    fields = parse_fields_with_length(args.fields)

    xml = generate_liquibase(args.entity_name, table_name, fields, args.author)

    if args.output_dir:
        filename = f"0001__create_{to_snake_case(args.entity_name)}_table.xml"
        write_file(args.output_dir, f"db/changelog/tenant/parts/{filename}", xml)
    else:
        print(xml)


if __name__ == "__main__":
    main()
