#!/usr/bin/env python3
"""Generate Fineract custom exception classes."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import to_camel_case, write_file, package_to_path


def generate_not_found(entity_name: str, package: str) -> str:
    var_name = to_camel_case(entity_name)
    return f"""package {package}.exception;

import org.apache.fineract.infrastructure.core.exception.AbstractPlatformResourceNotFoundException;

public class {entity_name}NotFoundException
        extends AbstractPlatformResourceNotFoundException {{

    public {entity_name}NotFoundException(final Long id) {{
        super("error.msg.{var_name}.not.found",
              "{entity_name} with identifier " + id + " does not exist", id);
    }}
}}
"""


def generate_cannot_be_deleted(entity_name: str, package: str) -> str:
    var_name = to_camel_case(entity_name)
    return f"""package {package}.exception;

import org.apache.fineract.infrastructure.core.exception.AbstractPlatformDomainRuleException;

public class {entity_name}CannotBeDeletedException
        extends AbstractPlatformDomainRuleException {{

    public {entity_name}CannotBeDeletedException(final Long id, final String reason) {{
        super("error.msg.{var_name}.cannot.be.deleted",
              "{entity_name} with identifier " + id
              + " cannot be deleted: " + reason, id, reason);
    }}
}}
"""


def generate_duplicate(entity_name: str, package: str) -> str:
    var_name = to_camel_case(entity_name)
    return f"""package {package}.exception;

import org.apache.fineract.infrastructure.core.exception.AbstractPlatformDomainRuleException;

public class {entity_name}DuplicateException
        extends AbstractPlatformDomainRuleException {{

    public {entity_name}DuplicateException(final String name) {{
        super("error.msg.{var_name}.duplicate",
              "{entity_name} with name '" + name + "' already exists", name);
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract exception classes")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    not_found = generate_not_found(args.entity_name, args.package)
    cannot_delete = generate_cannot_be_deleted(args.entity_name, args.package)
    duplicate = generate_duplicate(args.entity_name, args.package)

    pkg_path = package_to_path(args.package)
    if args.output_dir:
        write_file(args.output_dir,
                   f"{pkg_path}/exception/{args.entity_name}NotFoundException.java",
                   not_found)
        write_file(args.output_dir,
                   f"{pkg_path}/exception/{args.entity_name}CannotBeDeletedException.java",
                   cannot_delete)
        write_file(args.output_dir,
                   f"{pkg_path}/exception/{args.entity_name}DuplicateException.java",
                   duplicate)
    else:
        print(not_found)
        print(cannot_delete)
        print(duplicate)


if __name__ == "__main__":
    main()
