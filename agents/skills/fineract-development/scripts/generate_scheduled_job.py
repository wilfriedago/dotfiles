#!/usr/bin/env python3
"""Generate Fineract scheduled job (Spring Batch tasklet + config)."""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from utils import to_camel_case, to_snake_case, write_file, package_to_path


def generate_tasklet(class_name: str, job_name: str, package: str) -> str:
    return f"""package {package}.jobs;

import lombok.extern.slf4j.Slf4j;
import org.apache.fineract.infrastructure.jobs.service.JobName;
import org.apache.fineract.infrastructure.jobs.annotation.CronTarget;
import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class {class_name}JobTasklet implements Tasklet {{

    // TODO: Inject required services via constructor

    @Override
    @CronTarget(jobName = "{job_name}")
    public RepeatStatus execute(final StepContribution contribution,
            final ChunkContext chunkContext) throws Exception {{
        log.info("Starting job: {job_name}");

        // TODO: Implement job logic here
        // Example: iterate over entities and process them

        log.info("Completed job: {job_name}");
        return RepeatStatus.FINISHED;
    }}
}}
"""


def generate_job_config(class_name: str, job_name: str, package: str) -> str:
    var_name = to_camel_case(class_name)
    bean_job = f"{var_name}Job"
    bean_step = f"{var_name}Step"

    return f"""package {package}.jobs;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
public class {class_name}JobConfig {{

    @Bean
    public Job {bean_job}(
            final JobRepository jobRepository,
            final Step {bean_step}) {{
        return new JobBuilder("{bean_job}", jobRepository)
            .start({bean_step})
            .build();
    }}

    @Bean
    public Step {bean_step}(
            final JobRepository jobRepository,
            final PlatformTransactionManager transactionManager,
            final {class_name}JobTasklet tasklet) {{
        return new StepBuilder("{bean_step}", jobRepository)
            .tasklet(tasklet, transactionManager)
            .build();
    }}
}}
"""


def generate_liquibase_job_insert(job_name: str, cron: str, author: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.3.xsd">

    <changeSet author="{author}" id="1">
        <insert tableName="m_job">
            <column name="name" value="{job_name}"/>
            <column name="display_name" value="{job_name}"/>
            <column name="cron_expression" value="{cron}"/>
            <column name="is_active" valueBoolean="false"/>
            <column name="create_time" valueComputed="NOW()"/>
        </insert>
    </changeSet>

</databaseChangeLog>
"""


def main():
    parser = argparse.ArgumentParser(description="Generate Fineract scheduled job")
    parser.add_argument("--class-name", required=True, help="PascalCase class prefix")
    parser.add_argument("--job-name", required=True, help="Display name for the job")
    parser.add_argument("--package", required=True, help="Java package")
    parser.add_argument("--cron", default="0 0 0 1/1 * ? *",
                        help="Cron expression (default: daily midnight)")
    parser.add_argument("--author", default="fineract")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    tasklet = generate_tasklet(args.class_name, args.job_name, args.package)
    config = generate_job_config(args.class_name, args.job_name, args.package)
    migration = generate_liquibase_job_insert(args.job_name, args.cron, args.author)

    pkg_path = package_to_path(args.package)
    if args.output_dir:
        write_file(args.output_dir,
                   f"{pkg_path}/jobs/{args.class_name}JobTasklet.java", tasklet)
        write_file(args.output_dir,
                   f"{pkg_path}/jobs/{args.class_name}JobConfig.java", config)
        snake = to_snake_case(args.class_name)
        write_file(args.output_dir,
                   f"db/changelog/tenant/parts/0002__insert_{snake}_job.xml",
                   migration)
    else:
        print(tasklet)
        print(config)
        print(migration)


if __name__ == "__main__":
    main()
