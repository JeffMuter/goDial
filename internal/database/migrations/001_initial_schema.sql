-- +goose Up
-- Initial schema for goDial application

-- Users table to store user information
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Calls table to store call information
CREATE TABLE calls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    phone_number TEXT NOT NULL,
    recipient_context TEXT,
    objective TEXT NOT NULL,
    background_context TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Call logs table to store conversation logs
CREATE TABLE call_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    call_id INTEGER NOT NULL,
    message_type TEXT NOT NULL CHECK (message_type IN ('user_speech', 'ai_response', 'system')),
    content TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (call_id) REFERENCES calls(id) ON DELETE CASCADE
);

-- Indexes for better performance
CREATE INDEX idx_calls_user_id ON calls(user_id);
CREATE INDEX idx_calls_status ON calls(status);
CREATE INDEX idx_call_logs_call_id ON call_logs(call_id);
CREATE INDEX idx_call_logs_timestamp ON call_logs(timestamp);

-- +goose Down
DROP INDEX IF EXISTS idx_call_logs_timestamp;
DROP INDEX IF EXISTS idx_call_logs_call_id;
DROP INDEX IF EXISTS idx_calls_status;
DROP INDEX IF EXISTS idx_calls_user_id;
DROP TABLE IF EXISTS call_logs;
DROP TABLE IF EXISTS calls;
DROP TABLE IF EXISTS users; 