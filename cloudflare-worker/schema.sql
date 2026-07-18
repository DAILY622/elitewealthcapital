-- Elite Wealth Capital - D1 Database Schema
-- Edge-replicated database for fast global access

-- User Portfolios (summary data)
CREATE TABLE IF NOT EXISTS portfolios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,
  total_invested REAL DEFAULT 0,
  total_profit REAL DEFAULT 0,
  active_investments INTEGER DEFAULT 0,
  completed_investments INTEGER DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investment History (completed investments)
CREATE TABLE IF NOT EXISTS investment_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  plan_name TEXT NOT NULL,
  amount REAL NOT NULL,
  profit REAL DEFAULT 0,
  roi_percentage REAL,
  start_date TEXT,
  end_date TEXT,
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES portfolios(user_id)
);

-- User Watchlists (saved investment plans)
CREATE TABLE IF NOT EXISTS watchlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  symbol TEXT NOT NULL,
  plan_name TEXT,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES portfolios(user_id)
);

-- Crypto Price History (for charts)
CREATE TABLE IF NOT EXISTS price_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  symbol TEXT NOT NULL,
  price REAL NOT NULL,
  change_24h REAL DEFAULT 0,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_investment_history_user ON investment_history(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlists_user ON watchlists(user_id);
CREATE INDEX IF NOT EXISTS idx_price_history_symbol ON price_history(symbol, timestamp);

-- Sample data for testing
INSERT INTO portfolios (user_id, total_invested, total_profit, active_investments) 
VALUES 
  (1, 10000, 1500, 3),
  (2, 5000, 750, 2)
ON CONFLICT(user_id) DO NOTHING;

INSERT INTO investment_history (user_id, plan_name, amount, profit, roi_percentage, start_date, end_date, status)
VALUES
  (1, 'Bitcoin Mining', 5000, 750, 15, '2026-01-01', '2026-01-31', 'completed'),
  (1, 'Real Estate', 3000, 450, 15, '2026-02-01', '2026-03-01', 'completed')
ON CONFLICT DO NOTHING;
