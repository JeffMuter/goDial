-- +goose Up
ALTER TABLE users ADD COLUMN minutes NOT NULL DEFAULT 0;
-- +goose Down
