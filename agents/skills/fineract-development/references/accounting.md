# Accounting Integration

## Purpose

**CRITICAL SKILL.** This skill teaches how Fineract integrates with its accounting ledger. Incorrect implementation can corrupt financial records, create imbalanced journal entries, or violate regulatory requirements.

Without this skill, agents corrupt financial ledgers.

## Accounting Architecture

```
Financial Operation (e.g., Loan Disbursement)
    │
    ▼
Transaction Processor
    │
    ├── Validates accounting configuration
    ├── Determines GL accounts from product-to-account mapping
    ├── Creates balanced journal entries (debits = credits)
    │
    ▼
Journal Entry Repository
    │
    └── Persists to m_journal_entry table
```

## Core Concepts

### Chart of Accounts

Fineract maintains a chart of accounts (GL accounts) in `m_acc_gl_account`:

| Account Type | Purpose                   | Example                          |
| ------------ | ------------------------- | -------------------------------- |
| ASSET        | What the institution owns | Loan Portfolio, Cash             |
| LIABILITY    | What the institution owes | Savings Deposits, Borrowings     |
| EQUITY       | Owner's investment        | Share Capital, Retained Earnings |
| INCOME       | Revenue                   | Interest Income, Fee Income      |
| EXPENSE      | Costs                     | Interest Expense, Provisions     |

### Product-to-Account Mapping

Each financial product (loan, savings) is mapped to GL accounts:

```
Loan Product "Micro Loan"
├── Fund Source         → GL 1001 (Cash)
├── Loan Portfolio      → GL 1100 (Loan Receivable)
├── Interest Income     → GL 4001 (Interest Revenue)
├── Fee Income          → GL 4002 (Fee Revenue)
├── Losses Written Off  → GL 5001 (Write-off Expense)
└── Overpayment         → GL 2001 (Overpayment Liability)
```

### Journal Entry Structure

Every financial transaction creates balanced journal entries:

```
Loan Disbursement ($10,000):
┌──────────────────┬─────────┬─────────┐
│ GL Account       │ Debit   │ Credit  │
├──────────────────┼─────────┼─────────┤
│ Loan Portfolio   │ $10,000 │         │
│ Fund Source      │         │ $10,000 │
└──────────────────┴─────────┴─────────┘
Total Debits = Total Credits ✓
```

## Transaction Processors

Transaction processors are the ONLY components that should create journal entries:

```java
public class CashBasedAccountingProcessor implements AccountingProcessor {

    @Override
    public void createJournalEntriesForLoan(
            LoanDTO loanDTO,
            List<LoanTransactionDTO> transactions) {
        for (LoanTransactionDTO txn : transactions) {
            if (txn.getTransactionType().isDisbursement()) {
                createDisbursementJournalEntries(loanDTO, txn);
            } else if (txn.getTransactionType().isRepayment()) {
                createRepaymentJournalEntries(loanDTO, txn);
            }
            // ... other transaction types
        }
    }

    private void createDisbursementJournalEntries(
            LoanDTO loanDTO, LoanTransactionDTO txn) {
        // DEBIT: Loan Portfolio account
        helper.createDebitJournalEntryForLoan(
            loanDTO.getOfficeId(),
            loanDTO.getLoanPortfolioAccountId(),
            loanDTO.getLoanId(),
            txn.getId(),
            txn.getTransactionDate(),
            txn.getAmount());

        // CREDIT: Fund Source account
        helper.createCreditJournalEntryForLoan(
            loanDTO.getOfficeId(),
            loanDTO.getFundSourceAccountId(),
            loanDTO.getLoanId(),
            txn.getId(),
            txn.getTransactionDate(),
            txn.getAmount());
    }
}
```

## Accounting Rules

### Rule 1: Balanced Entries (CRITICAL)

Every journal entry set MUST have total debits equal to total credits. An imbalanced entry corrupts the ledger.

### Rule 2: No Direct GL Writes

NEVER write to `m_journal_entry` directly. Always go through the accounting helper/processor.

### Rule 3: Accounting Within Transaction

