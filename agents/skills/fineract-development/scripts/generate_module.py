#!/usr/bin/env python3
"""Generate a complete Fineract module scaffold.

Combines all individual generators to produce entity, repository, services,
handlers, API resource, data class, validator, exceptions, business events,
and Liquibase migration in one go.
"""

import argparse
import sys
import os
import importlib.util

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPTS_DIR)

from utils import to_snake_case, to_camel_case


def load_module(name):
    """Dynamically import a generator module."""
    spec = importlib.util.spec_from_file_location(name, os.path.join(SCRIPTS_DIR, f"{name}.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    parser = argparse.ArgumentParser(
        description="Generate a complete Fineract module scaffold")
    parser.add_argument("--module-name", required=True,
                        help="Module name (kebab-case, e.g. savings-product)")
    parser.add_argument("--entity-name", required=True,
                        help="PascalCase entity name (e.g. SavingsProduct)")
    parser.add_argument("--package", required=True,
                        help="Java package (e.g. org.apache.fineract.portfolio.savingsproduct)")
    parser.add_argument("--fields", required=True,
                        help="Comma-separated name:Type pairs")
    parser.add_argument("--api-path",
                        help="API URL path (default: <camelEntity>s)")
    parser.add_argument("--actions", default="create,update,delete",
                        help="Write actions (default: create,update,delete)")
    parser.add_argument("--author", default="fineract",
                        help="Liquibase changelog author")
    parser.add_argument("--output-dir", required=True,
                        help="Output directory for generated files")
    args = parser.parse_args()

    output_dir = args.output_dir
    api_path = args.api_path or to_camel_case(args.entity_name) + "s"
    table_name = f"m_{to_snake_case(args.entity_name)}"
    table_alias = to_snake_case(args.entity_name)[:2]

    print(f"🏗️  Generating Fineract module: {args.module_name}")
    print(f"   Entity: {args.entity_name}")
    print(f"   Package: {args.package}")
    print(f"   Output: {output_dir}")
    print()

    # 1. Entity + Repository
    print("📦 Generating entity, repository, and wrapper...")
    gen = load_module("generate_entity")
    fields = gen.parse_fields(args.fields)
    from utils import package_to_path, write_file
    pkg_path = package_to_path(args.package)

    write_file(output_dir, f"{pkg_path}/domain/{args.entity_name}.java",
               gen.generate_entity(args.entity_name, args.package, fields))
    write_file(output_dir, f"{pkg_path}/domain/{args.entity_name}Repository.java",
               gen.generate_repository(args.entity_name, args.package))
    write_file(output_dir, f"{pkg_path}/domain/{args.entity_name}RepositoryWrapper.java",
               gen.generate_repository_wrapper(args.entity_name, args.package))

    # 2. Exceptions (needed by other components)
    print("⚠️  Generating exception classes...")
    gen_exc = load_module("generate_exceptions")
    write_file(output_dir,
               f"{pkg_path}/exception/{args.entity_name}NotFoundException.java",
               gen_exc.generate_not_found(args.entity_name, args.package))
    write_file(output_dir,
               f"{pkg_path}/exception/{args.entity_name}CannotBeDeletedException.java",
               gen_exc.generate_cannot_be_deleted(args.entity_name, args.package))
    write_file(output_dir,
               f"{pkg_path}/exception/{args.entity_name}DuplicateException.java",
               gen_exc.generate_duplicate(args.entity_name, args.package))

    # 3. Data class + Validator
    print("📋 Generating data class and validator...")
    gen_data = load_module("generate_data")
    write_file(output_dir, f"{pkg_path}/data/{args.entity_name}Data.java",
               gen_data.generate_data_class(args.entity_name, args.package, fields))
    write_file(output_dir,
               f"{pkg_path}/serialization/{args.entity_name}DataValidator.java",
               gen_data.generate_validator(args.entity_name, args.package, fields))

    # 4. Business Events
    print("🔔 Generating business events...")
    gen_event = load_module("generate_business_event")
    for action in ["Created", "Updated", "Deleted"]:
        class_name = f"{args.entity_name}{action}BusinessEvent"
        write_file(output_dir, f"{pkg_path}/event/{class_name}.java",
                   gen_event.generate_event(args.entity_name, args.package, action))

    # 5. Write Service + Handlers
    print("✍️  Generating write service and command handlers...")
    gen_svc = load_module("generate_write_service")
    actions = [a.strip() for a in args.actions.split(",")]
    write_file(output_dir,
               f"{pkg_path}/service/{args.entity_name}WritePlatformService.java",
               gen_svc.generate_write_interface(args.entity_name, args.package, actions))
    write_file(output_dir,
               f"{pkg_path}/service/{args.entity_name}WritePlatformServiceImpl.java",
               gen_svc.generate_write_impl(args.entity_name, args.package, actions))
    for action in actions:
        handler_class = f"{action.capitalize()}{args.entity_name}CommandHandler"
        write_file(output_dir, f"{pkg_path}/handler/{handler_class}.java",
                   gen_svc.generate_command_handler(args.entity_name, args.package, action))

    # 6. Read Service
    print("📖 Generating read service...")
    gen_read = load_module("generate_read_service")
    write_file(output_dir,
               f"{pkg_path}/service/{args.entity_name}ReadPlatformService.java",
               gen_read.generate_read_interface(args.entity_name, args.package))
    write_file(output_dir,
               f"{pkg_path}/service/{args.entity_name}ReadPlatformServiceImpl.java",
               gen_read.generate_read_impl(args.entity_name, args.package, fields,
                                            table_name, table_alias))

    # 7. API Resource
    print("🌐 Generating API resource...")
    gen_api = load_module("generate_api_resource")
    write_file(output_dir, f"{pkg_path}/api/{args.entity_name}ApiResource.java",
               gen_api.generate_api_resource(args.entity_name, args.package, api_path))

    # 8. Liquibase Migration
    print("🗄️  Generating Liquibase migration...")
    gen_lb = load_module("generate_liquibase")
    from utils import parse_fields_with_length
    lb_fields = parse_fields_with_length(args.fields)
    snake = to_snake_case(args.entity_name)
    write_file(output_dir,
               f"db/changelog/tenant/parts/0001__create_{snake}_table.xml",
               gen_lb.generate_liquibase(args.entity_name, table_name, lb_fields,
                                          args.author))

    print()
    print(f"✅ Module '{args.module_name}' generated successfully!")
    print(f"   Files in: {output_dir}")
    print()
    print("Next steps:")
    print("  1. Review and customize the generated code")
    print("  2. Add CommandWrapperBuilder methods for your entity")
    print("  3. Register permissions in Liquibase (already included)")
    print("  4. Wire module into Fineract's build (settings.gradle)")
    print("  5. Add business logic to entity and services")


if __name__ == "__main__":
    main()
