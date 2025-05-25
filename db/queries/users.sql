-- name: CreateUser :one
INSERT INTO users (email, name)
VALUES (?, ?)
RETURNING *;

-- name: GetUser :one
SELECT * FROM users
WHERE id = ?;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = ?;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY created_at DESC;

-- name: UpdateUser :one
UPDATE users
SET name = ?, updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = ?; 