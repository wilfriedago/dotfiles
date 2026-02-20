#!/usr/bin/env python3
"""Generate Fineract JAX-RS API resource class."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import to_upper_snake, to_camel_case, write_file, package_to_path


def generate_api_resource(entity_name: str, package: str, api_path: str) -> str:
    var_name = to_camel_case(entity_name)
    entity_upper = to_upper_snake(entity_name)
    tag_name = " ".join(w for w in entity_name.split() or
                        [entity_name])  # Use as-is for tag

    # Create readable tag by splitting PascalCase
    import re
    tag_name = " ".join(re.findall(r'[A-Z][a-z]*', entity_name))

    return f"""package {package}.api;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.UriInfo;
import java.util.Collection;
import org.apache.fineract.commands.domain.CommandWrapper;
import org.apache.fineract.commands.service.CommandWrapperBuilder;
import org.apache.fineract.commands.service.PortfolioCommandSourceWritePlatformService;
import org.apache.fineract.infrastructure.core.api.ApiRequestParameterHelper;
import org.apache.fineract.infrastructure.core.data.CommandProcessingResult;
import org.apache.fineract.infrastructure.core.serialization.ApiRequestJsonSerializationSettings;
import org.apache.fineract.infrastructure.core.serialization.DefaultToApiJsonSerializer;
import lombok.RequiredArgsConstructor;
import org.apache.fineract.infrastructure.security.service.PlatformSecurityContext;
import org.springframework.stereotype.Component;
import {package}.data.{entity_name}Data;
import {package}.service.{entity_name}ReadPlatformService;

@Path("/v1/{api_path}")
@Component
@Tag(name = "{tag_name}", description = "{tag_name} management API")
@RequiredArgsConstructor
public class {entity_name}ApiResource {{

    private final PlatformSecurityContext context;
    private final {entity_name}ReadPlatformService readService;
    private final DefaultToApiJsonSerializer<{entity_name}Data> toApiJsonSerializer;
    private final PortfolioCommandSourceWritePlatformService commandsSourceService;
    private final ApiRequestParameterHelper apiRequestParameterHelper;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "List all {tag_name.lower()}s",
               description = "Retrieve all {tag_name.lower()} records")
    @ApiResponse(responseCode = "200", description = "OK")
    public String retrieveAll(@Context final UriInfo uriInfo) {{
        this.context.authenticatedUser()
            .validateHasReadPermission("{entity_upper}");

        final Collection<{entity_name}Data> data = this.readService.retrieveAll();

        final ApiRequestJsonSerializationSettings settings =
            this.apiRequestParameterHelper.process(uriInfo.getQueryParameters());
        return this.toApiJsonSerializer.serialize(settings, data);
    }}

    @GET
    @Path("{{entityId}}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Retrieve a {tag_name.lower()}")
    @ApiResponse(responseCode = "200", description = "OK")
    public String retrieveOne(
            @PathParam("entityId") @Parameter(description = "{entity_name} ID") final Long entityId,
            @Context final UriInfo uriInfo) {{
        this.context.authenticatedUser()
            .validateHasReadPermission("{entity_upper}");

        final {entity_name}Data data = this.readService.retrieveOne(entityId);

        final ApiRequestJsonSerializationSettings settings =
            this.apiRequestParameterHelper.process(uriInfo.getQueryParameters());
        return this.toApiJsonSerializer.serialize(settings, data);
    }}

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Create a {tag_name.lower()}")
    @ApiResponse(responseCode = "200", description = "OK")
    public String create(final String apiRequestBodyAsJson) {{
        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .create{entity_name}()
            .withJson(apiRequestBodyAsJson)
            .build();

        final CommandProcessingResult result =
            this.commandsSourceService.logCommandSource(commandRequest);
        return this.toApiJsonSerializer.serialize(result);
    }}

    @PUT
    @Path("{{entityId}}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Update a {tag_name.lower()}")
    @ApiResponse(responseCode = "200", description = "OK")
    public String update(
            @PathParam("entityId") @Parameter(description = "{entity_name} ID") final Long entityId,
            final String apiRequestBodyAsJson) {{
        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .update{entity_name}(entityId)
            .withJson(apiRequestBodyAsJson)
            .build();

        final CommandProcessingResult result =
            this.commandsSourceService.logCommandSource(commandRequest);
        return this.toApiJsonSerializer.serialize(result);
    }}

    @DELETE
    @Path("{{entityId}}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Delete a {tag_name.lower()}")
    @ApiResponse(responseCode = "200", description = "OK")
    public String delete(
            @PathParam("entityId") @Parameter(description = "{entity_name} ID") final Long entityId) {{
        final CommandWrapper commandRequest = new CommandWrapperBuilder()
            .delete{entity_name}(entityId)
            .build();

        final CommandProcessingResult result =
            this.commandsSourceService.logCommandSource(commandRequest);
        return this.toApiJsonSerializer.serialize(result);
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract API resource")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--api-path", help="URL path segment (default: lowercase entity)")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    api_path = args.api_path or to_camel_case(args.entity_name) + "s"
    code = generate_api_resource(args.entity_name, args.package, api_path)

    if args.output_dir:
        pkg_path = package_to_path(args.package)
        write_file(args.output_dir,
                   f"{pkg_path}/api/{args.entity_name}ApiResource.java", code)
    else:
        print(code)


if __name__ == "__main__":
    main()
