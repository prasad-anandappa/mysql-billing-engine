-- queries.sql
USE billing_engine;
-- 1. Open balances, oldest first
SELECT * FROM v_invoice_balances WHERE balance_due > 0 ORDER BY due_date;
-- 2. Ageing report
SELECT * FROM v_ageing_report ORDER BY days_90_plus DESC, days_61_90 DESC;
-- 3. Revenue recognised by month (issued invoices)
SELECT DATE_FORMAT(issued_date, '%Y-%m') AS month, SUM(total_amount) AS billed, COUNT(*) AS invoices
FROM invoices WHERE status <> 'VOID' AND issued_date IS NOT NULL GROUP BY month ORDER BY month;
-- 4. Unallocated payment money per customer
SELECT c.name, p.payment_id, p.amount - COALESCE(SUM(pa.amount),0) AS unallocated
FROM payments p JOIN customers c ON c.customer_id = p.customer_id
LEFT JOIN payment_allocations pa ON pa.payment_id = p.payment_id
GROUP BY c.name, p.payment_id, p.amount HAVING unallocated > 0;
-- 5. Top customers by billed amount
SELECT customer_name, billed, paid, billed - paid AS outstanding FROM v_customer_statement ORDER BY billed DESC;
-- 6. Invoices due in the next 7 days and still open
SELECT invoice_number, due_date, balance_due FROM v_invoice_balances
WHERE balance_due > 0 AND due_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
ORDER BY due_date;
