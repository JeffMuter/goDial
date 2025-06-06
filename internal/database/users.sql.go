// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.27.0
// source: users.sql

package database

import (
	"context"
)

const createUser = `-- name: CreateUser :one
INSERT INTO users (email, name)
VALUES (?, ?)
RETURNING id, email, name, created_at, updated_at, minutes
`

type CreateUserParams struct {
	Email string `json:"email"`
	Name  string `json:"name"`
}

func (q *Queries) CreateUser(ctx context.Context, arg CreateUserParams) (User, error) {
	row := q.db.QueryRowContext(ctx, createUser, arg.Email, arg.Name)
	var i User
	err := row.Scan(
		&i.ID,
		&i.Email,
		&i.Name,
		&i.CreatedAt,
		&i.UpdatedAt,
		&i.Minutes,
	)
	return i, err
}

const deleteUser = `-- name: DeleteUser :exec
DELETE FROM users
WHERE id = ?
`

func (q *Queries) DeleteUser(ctx context.Context, id int64) error {
	_, err := q.db.ExecContext(ctx, deleteUser, id)
	return err
}

const getUser = `-- name: GetUser :one
SELECT id, email, name, created_at, updated_at, minutes FROM users
WHERE id = ?
`

func (q *Queries) GetUser(ctx context.Context, id int64) (User, error) {
	row := q.db.QueryRowContext(ctx, getUser, id)
	var i User
	err := row.Scan(
		&i.ID,
		&i.Email,
		&i.Name,
		&i.CreatedAt,
		&i.UpdatedAt,
		&i.Minutes,
	)
	return i, err
}

const getUserByEmail = `-- name: GetUserByEmail :one
SELECT id, email, name, created_at, updated_at, minutes FROM users
WHERE email = ?
`

func (q *Queries) GetUserByEmail(ctx context.Context, email string) (User, error) {
	row := q.db.QueryRowContext(ctx, getUserByEmail, email)
	var i User
	err := row.Scan(
		&i.ID,
		&i.Email,
		&i.Name,
		&i.CreatedAt,
		&i.UpdatedAt,
		&i.Minutes,
	)
	return i, err
}

const getUserMinutes = `-- name: GetUserMinutes :one
SELECT minutes FROM users
WHERE email = ?
`

func (q *Queries) GetUserMinutes(ctx context.Context, email string) (interface{}, error) {
	row := q.db.QueryRowContext(ctx, getUserMinutes, email)
	var minutes interface{}
	err := row.Scan(&minutes)
	return minutes, err
}

const listUsers = `-- name: ListUsers :many
SELECT id, email, name, created_at, updated_at, minutes FROM users
ORDER BY created_at DESC
`

func (q *Queries) ListUsers(ctx context.Context) ([]User, error) {
	rows, err := q.db.QueryContext(ctx, listUsers)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []User{}
	for rows.Next() {
		var i User
		if err := rows.Scan(
			&i.ID,
			&i.Email,
			&i.Name,
			&i.CreatedAt,
			&i.UpdatedAt,
			&i.Minutes,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const updateUser = `-- name: UpdateUser :one
UPDATE users
SET name = ?, updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING id, email, name, created_at, updated_at, minutes
`

type UpdateUserParams struct {
	Name string `json:"name"`
	ID   int64  `json:"id"`
}

func (q *Queries) UpdateUser(ctx context.Context, arg UpdateUserParams) (User, error) {
	row := q.db.QueryRowContext(ctx, updateUser, arg.Name, arg.ID)
	var i User
	err := row.Scan(
		&i.ID,
		&i.Email,
		&i.Name,
		&i.CreatedAt,
		&i.UpdatedAt,
		&i.Minutes,
	)
	return i, err
}
