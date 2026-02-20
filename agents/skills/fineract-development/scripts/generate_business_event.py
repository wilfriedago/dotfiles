#!/usr/bin/env python3
"""Generate Fineract business event classes."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import to_camel_case, write_file, package_to_path


def generate_event(entity_name: str, package: str, event_action: str) -> str:
    class_name = f"{entity_name}{event_action}BusinessEvent"
    var_name = to_camel_case(entity_name)

    return f"""package {package}.event;

import org.apache.fineract.infrastructure.event.business.domain.AbstractBusinessEvent;
import {package}.domain.{entity_name};

public class {class_name} extends AbstractBusinessEvent<{entity_name}> {{

    public {class_name}(final {entity_name} value) {{
        super(value);
    }}

    @Override
    public String getType() {{
        return "{class_name}";
    }}

    @Override
    public String getCategory() {{
        return "{entity_name}";
    }}

    @Override
    public Long getAggregateRootId() {{
        return get().getId();
    }}
}}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract business events")
    parser.add_argument("--entity-name", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--events", default="Created,Updated,Deleted",
                        help="Comma-separated event actions (default: Created,Updated,Deleted)")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    events = [e.strip() for e in args.events.split(",")]
    pkg_path = package_to_path(args.package)

    for event_action in events:
        code = generate_event(args.entity_name, args.package, event_action)
        class_name = f"{args.entity_name}{event_action}BusinessEvent"
        if args.output_dir:
            write_file(args.output_dir,
                       f"{pkg_path}/event/{class_name}.java", code)
        else:
            print(code)


if __name__ == "__main__":
    main()
