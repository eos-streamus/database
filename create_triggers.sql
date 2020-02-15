-- Needed triggers

-- ActivityMessage
--   User is part of activity
--   timestamp > oldest started_at
--   Cannot point to a ResourceActivity which is linked to a CollectionActivity. Change to CollectionActivity id


-- ResourceActivity
--   If part of CollectionActivity, must point to a Resource which is part of CollectionActivity's collection
--   If part of CollectionActivity, started_at > previous.paused_timestamp or started_at > previous.started_at + resource.duration
--   If part of CollectionActivity, users must be a subset of CollectionActivity's users

-- Band-Musician
--   from < to
--   from > Musician.Artist.dateOfBirth if exists
--   If a musician is member more than once, newer.from > older.to