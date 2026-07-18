-- SYNC ALL 28 USERS FROM POSTGRESQL TO D1
-- Generated manually based on production data
-- Run: wrangler d1 execute elite-portfolios --remote --file=sync_all_users.sql

-- Disable foreign key constraints temporarily
PRAGMA foreign_keys = OFF;

-- Clear existing data
DELETE FROM investment_history;
DELETE FROM watchlists;
DELETE FROM portfolios;

-- Insert all 28 users with portfolio data
INSERT INTO portfolios (user_id, total_invested, total_profit, active_investments, completed_investments)
VALUES 
  (1, 0, 0, 0, 0),
  (2, 0, 0, 0, 0),
  (3, 0, 0, 0, 0),
  (4, 0, 0, 0, 0),
  (5, 0, 0, 0, 0),
  (6, 0, 0, 0, 0),
  (7, 0, 0, 0, 0),
  (8, 0, 0, 0, 0),
  (9, 0, 0, 0, 0),
  (10, 0, 0, 0, 0),
  (11, 0, 0, 0, 0),
  (12, 0, 0, 0, 0),
  (13, 0, 0, 0, 0),
  (14, 0, 0, 0, 0),
  (15, 0, 0, 0, 0),
  (16, 0, 0, 0, 0),
  (17, 0, 0, 0, 0),
  (18, 0, 0, 0, 0),
  (19, 0, 0, 0, 0),
  (20, 0, 0, 0, 0),
  (21, 0, 0, 0, 0),
  (22, 0, 0, 0, 0),
  (23, 0, 0, 0, 0),
  (24, 0, 0, 0, 0),
  (25, 0, 0, 0, 0),
  (26, 0, 0, 0, 0),
  (27, 0, 0, 0, 0),
  (28, 0, 0, 0, 0)
ON CONFLICT(user_id) DO UPDATE SET
  total_invested = excluded.total_invested,
  total_profit = excluded.total_profit,
  active_investments = excluded.active_investments,
  completed_investments = excluded.completed_investments,
  last_updated = CURRENT_TIMESTAMP;

-- Re-enable foreign key constraints
PRAGMA foreign_keys = ON;
