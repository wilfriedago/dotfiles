#!/usr/bin/env python3
"""Generate Fineract write service interface, implementation, and command handlers."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import to_upper_snake, to_camel_case, write_file, package_to_path


def generate_write_interface(entity_name: str, package: str, actions: list) -> str:
    methods = []
    for action in actions:
        if action == "create":
            methods.append("    CommandProcessingResult create(JsonCommand command);")
        elif action == "update":
            methods.append(f"    CommandProcessingResult update(Long {to_camel_case(entity_name)}Id, JsonCommand command);")
        elif action == "delete":
            methods.append(f"    CommandProcessingResult delete(Long {to_camel_case(entity_name)}Id);")
        else:
            methods.append(f"    CommandProcessingResult {action}(Long {to_camel_case(entity_name)}Id, JsonCommand command);")

    methods_str = "\n\n".join(methods)
    return f"""package {package}.service;

import org.apache.fineract.infrastructure.core.api.JsonCommand;
import org.apache.fineract.infrastructure.core.data.CommandProcessingResult;

public interface {entity_name}WritePlatformService {{

{methods_str}
}}
"""


def generate_write_impl(entity_name: str, package: str, actions: list) -> str:
    var_name = to_camel_case(entity_name)
    entity_upper = to_upper_snake(entity_name)

    method_impls = []
    for action in actions:
        if action == "create":
            method_impls.append(f"""    @Override
    @Transactional
    public CommandProcessingResult create(final JsonCommand command) {{
        this.context.authenticatedUser();
        this.validator.validateForCreate(command.json());

        try {{
            final {entity_name} entity = {entity_name}.fromJson(command);
            this.repository.saveAndFlush(entity);

            this.businessEventNotifierService.notifyPostBusinessEvent(
                new {entity_name}CreatedBusinessEvent(entity));

            return new CommandProcessingResultBuilder()
                .withCommandId(command.commandId())
                .withEntityId(entity.getId())
                .build();
        }} catch (final DataIntegrityViolationException e) {{
            handleDataIntegrityIssues(command, e);
            return CommandProcessingResult.empty();
        }}
    }}""")
        elif action == "update":
            method_impls.append(f"""    @Override
    @Transactional
    public CommandProcessingResult update(final Long {var_name}Id, final JsonCommand command) {{
        this.context.authenticatedUser();
        this.validator.validateForUpdate(command.json());

        final {entity_name} entity = this.repository.findOneWithNotFoundDetection({var_name}Id);
        final Map<String, Object> changes = entity.update(command);

        if (!changes.isEmpty()) {{
            this.repository.saveAndFlush(entity);
        }}

        return new CommandProcessingResultBuilder()
            .withCommandId(command.commandId())
            .withEntityId({var_name}Id)
            .with(changes)
            .build();
    }}""")
        elif action == "delete":
            method_impls.append(f"""    @Override
    @Transactional
    public CommandProcessingResult delete(final Long {var_name}Id) {{
        this.context.authenticatedUser();
        final {entity_name} entity = this.repository.findOneWithNotFoundDetection({var_name}Id);
        this.repository.delete(entity);
        return new CommandProcessingResultBuilder()
            .withEntityId({var_name}Id)
            .build();
    }}""")

    methods_str = "\n\n".join(method_impls)

    return f"""package {package}.service;

import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.apache.fineract.infrastructure.core.api.JsonCommand;
import org.apache.fineract.infrastructure.core.data.CommandProcessingResult;
import org.apache.fineract.infrastructure.core.data.CommandProcessingResultBuilder;
import org.apache.fineract.infrastructure.core.exception.PlatformDataIntegrityException;
import org.apache.fineract.infrastructure.security.service.PlatformSecurityContext;
import org.apache.fineract.infrastructure.event.business.service.BusinessEventNotifierService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import {package}.domain.{entity_name};
import {package}.domain.{entity_name}RepositoryWrapper;
import {package}.event.{entity_name}CreatedBusinessEvent;
import {package}.serialization.{entity_name}DataValidator;

@Service
@Slf4j
@RequiredArgsConstructor
public class {entity_name}WritePlatformServiceImpl
        implements {entity_name}WritePlatformService {{

    private final PlatformSecurityContext context;
    private final {entity_name}RepositoryWrapper repository;
    private final {entity_name}DataValidator validator;
    private final BusinessEventNotifierService businessEventNotifierService;

{methods_str}

    private void handleDataIntegrityIssues(final JsonCommand command,
            final DataIntegrityViolationException e) {{
        final Throwable cause = e.getMostSpecificCause();
        log.error("Data integrity issue: {{}}", cause.getMessage(), e);
        throw new PlatformDataIntegrityException(
            "error.msg.{to_camel_case(entity_name)}.unknown.data.integrity.issue",
            "Unknown data integrity issue with {entity_name}");
    }}
}}
"""


def generate_command_handler(entity_name: str, package: str, action: str) -> str:
    entity_upper = to_upper_snake(entity_name)
    action_upper = action.upper()
    class_name = f"{action.capitalize()}{entity_name}CommandHandler"
    var_name = to_camel_case(entity_name)

    if action == "create":
        service_call = "return this.service.create(command);"
    elif action == "update":
        service_call = f"return this.service.update(command.entityId(), command);"
    elif action == "delete":
        service_call = f"return this.service.delete(command.entityId());"
    else:
        service_call = f"return this.service.{action}(command.entityId(), command);"

    return f"""package {package}.handler;

import lombok.RequiredArgsConstructor;
import org.apache.fineract.commands.annotation.CommandType;
import org.apache.fineract.commands.handler.NewCommandSourceHandler;
import org.apache.fineract.infrastructure.core.api.JsonCommand;
import org.apache.fineract.infrastructure.core.data.CommandProcessingResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import {package}.service.{entity_name}WritePlatformService;

@Service
@CommandType(entity = "{entity_upper}", action = "{action_upper}")
@RequiredArgsConstructor
public class {class_name} implements NewCommandSourceHandler {{

    private final {entity_name}WritePlatformService service;

    @Override
    @Transactional
    public CommandProcessingResult processCommand(final JsonCommand command) {{
        {service_call}
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract write service and command handlers")
    parser.add_argument("--entity-name", required=True, help="PascalCase entity name")
    parser.add_argument("--package", required=True, help="Java package")
    parser.add_argument("--actions", default="create,update,delete",
                        help="Comma-separated actions (default: create,update,delete)")
    parser.add_argument("--output-dir", help="Output directory")
    args = parser.parse_args()

    actions = [a.strip() for a in args.actions.split(",")]

    interface_code = generate_write_interface(args.entity_name, args.package, actions)
    impl_code = generate_write_impl(args.entity_name, args.package, actions)

    pkg_path = package_to_path(args.package)

    if args.output_dir:
        write_file(args.output_dir,
                   f"{pkg_path}/service/{args.entity_name}WritePlatformService.java",
                   interface_code)
        write_file(args.output_dir,
                   f"{pkg_path}/service/{args.entity_name}WritePlatformServiceImpl.java",
                   impl_code)
        for action in actions:
            handler_code = generate_command_handler(args.entity_name, args.package, action)
            class_name = f"{action.capitalize()}{args.entity_name}CommandHandler"
            write_file(args.output_dir,
                       f"{pkg_path}/handler/{class_name}.java",
                       handler_code)
    else:
        print(interface_code)
        print(impl_code)
        for action in actions:
            print(generate_command_handler(args.entity_name, args.package, action))


if __name__ == "__main__":
    main()
