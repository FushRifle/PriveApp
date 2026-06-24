-- Inbox queries filter by one participant and order conversations by the
-- latest message. PostgreSQL needs one composite index for each side of the
-- conversation because the lookup uses user1_id OR user2_id.

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user1_last_message_time
ON public.chat_conversations USING btree (
  user1_id,
  last_message_time DESC NULLS LAST
);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user2_last_message_time
ON public.chat_conversations USING btree (
  user2_id,
  last_message_time DESC NULLS LAST
);

ANALYZE public.chat_conversations;

-- Do not add more single-column indexes for id, user1_id, or user2_id.
-- The primary key already indexes id, the unique constraint already indexes
-- (user1_id, user2_id), and the schema already has standalone participant
-- indexes. Duplicate indexes increase storage and slow every write.
