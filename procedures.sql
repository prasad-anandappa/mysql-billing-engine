-- procedures.sql
USE billing_engine;
DELIMITER $$
CREATE PROCEDURE recalculate_invoice(IN p_invoice_id BIGINT UNSIGNED, IN p_tax_percent DECIMAL(5,2), IN p_discount_percent DECIMAL(5,2))
BEGIN
  DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0.00;
  SELECT COALESCE(SUM(line_total),0) INTO v_subtotal FROM invoice_line_items WHERE invoice_id = p_invoice_id;
  UPDATE invoices
     SET subtotal = v_subtotal,
         discount_amount = ROUND(v_subtotal * p_discount_percent / 100, 2),
         tax_amount = ROUND((v_subtotal - ROUND(v_subtotal * p_discount_percent / 100, 2)) * p_tax_percent / 100, 2),
         total_amount = (v_subtotal - ROUND(v_subtotal * p_discount_percent / 100, 2)) + ROUND((v_subtotal - ROUND(v_subtotal * p_discount_percent / 100, 2)) * p_tax_percent / 100, 2)
   WHERE invoice_id = p_invoice_id;
END$$
CREATE PROCEDURE allocate_payment(IN p_payment_id BIGINT UNSIGNED, IN p_invoice_id BIGINT UNSIGNED, IN p_amount DECIMAL(12,2))
BEGIN
  DECLARE v_paid DECIMAL(12,2) DEFAULT 0.00;
  DECLARE v_total DECIMAL(12,2) DEFAULT 0.00;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO payment_allocations (payment_id, invoice_id, amount) VALUES (p_payment_id, p_invoice_id, p_amount);
  SELECT COALESCE(SUM(amount),0) INTO v_paid FROM payment_allocations WHERE invoice_id = p_invoice_id;
  SELECT total_amount INTO v_total FROM invoices WHERE invoice_id = p_invoice_id;
  UPDATE invoices SET status = CASE WHEN v_paid >= v_total THEN 'PAID' WHEN v_paid > 0 THEN 'PART_PAID' ELSE status END
   WHERE invoice_id = p_invoice_id;
  COMMIT;
END$$
CREATE PROCEDURE mark_overdue_invoices()
BEGIN
  UPDATE invoices SET status = 'OVERDUE'
   WHERE status IN ('ISSUED','PART_PAID') AND due_date < CURRENT_DATE;
END$$
DELIMITER ;
