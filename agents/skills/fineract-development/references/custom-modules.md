# Custom Module / Extension Pattern

Fineract supports a **pluggable extension model** via Spring Boot auto-configuration. Custom modules live under `custom/` and can override core services, add batch jobs, COB business steps, transaction processors, and events — all without modifying core code.

## Directory Layout

```
custom/
  {company}/                       # e.g. "acme"
    {category}/                    # e.g. "note", "loan", "event"
      service/                     # Business logic implementation
        src/main/java/...
        build.gradle
        dependencies.gradle
      starter/                     # Spring Boot auto-configuration
        src/main/java/.../starter/
          <Company><Module>AutoConfiguration.java
        src/main/resources/META-INF/spring/
          org.springframework.boot.autoconfigure.AutoConfiguration.imports
        src/test/...
        build.gradle
        dependencies.gradle
      processor/                   # (optional) Transaction processors
      cob/                         # (optional) COB business steps
      job/                         # (optional) Batch jobs
```

## Module Discovery (Gradle)

Modules are automatically discovered via `settings.gradle`:

```gradle
file("${rootDir}/custom").eachDir { companyDir ->
    if('build' != companyDir.name && 'docker' != companyDir.name) {
        file("${rootDir}/custom/${companyDir.name}").eachDir { categoryDir ->
            if('build' != categoryDir.name) {
                file("${rootDir}/custom/${companyDir.name}/${categoryDir.name}").eachDir { moduleDir ->
                    if('build' != moduleDir.name) {
                        include ":custom:${companyDir.name}:${categoryDir.name}:${moduleDir.name}"
                    }
                }
            }
        }
    }
}
```

No manual `include` needed — drop the module in the right directory and Gradle finds it.

## Auto-Configuration

### AutoConfiguration Class

```java
@AutoConfiguration
@ComponentScan("com.acme.fineract.portfolio.note")
@ConditionalOnProperty("acme.note.enabled")
public class AcmeNoteAutoConfiguration {}
```

- `@AutoConfiguration` — registers as Spring Boot auto-configuration
- `@ComponentScan` — discovers `@Service`, `@Component` beans in the package
- `@ConditionalOnProperty` — module activates only when property is `true`

For modules with multiple sub-packages:

```java
@AutoConfiguration
@ComponentScans({
    @ComponentScan("com.acme.fineract.loan.cob"),
    @ComponentScan("com.acme.fineract.loan.processor"),
    @ComponentScan("com.acme.fineract.loan.job")
})
@ConditionalOnProperty("acme.loan.enabled")
public class AcmeLoanAutoConfiguration {

    @Bean
    public LoanRepaymentScheduleTransactionProcessorFactory
           loanRepaymentScheduleTransactionProcessorFactory(
            AcmeLoanRepaymentScheduleTransactionProcessor defaultProcessor,
            List<LoanRepaymentScheduleTransactionProcessor> processors) {
        return new LoanRepaymentScheduleTransactionProcessorFactory(defaultProcessor, processors);
    }
}
```

### Registration File

Create `src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`:

```
com.acme.fineract.portfolio.note.starter.AcmeNoteAutoConfiguration
```

One fully-qualified class name per line. Spring Boot discovers this automatically.

## Service Override Pattern

Implement the core interface with `@Service` and `@ConditionalOnProperty`:

```java
@Slf4j
@Service
@ConditionalOnProperty("acme.note.enabled")
public class AcmeNoteReadPlatformService implements NoteReadPlatformService, InitializingBean {

    @Override
    public void afterPropertiesSet() throws Exception {
        log.warn("Note Read Service: '{}'", getClass().getCanonicalName());
    }

    @Override
    public NoteData retrieveNote(Long noteId, Long resourceId, Integer noteTypeId) {
        // Custom implementation
    }

    @Override
    public List<NoteData> retrieveNotesByResource(Long resourceId, Integer noteTypeId) {
        return Collections.emptyList();
    }
}
```

When `acme.note.enabled=true`, this bean replaces the core `NoteReadPlatformServiceImpl` because Spring's `@ConditionalOnProperty` and component scanning priority gives custom modules precedence.

Use `InitializingBean.afterPropertiesSet()` to log confirmation that the override is active.

## Extension Points

### Transaction Processor

```java
@Component
public class AcmeLoanRepaymentScheduleTransactionProcessor
       extends FineractStyleLoanRepaymentScheduleTransactionProcessor {

    public static final String STRATEGY_CODE = "acme-standard-strategy";
    public static final String STRATEGY_NAME = "ACME Corp.: standard loan transaction processing strategy";

    @Override
    public String getCode() { return STRATEGY_CODE; }

    @Override
    public String getName() { return STRATEGY_NAME; }
}
```

### COB Business Step

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class AcmeNoopBusinessStep implements LoanCOBBusinessStep {

    private static final String ENUM_STYLED_NAME = "ACME_LOAN_NOOP";
    private static final String HUMAN_READABLE_NAME = "ACME Loan Noop";

    @Override
    public Loan execute(Loan input) { return input; }

    @Override
    public String getEnumStyledName() { return ENUM_STYLED_NAME; }

    @Override
    public String getHumanReadableName() { return HUMAN_READABLE_NAME; }
}
```

### Batch Job

Define job name enum, tasklet, configuration, and name provider:

```java
// Job name enum
public enum AcmeJobName {
    ACME_NOOP_JOB("Acme Noop Job");
    private final String name;
    // ...
}

// Tasklet
@Component
public class AcmeNoopJobTasklet implements Tasklet {
    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) {
        return RepeatStatus.FINISHED;
    }
}

// Configuration
@Configuration
@RequiredArgsConstructor
public class AcmeNoopJobConfiguration {
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final AcmeNoopJobTasklet tasklet;

