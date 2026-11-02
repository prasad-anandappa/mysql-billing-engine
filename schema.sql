-- mysql-billing-engine : schema.sql
CREATE DATABASE IF NOT EXISTS billing_engine CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE billing_engine;
CREATE TABLE customers (
  customer_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(140) NOT NULL,
  email VARCHAR(160) NOT NULL,
  billing_country VARCHAR(60) NOT NULL DEFAULT 'US',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customers_email (email)
) ENGINE=InnoDB;
CREATE TABLE tax_rates (
  tax_rate_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  jurisdiction VARCHAR(60) NOT NULL,
  rate_percent DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (tax_rate_id),
  UNIQUE KEY uq_tax_jurisdiction (jurisdiction)
) ENGINE=InnoDB;
CREATE TABLE invoices (
  invoice_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id INT UNSIGNED NOT NULL,
  invoice_number VARCHAR(30) NOT NULL,
  status ENUM('DRAFT','ISSUED','PART_PAID','PAID','OVERDUE','VOID') NOT NULL DEFAULT 'DRAFT',
  issued_date DATE NULL,
  due_date DATE NULL,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (invoice_id),
  UNIQUE KEY uq_invoices_number (invoice_number),
  KEY idx_invoices_customer_status (customer_id, status),
  KEY idx_invoices_due (due_date),
  CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
) ENGINE=InnoDB;
CREATE TABLE invoice_line_items (
  line_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invoice_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(200) NOT NULL,
  quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  PRIMARY KEY (line_id),
  CONSTRAINT fk_lines_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id) ON DELETE CASCADE,
  CONSTRAINT chk_lines_qty CHECK (quantity > 0)
) ENGINE=InnoDB;
CREATE TABLE payments (
  payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id INT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('CARD','BANK','CASH','OTHER') NOT NULL DEFAULT 'CARD',
  received_at DATE NOT NULL,
  reference VARCHAR(80) NULL,
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payments_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT chk_payments_amount CHECK (amount > 0)
) ENGINE=InnoDB;
CREATE TABLE payment_allocations (
  allocation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  allocated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (allocation_id),
  UNIQUE KEY uq_alloc_payment_invoice (payment_id, invoice_id),
  CONSTRAINT fk_alloc_payment FOREIGN KEY (payment_id) REFERENCES payments (payment_id),
  CONSTRAINT fk_alloc_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id),
  CONSTRAINT chk_alloc_amount CHECK (amount > 0)
) ENGINE=InnoDB;
