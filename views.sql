-- views.sql
USE billing_engine;
CREATE OR REPLACE VIEW v_invoice_balances AS
SELECT i.invoice_id, i.invoice_number, c.name AS customer_name, i.status, i.total_amount,
       COALESCE(SUM(pa.amount),0) AS paid_amount,
       i.total_amount - COALESCE(SUM(pa.amount),0) AS balance_due,
       i.due_date
FROM invoices i
JOIN customers c ON c.customer_id = i.customer_id
LEFT JOIN payment_allocations pa ON pa.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.invoice_number, c.name, i.status, i.total_amount, i.due_date;
CREATE OR REPLACE VIEW v_ageing_report AS
SELECT c.name AS customer_name,
       SUM(CASE WHEN DATEDIFF(CURRENT_DATE, i.due_date) BETWEEN 0 AND 30 THEN i.total_amount - COALESCE(p.paid,0) ELSE 0 END) AS days_0_30,
       SUM(CASE WHEN DATEDIFF(CURRENT_DATE, i.due_date) BETWEEN 31 AND 60 THEN i.total_amount - COALESCE(p.paid,0) ELSE 0 END) AS days_31_60,
       SUM(CASE WHEN DATEDIFF(CURRENT_DATE, i.due_date) BETWEEN 61 AND 90 THEN i.total_amount - COALESCE(p.paid,0) ELSE 0 END) AS days_61_90,
       SUM(CASE WHEN DATEDIFF(CURRENT_DATE, i.due_date) > 90 THEN i.total_amount - COALESCE(p.paid,0) ELSE 0 END) AS days_90_plus
FROM invoices i
JOIN customers c ON c.customer_id = i.customer_id
LEFT JOIN (SELECT invoice_id, SUM(amount) AS paid FROM payment_allocations GROUP BY invoice_id) p ON p.invoice_id = i.invoice_id
WHERE i.status IN ('ISSUED','PART_PAID','OVERDUE')
GROUP BY c.name;
CREATE OR REPLACE VIEW v_customer_statement AS
SELECT c.customer_id, c.name AS customer_name, COUNT(i.invoice_id) AS invoices,
       SUM(i.total_amount) AS billed, SUM(COALESCE(p.paid,0)) AS paid
FROM customers c
LEFT JOIN invoices i ON i.customer_id = c.customer_id AND i.status <> 'VOID'
LEFT JOIN (SELECT invoice_id, SUM(amount) AS paid FROM payment_allocations GROUP BY invoice_id) p ON p.invoice_id = i.invoice_id
GROUP BY c.customer_id, c.name;
