-- name: CreateCall :one
INSERT INTO calls (user_id, phone_number, recipient_context, objective, background_context)
VALUES (?, ?, ?, ?, ?)
RETURNING *;

-- name: GetCall :one
SELECT * FROM calls
WHERE id = ?;

-- name: ListCallsByUser :many
SELECT * FROM calls
WHERE user_id = ?
ORDER BY created_at DESC;

-- name: ListCallsByStatus :many
SELECT * FROM calls
WHERE status = ?
ORDER BY created_at DESC;

-- name: UpdateCallStatus :one
UPDATE calls
SET status = ?, updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING *;

-- name: CompleteCall :one
UPDATE calls
SET status = 'completed', completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING *;

-- name: DeleteCall :exec
DELETE FROM calls
WHERE id = ?; 