Journal entries must be created within the same `@Transactional` boundary as the financial operation. If the operation fails, journal entries must roll back too.

### Rule 4: Product Mapping Validation

Before creating entries, validate that the product has accounting configured. Some products may use "NONE" (no accounting), "CASH" (cash-based), or "ACCRUAL" (accrual-based).

### Rule 5: Reversal, Not Deletion

Incorrect journal entries are NEVER deleted. They are reversed (creating opposite entries).

## Accounting Methods

### Cash Basis

Journal entries created when cash moves (disbursement, repayment actual receipt).

### Accrual Basis

Journal entries created when income is earned or expense is incurred, regardless of cash movement.

| Event             | Cash Basis Entry          | Accrual Basis Entry             |
| ----------------- | ------------------------- | ------------------------------- |
| Loan disbursement | Debit Loan, Credit Cash   | Same                            |
| Interest accrued  | No entry                  | Debit Receivable, Credit Income |
| Interest received | Debit Cash, Credit Income | Debit Cash, Credit Receivable   |

## When Accounting Entries Are Triggered

| Financial Event    | Triggers Accounting?     |
| ------------------ | ------------------------ |
| Loan disbursement  | YES                      |
| Loan repayment     | YES                      |
| Loan write-off     | YES                      |
| Savings deposit    | YES                      |
| Savings withdrawal | YES                      |
| Interest posting   | YES                      |
| Fee charge         | YES                      |
| Product creation   | NO (configuration only)  |
| Client creation    | NO (no financial impact) |
| User management    | NO                       |

## Anti-Patterns (CRITICAL)

### NEVER: Balance Updates Outside Processors

```java
// WRONG: Direct GL write in service
journalEntryRepository.save(new JournalEntry(...)); // VIOLATION
```

### NEVER: Unbalanced Entries

```java
// WRONG: Only a debit, no credit
helper.createDebitJournalEntry(office, account, amount);
// Missing corresponding credit!
```

### NEVER: Delete Journal Entries

```java
// WRONG: Deleting financial records
journalEntryRepository.delete(entry); // VIOLATION — use reversal
```

### NEVER: Skip Product Accounting Check

```java
// WRONG: Not checking if accounting is configured
createJournalEntries(loan); // May fail if no GL mapping

// CORRECT: Check first
if (loan.isAccountingEnabledOnLoanProduct()) {
    accountingProcessor.createJournalEntries(loanDTO, transactions);
}
```

## Decision Framework

### Does My New Feature Need Accounting?

```
Does the operation move money?                    → YES, needs accounting
Does the operation create/modify financial balances? → YES, needs accounting
Does the operation only change configuration?     → NO
Does the operation only read data?                → NO
Is it purely administrative (users, offices)?     → NO
```

### Which Accounting Method?

| Product Type       | Typical Method |
| ------------------ | -------------- |
| Microfinance loans | Cash basis     |
| Commercial loans   | Accrual basis  |
| Savings accounts   | Cash basis     |
| Fixed deposits     | Accrual basis  |

## Checklist (CRITICAL)

### Journal Entries

- [ ] All debits equal all credits in every journal entry set
- [ ] Journal entries created through accounting processor/helper (never direct repo)
- [ ] Entries created within same @Transactional as financial operation
- [ ] Product accounting configuration checked before creating entries
- [ ] Incorrect entries reversed (not deleted)
- [ ] Office ID correctly set on all journal entries

### Product Mapping

- [ ] Product-to-GL-account mapping configured
- [ ] All required accounts mapped (fund source, portfolio, income, etc.)
- [ ] Accounting method set (NONE, CASH, ACCRUAL)
- [ ] Mapping validated before financial operations

### Financial Operations

- [ ] Money movement operations create journal entries
- [ ] Non-financial operations do NOT create journal entries
- [ ] Balance mutations go through transaction processors ONLY
- [ ] No direct writes to m_journal_entry table
- [ ] No journal entry deletions (use reversal only)

### Regulatory

- [ ] Audit trail maintained for all financial transactions
- [ ] Journal entries include transaction reference IDs
- [ ] Date and currency correctly set on entries
