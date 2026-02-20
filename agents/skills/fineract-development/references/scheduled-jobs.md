# Cron Jobs & Batch Processing

## Purpose

This skill teaches how to implement scheduled jobs in Fineract using Spring Batch, including Tasklet pattern, Job/Step configuration, `@CronTarget` usage, and failure handling.

## Architecture

Fineract scheduled jobs are Spring Batch jobs that execute per-tenant:

```
Scheduler
    │
    ├── For each tenant:
    │   ├── Set tenant context
    │   ├── Execute Spring Batch Job
    │   │   ├── Step 1 (Tasklet)
    │   │   ├── Step 2 (optional)
    │   │   └── ...
    │   └── Clear tenant context
    │
    └── Log results to m_job_run_history
```

## Tasklet Pattern

### Tasklet Implementation

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class PostInterestForSavingsJobTasklet implements Tasklet {

    private final SavingsAccountWritePlatformService savingsService;

    @Override
    @CronTarget(jobName = "Post Interest For Savings")
    public RepeatStatus execute(StepContribution contribution,
            ChunkContext chunkContext) throws Exception {
        log.info("Starting interest posting for savings accounts");

        savingsService.postInterestForAllAccounts();

        log.info("Completed interest posting for savings accounts");
        return RepeatStatus.FINISHED;
    }
}
```

### Job Configuration

```java
@Configuration
@RequiredArgsConstructor
public class PostInterestForSavingsJobConfig {

    @Bean
    public Job postInterestForSavingsJob(
            JobRepository jobRepository,
            Step postInterestStep) {
        return new JobBuilder("postInterestForSavingsJob", jobRepository)
            .start(postInterestStep)
            .build();
    }

    @Bean
    public Step postInterestStep(
            JobRepository jobRepository,
            PlatformTransactionManager transactionManager,
            PostInterestForSavingsJobTasklet tasklet) {
        return new StepBuilder("postInterestStep", jobRepository)
            .tasklet(tasklet, transactionManager)
            .build();
    }
}
```

## Job Registration (Liquibase)

Every job must be registered in `m_job` table:

```xml
<changeSet author="developer" id="register-job">
    <insert tableName="m_job">
        <column name="name" value="Post Interest For Savings"/>
        <column name="display_name" value="Post Interest For Savings"/>
        <column name="cron_expression" value="0 0 0 1/1 * ? *"/>
        <column name="is_active" valueBoolean="false"/>
        <column name="create_time" valueComputed="NOW()"/>
    </insert>

    <rollback>
        <delete tableName="m_job">
            <where>name = 'Post Interest For Savings'</where>
        </delete>
    </rollback>