    @Bean
    protected Step acmeNoopJobStep() {
        return new StepBuilder(AcmeJobName.ACME_NOOP_JOB.name(), jobRepository)
                .tasklet(tasklet, transactionManager).build();
    }

    @Bean
    public Job acmeNoopJob() {
        return new JobBuilder(AcmeJobName.ACME_NOOP_JOB.name(), jobRepository)
                .start(acmeNoopJobStep()).incrementer(new RunIdIncrementer()).build();
    }
}

// Name provider (registers job with Fineract's job registry)
@Configuration
public class AcmeJobNameConfig {
    @Bean
    public JobNameProvider acmeJobNameProvider() {
        return new SimpleJobNameProvider(List.of(
            new JobNameData(AcmeJobName.ACME_NOOP_JOB.name(), AcmeJobName.ACME_NOOP_JOB.toString())
        ));
    }
}
```

### Custom External Event

```java
// Event class
public class AcmeLoanExternalEvent extends LoanBusinessEvent {
    private static final String TYPE = "AcmeLoanExternalEvent";
    public AcmeLoanExternalEvent(Loan value) { super(value); }
    @Override public String getType() { return TYPE; }
}

// Event source registration
@Configuration
public class AcmeExternalEventSourceProviderConfig {
    @Bean
    public ExternalEventSourceProvider acmeEventSourceProvider() {
        return new SimpleExternalEventSourceProvider(List.of(
            new ExternalEventSourceData("com.acme.fineract.event.externalevent")
        ));
    }
}
```

## Build File Conventions

### Service Module `build.gradle`

```gradle
description = 'ACME Fineract Note Service'
group = 'com.acme.fineract'
base { archivesName = 'acme-fineract-note-service' }
apply from: 'dependencies.gradle'
```

### Service Module `dependencies.gradle`

```gradle
dependencies {
    implementation(project(':fineract-core'))
    implementation(project(':fineract-provider'))
    compileOnly('org.springframework.boot:spring-boot-autoconfigure')
}
```

### Starter Module `dependencies.gradle`

```gradle
dependencies {
    implementation(project(':custom:acme:note:service'))
    implementation('org.springframework.boot:spring-boot-starter')
    testImplementation(project(':fineract-core'))
    testImplementation(project(':fineract-provider'))
}
```

## Testing Custom Modules

Use Cucumber + `ApplicationContextRunner` to verify overrides:

### Test Configuration (Default — no overrides)

```java
@EnableConfigurationProperties({ FineractProperties.class })
public class TestDefaultConfiguration {
    @Bean public FromJsonHelper fromJsonHelper() { return mock(FromJsonHelper.class); }
    @Bean public NoteRepository noteRepository() { return mock(NoteRepository.class); }
    // ... other mocked dependencies
}
```

### Test Configuration (With overrides)

```java
@ComponentScan("com.acme.fineract")  // <-- loads custom implementations
public class TestOverrideConfiguration {
    @Bean public FromJsonHelper fromJsonHelper() { return mock(FromJsonHelper.class); }
    // ... same mocks
}
```

### Cucumber Feature

```gherkin
Feature: Note Feature

  @modules
  Scenario Outline: Verify service override
    Given An auto configuration <autoConfigurationClass> and a service configuration <configurationClass>
    When The user retrieves the service of interface class <interfaceClass>
    Then The service class should match <serviceClass>

    Examples:
      | autoConfigurationClass                              | configurationClass                                                | interfaceClass                                                     | serviceClass                                                                        |
      | org.apache.fineract.portfolio.note.starter.NoteAutoConfiguration | com.acme.fineract.portfolio.note.starter.TestDefaultConfiguration | org.apache.fineract.portfolio.note.service.NoteReadPlatformService | org.apache.fineract.portfolio.note.service.NoteReadPlatformServiceImpl              |
      | org.apache.fineract.portfolio.note.starter.NoteAutoConfiguration | com.acme.fineract.portfolio.note.starter.TestOverrideConfiguration | org.apache.fineract.portfolio.note.service.NoteReadPlatformService | com.acme.fineract.portfolio.note.service.AcmeNoteReadPlatformService                |
```

### Step Definitions

```java
public class AcmeNoteServiceStepDefinitions implements En {
    private ApplicationContextRunner contextRunner;

    public AcmeNoteServiceStepDefinitions() {
        Given("/^An auto configuration (.*) and a service configuration (.*)$/",
            (String autoConfig, String config) -> {
                contextRunner = new ApplicationContextRunner()
                    .withConfiguration(AutoConfigurations.of(Class.forName(autoConfig)))
                    .withPropertyValues("acme.note.enabled", "true")
                    .withUserConfiguration(Class.forName(config.trim()));
            });
        // ... When/Then steps verify correct bean type
    }
}
```

## Package Naming Convention

```
com.{company}.fineract.{domain}.{component}

Examples:
  com.acme.fineract.portfolio.note.service
  com.acme.fineract.portfolio.note.starter
  com.acme.fineract.loan.processor
  com.acme.fineract.loan.cob
  com.acme.fineract.loan.job
  com.acme.fineract.event.externalevent
```

## Checklist: Adding a New Custom Module

1. Create directory: `custom/{company}/{category}/{module}/`
2. Add `build.gradle` with description, group, archivesName
3. Add `dependencies.gradle` with required project dependencies
4. If starter module: create `@AutoConfiguration` class with `@ConditionalOnProperty`
5. If starter module: create `AutoConfiguration.imports` file under `META-INF/spring/`
6. Implement core interfaces with `@Service` + `@ConditionalOnProperty`
7. Add Cucumber tests with `TestDefaultConfiguration` (core) and `TestOverrideConfiguration` (custom)
8. No need to modify `settings.gradle` — auto-discovered
