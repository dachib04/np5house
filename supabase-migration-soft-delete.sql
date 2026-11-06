-- Soft-delete: "Delete" in the admin now just marks a house as deleted (recoverable),
-- instead of permanently destroying it. A separate "Delete Permanently" action does the
-- real, unrecoverable delete.
alter table houses add column if not exists deleted_at timestamptz;
