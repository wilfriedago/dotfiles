#!/usr/bin/env python3
"""Generate Fineract Data DTO, serializer, and validator classes."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import (parse_fields, to_camel_case, collect_imports, write_file,
                   package_to_path)


def generate_data_class(entity_name: str, package: str, fields: list) -> str:
    imports = collect_imports(fields)
    imports_block = "\n".join(imports) + "\n" if imports else ""

    field_decls = ["    private Long id;"]
    for fname, ftype in fields:
        field_decls.append(f"    private {ftype} {fname};")

    fields_str = "\n".join(field_decls)

    return f"""package {package}.data;

import java.io.Serializable;
{imports_block}import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;

@Data
@NoArgsConstructor
@Accessors(chain = true)
public class {entity_name}Data implements Serializable {{

    private static final long serialVersionUID = 1L;

{fields_str}
}}
"""


def generate_validator(entity_name: str, package: str, fields: list) -> str:
    var_name = to_camel_case(entity_name)

    param_names = [f'"{fname}"' for fname, _ in fields]
    param_names.append('"locale"')
    params_set = ", ".join(param_names)

    validation_lines = []
    for fname, ftype in fields:
        if ftype == "String":
            validation_lines.append(f"""
        final String {fname} = this.fromJsonHelper
            .extractStringNamed("{fname}", element);
        baseDataValidator.reset().parameter("{fname}")
            .value({fname}).notBlank().notExceedingLengthOf(255);""")
        elif ftype == "BigDecimal":
            validation_lines.append(f"""
        final BigDecimal {fname} = this.fromJsonHelper
            .extractBigDecimalWithLocaleNamed("{fname}", element);
        baseDataValidator.reset().parameter("{fname}")
            .value({fname}).notNull().zeroOrPositiveAmount();""")
        elif ftype in ("boolean", "Boolean"):
            validation_lines.append(f"""
        final Boolean {fname} = this.fromJsonHelper
            .extractBooleanNamed("{fname}", element);
        baseDataValidator.reset().parameter("{fname}")
            .value({fname}).ignoreIfNull();""")
        elif ftype in ("Integer", "int"):
            validation_lines.append(f"""
        final Integer {fname} = this.fromJsonHelper
            .extractIntegerWithLocaleNamed("{fname}", element);
        baseDataValidator.reset().parameter("{fname}")
            .value({fname}).notNull().integerGreaterThanZero();""")

    validations_str = "".join(validation_lines)

    return f"""package {package}.serialization;

import com.google.gson.JsonElement;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.fineract.infrastructure.core.data.ApiParameterError;
import org.apache.fineract.infrastructure.core.data.DataValidatorBuilder;
import org.apache.fineract.infrastructure.core.exception.PlatformApiDataValidationException;
import lombok.RequiredArgsConstructor;
import org.apache.fineract.infrastructure.core.serialization.FromJsonHelper;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class {entity_name}DataValidator {{

    private final FromJsonHelper fromJsonHelper;

    private static final Set<String> CREATE_REQUEST_PARAMS = Set.of(
        {params_set}
    );

    private static final Set<String> UPDATE_REQUEST_PARAMS = Set.of(
        {params_set}
    );

    public void validateForCreate(final String json) {{
        final Type typeOfMap = new TypeToken<Map<String, Object>>() {{}}.getType();
        this.fromJsonHelper.checkForUnsupportedParameters(typeOfMap, json,
            CREATE_REQUEST_PARAMS);

        final List<ApiParameterError> dataValidationErrors = new ArrayList<>();
        final DataValidatorBuilder baseDataValidator =
            new DataValidatorBuilder(dataValidationErrors)
                .resource("{var_name}");

        final JsonElement element = this.fromJsonHelper.parse(json);
{validations_str}

        throwExceptionIfValidationWarningsExist(dataValidationErrors);
    }}

    public void validateForUpdate(final String json) {{
        final Type typeOfMap = new TypeToken<Map<String, Object>>() {{}}.getType();
        this.fromJsonHelper.checkForUnsupportedParameters(typeOfMap, json,
            UPDATE_REQUEST_PARAMS);

        final List<ApiParameterError> dataValidationErrors = new ArrayList<>();
        final DataValidatorBuilder baseDataValidator =
            new DataValidatorBuilder(dataValidationErrors)
                .resource("{var_name}");

        final JsonElement element = this.fromJsonHelper.parse(json);
        // For updates, fields are optional — use .ignoreIfNull() where appropriate
{validations_str}

        throwExceptionIfValidationWarningsExist(dataValidationErrors);
    }}

    private void throwExceptionIfValidationWarningsExist(
            final List<ApiParameterError> dataValidationErrors) {{
        if (!dataValidationErrors.isEmpty()) {{
            throw new PlatformApiDataValidationException(dataValidationErrors);
        }}
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract data class and validator")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--fields", required=True)
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    fields = parse_fields(args.fields)
    data_code = generate_data_class(args.entity_name, args.package, fields)
    validator_code = generate_validator(args.entity_name, args.package, fields)

    pkg_path = package_to_path(args.package)
    if args.output_dir:
        write_file(args.output_dir,
                   f"{pkg_path}/data/{args.entity_name}Data.java", data_code)
        write_file(args.output_dir,
                   f"{pkg_path}/serialization/{args.entity_name}DataValidator.java",
                   validator_code)
    else:
        print(data_code)
        print(validator_code)


if __name__ == "__main__":
    main()
