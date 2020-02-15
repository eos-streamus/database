-- Needed triggers

-- ActivityMessage
--   User is part of activity
--   timestamp > oldest started_at
--   Cannot point to a ResourceActivity which is linked to a CollectionActivity. Change to CollectionActivity id


-- ResourceActivity
--   If part of CollectionActivity, must point to a Resource which is part of CollectionActivity's collection
--   If part of CollectionActivity, started_at > previous.paused_timestamp or started_at > previous.started_at + resource.duration
--   If part of CollectionActivity, users must be a subset of CollectionActivity's users
--   ResourceActivity.paused_at < Resource.duration

-- Band-Musician
--   from < to
--   from > Musician.Artist.dateOfBirth if exists
--   If a musician is member more than once, newer.from > older.to

-- Resource
--   Resource.created_at <= now()
--   Resource.duration > 0

-- Collection
--   Collection.created_at <= now()
--   Collection.updated_at > Collection.created_at && Collection.updated_at <= now()

-- Album
--   Album.release_date <= now()
--   Album.release_date <= Collection.created_at

-- SongCollectionSong
--   track_number > 0
--   track_numbers are continuous integers.

-- Episode
--   SeasonNumber > 0
--   EpisodeNumber > 0
--   EpisodeNumbers follow each other starting at 1

-- VideoPlaylist
--   number > 0
--   numbers follow eachother