</changeSet>
```

## Cron Expression Reference

| Expression        | Schedule          |
| ----------------- | ----------------- |
| `0 0 0 1/1 * ? *` | Daily at midnight |
| `0 0 */6 * * ?`   | Every 6 hours     |
| `0 0 0 1 1/1 ? *` | Monthly on 1st    |
| `0 0 0 ? * MON *` | Weekly on Monday  |
| `0 0/30 * * * ?`  | Every 30 minutes  |

## Multi-Step Jobs

For complex batch processing with multiple steps:

```java
@Bean
public Job complexBatchJob(JobRepository jobRepository,
        Step extractStep, Step processStep, Step reportStep) {
    return new JobBuilder("complexBatchJob", jobRepository)
        .start(extractStep)
        .next(processStep)
        .next(reportStep)
        .build();
}
```

## Chunk-Based Processing

For processing large datasets:

```java
@Bean
public Step processAccountsStep(
        JobRepository jobRepository,
        PlatformTransactionManager transactionManager,
        ItemReader<SavingsAccount> reader,
        ItemProcessor<SavingsAccount, SavingsAccount> processor,
        ItemWriter<SavingsAccount> writer) {
    return new StepBuilder("processAccountsStep", jobRepository)
        .<SavingsAccount, SavingsAccount>chunk(100, transactionManager)
        .reader(reader)
        .processor(processor)
        .writer(writer)
        .faultTolerant()
        .skipLimit(10)
        .skip(Exception.class)
        .retryLimit(3)
        .retry(TransientDataAccessException.class)
        .build();
}
```

## Failure Handling

### Retry Strategy

```java
.faultTolerant()
.retryLimit(3)
.retry(TransientDataAccessException.class)  // Retry on transient DB errors
.retry(OptimisticLockingFailureException.class)
```

### Skip Strategy

```java
.skipLimit(10)
.skip(InvalidDataException.class)  // Skip bad records, continue processing
.noSkip(CriticalFinancialException.class)  // Never skip financial errors
```

### Listener for Logging Failures

```java
.listener(new StepExecutionListener() {
    @Override
    public ExitStatus afterStep(StepExecution stepExecution) {
        log.info("Step completed: read={}, processed={}, skipped={}",
            stepExecution.getReadCount(),
            stepExecution.getWriteCount(),
            stepExecution.getSkipCount());
        return stepExecution.getExitStatus();
    }
})
```

## Decision Framework

### Tasklet vs Chunk Processing

| Criteria       | Tasklet                | Chunk                                |
| -------------- | ---------------------- | ------------------------------------ |
| Data volume    | Small (< 1000 records) | Large (> 1000 records)               |
| Processing     | All-or-nothing         | Record-by-record                     |
| Error handling | Fail entire job        | Skip/retry individual records        |
| Complexity     | Simple                 | More complex but resilient           |
| Use case       | End-of-day summaries   | Interest posting across all accounts |

### When to Create a Scheduled Job

- Periodic financial calculations (interest posting, fee application)
- End-of-day processing (balance snapshots, aging)
- Data cleanup (archive old records, purge temporary data)
- Report generation (periodic statements, regulatory reports)
- External system sync (push/pull data on schedule)

## Key Points

- `@CronTarget(jobName = "...")` links the tasklet to a job name in `m_job`.
- Cron expressions are stored in DB (editable at runtime via admin API).
- Jobs run per-tenant (multi-tenant scheduler iterates tenants).
- Use `RepeatStatus.FINISHED` for single-run tasks, `CONTINUABLE` for chunked.
- Spring Batch provides restart, skip, and retry semantics for complex jobs.
- Liquibase creates Spring Batch metadata tables (`BATCH_JOB_INSTANCE`, etc.) on startup.

## Generator

```bash
python3 scripts/generate_scheduled_job.py \
  --job-name "Post Interest For Savings" \
  --class-name PostInterestForSavings \
  --package org.apache.fineract.portfolio.savingsaccount \
  --output-dir ./output
```

# Checklist

- [ ] Changelog placed in `db/changelog/tenant/parts/`
- [ ] File named `XXXX__<description>.xml` with sequential number
- [ ] ChangeSet IDs are unique and sequential within file
- [ ] Table name uses `m_` prefix with snake_case
- [ ] Column names are snake_case
- [ ] Primary key: `BIGINT` with `autoIncrement="true"`
- [ ] Money fields: `DECIMAL(19,6)`
- [ ] Boolean fields: `TINYINT(1)` with `defaultValueNumeric="0"`
- [ ] String fields have explicit length: `VARCHAR(n)`
- [ ] Audit columns included: `created_by`, `created_on_utc`, `last_modified_by`, `last_modified_on_utc`
- [ ] Foreign keys added as separate changeSets with constraint names
- [ ] Every changeSet has a `<rollback>` block
- [ ] Indexes added for frequently queried columns
- [ ] Permissions inserted for CREATE, READ, UPDATE, DELETE
- [ ] Permission entity_name is UPPERCASE without separators
- [ ] `can_maker_checker` set appropriately
- [ ] Constraint names follow conventions (`fk_`, `idx_`, `_unique`)
- [ ] No `DROP TABLE` without data migration plan
