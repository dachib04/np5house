-- Draft/Live control: new houses stay hidden from the public site until explicitly
-- published, so half-finished houses (no prices/images yet) never show to visitors.
-- Existing houses default to true so nothing currently live disappears.
alter table houses add column if not exists published boolean not null default true;
