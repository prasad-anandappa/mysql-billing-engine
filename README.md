# mysql-billing-engine

I built this MySQL 8 billing engine to model the parts of invoicing that actually go wrong in practice: totals that drift from line items, payments that are never allocated, and overdue debt nobody can age. Everything important here — recalculation, allocation, overdue marking — lives in stored procedures so the rules hold no matter which application writes to the database.

## What the schema models

- `customers` and `tax_rates` (by jurisdiction)
- `invoices` — status lifecycle (`DRAFT`, `ISSUED`, `PART_PAID`, `PAID`, `OVERDUE`, `VOID`), subtotal / discount / tax / total
- `invoice_line_items` — with a **generated column** `line_total = quantity * unit_price`, so a line total can never disagree with its inputs
- `payments` and `payment_allocations` — a payment is money received; an allocation is money *applied* to a specific invoice. Keeping them separate is what makes partial payments and one-payment-many-invoices work.

## Key pieces

- `recalculate_invoice` — recomputes subtotal from line items, then discount, then tax on the discounted amount, in one place.
- `allocate_payment` — inserts an allocation in a transaction and moves the invoice to `PART_PAID` or `PAID` based on the allocated total.
- `mark_overdue_invoices` — flips open invoices past their due date to `OVERDUE`.
- **Views** — `v_invoice_balances` (total / paid / balance due), `v_ageing_report` (0–30 / 31–60 / 61–90 / 90+ buckets per customer), `v_customer_statement`.
- **Queries** — open balances oldest-first, monthly billed revenue, unallocated payment money, invoices due in the next 7 days.

## How to load it into MySQL 8

```bash
mysql -u root -p < schema.sql
mysql -u root -p billing_engine < seed.sql
mysql -u root -p billing_engine < procedures.sql
mysql -u root -p billing_engine < views.sql
mysql -u root -p billing_engine < queries.sql   # optional
```

## Validation

I validated these files on a machine with **no MySQL/MariaDB server and no Docker**, so I did **not** execute them against a live server and I am not claiming I did. Instead I ran a documented structural lint pass (Python, standard library only) over every `.sql` file in this repo: balanced parentheses and quotes after stripping strings/comments, statement termination, well-formed `DELIMITER` blocks, and a cross-file check that every table/view/procedure referenced is defined in this repo. All files passed that lint. Execution against MySQL 8 remains the reader's final check.

## License

MIT — see `LICENSE`. I am a Software Engineer; this is a personal portfolio project.
