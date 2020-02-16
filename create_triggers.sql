-- Needed triggers

-- ActivityMessage
--   User is part of activity
create or replace function checkCollectionActivityMembershipOnNewMessage()
  returns trigger as 
  $$
  begin
    if new.idUser not in (
      select UserActivity.idUser from UserActivity where UserActivity.idActivity = new.idActivity
    ) then
      raise exception 'User % is not in activity %', new.idUser, new.idActivity;
    end if;
    return new;
  end;
  $$
  language 'plpgsql';


create trigger checkCollectionActivityMembershipOnNewMessageTrigger
  before insert on ActivityMessage
  for each row execute procedure checkCollectionActivityMembershipOnNewMessage();

--   timestamp > oldest started_at
create or replace function checkMessageTimestampValidity()
  returns trigger as 
  $$
  declare
    oldest_timestamp timestamp;
  begin
    select into oldest_timestamp
    min(ResourceActivity.startedAt)
    from ResourceActivity
        where ResourceActivity.idActivity = new.idActivity or ResourceActivity.idCollectionActivity = new.idActivity;
    if
      new.postedAt > now() then
        raise Exception 'Timestamp % is in the future', new.postedAt;
    elseif
      new.postedAt < oldest_timestamp then
        raise exception 'Timestamp % is before lowest acceptable value %', new.postedAt, oldest_timestamp;
    end if;
    return new;
  end
  $$
  language 'plpgsql';
create trigger checkMessageTimestampValidityTrigger
  before insert on ActivityMessage
  for each row execute procedure checkMessageTimestampValidity();

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