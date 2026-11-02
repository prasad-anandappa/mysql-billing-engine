-- seed.sql
USE billing_engine;
INSERT INTO customers (name, email, billing_country) VALUES
  ('Acme Retail LLC','billing@acme.example','US'),
  ('Northwind Traders','ap@northwind.example','US'),
  ('Contoso Ltd','finance@contoso.example','GB');
INSERT INTO tax_rates (jurisdiction, rate_percent) VALUES ('US-AZ',8.30),('US-CA',7.25),('GB-VAT',20.00);
INSERT INTO invoices (customer_id, invoice_number, status, issued_date, due_date, subtotal, discount_amount, tax_amount, total_amount) VALUES
  (1,'INV-2026-001','PAID','2026-09-01','2026-10-01',1000.00,0.00,83.00,1083.00),
  (1,'INV-2026-002','PART_PAID','2026-10-01','2026-10-31',500.00,50.00,37.35,487.35),
  (2,'INV-2026-003','ISSUED','2026-08-15','2026-09-14',2400.00,0.00,199.20,2599.20),
  (3,'INV-2026-004','DRAFT',NULL,NULL,0.00,0.00,0.00,0.00);
INSERT INTO invoice_line_items (invoice_id, description, quantity, unit_price) VALUES
  (1,'Consulting - September',10,80.00),
  (1,'Hosting',1,200.00),
  (2,'Support plan',1,500.00),
  (3,'Implementation',20,120.00);
INSERT INTO payments (customer_id, amount, method, received_at, reference) VALUES
  (1,1083.00,'CARD','2026-09-28','pay_001'),
  (1,200.00,'BANK','2026-10-20','pay_002');
INSERT INTO payment_allocations (payment_id, invoice_id, amount) VALUES
  (1,1,1083.00),
  (2,2,200.00);
