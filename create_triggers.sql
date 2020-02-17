-- Needed triggers

-- Resource.duration > 0
create or replace function checkPositiveResourceDuration()
  returns trigger as 
  $$
  begin
    if new.duration <= 0 then
      raise exception 'Resource duration % is invalid. Must be >= 0', new.duration;
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkPositiveResourceDurationInsertTrigger
  before insert on resource
  for each row
  execute procedure checkPositiveResourceDuration();
create trigger checkPositiveResourceDurationupdateTrigger
  before update on resource
  for each row
  execute procedure checkPositiveResourceDuration();

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
create or replace function checkActivityMessageTarget()
  returns trigger as
  $$
  begin
    if (select idCollection from ResourceActivity where ActivityMessage.idActivity = ResourceActivity.idActivity) is not null then
      raise exception 'ActivityMessage cannot have as target a ResourceActivity which is part of a CollectionActivity';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkActivityMessageTargetTrigger
  before insert on ActivityMessage
  for each row execute procedure checkActivityMessageTarget();

-- ResourceActivity
--   If part of CollectionActivity, must point to a Resource which is part of CollectionActivity's collection
create or replace function checkCollectionResourceActivityTarget()
  returns trigger as
  $$
  begin
    if new.idCollectionActivity is not null and new.idResource not in (
      select distinct
        vcollectionresource.idResource
      from CollectionActivity
        inner join vcollectionresource on collectionActivity.idcollection = vcollectionresource.idcollection 
      where collectionActivity.idActivity = new.idCollectionActivity
    ) then
      raise exception 'ResourceActivity resource is not in associated collection activity collection';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkCollectionResourceActivityTargetTrigger
  before insert on ResourceActivity
  for each row execute procedure checkCollectionResourceActivityTarget();

--   If part of CollectionActivity, started_at > previous.paused_timestamp or started_at > previous.started_at + resource.duration
--   If part of CollectionActivity, users must be a subset of CollectionActivity's users



--   ResourceActivity.paused_at < Resource.duration && >= 0
create or replace function checkPausedAtValidity()
  returns trigger as
  $$
  begin
    if new.pausedAt > (select Resource.duration from Resource where Resource.id = new.idResource) or new.pausedAt < 0
      then raise exception 'ResourceActivity % for Resource % cannot be paused at % (duration %)', new.idActivity, new.idResource, new.pausedAt, (select duration from resource where id = new.idresource);
    end if;
    return new;
  end;
  $$
  language 'plpgsql';

drop trigger checkPausedAtValidityOnUpdateTrigger on resourceactivity;
create trigger checkPausedAtValidityOnUpdateTrigger
  before update on resourceactivity
  for each row execute procedure checkPausedAtValidity();

drop trigger checkPausedAtValidityOnInsertTrigger on resourceactivity;
create trigger checkPausedAtValidityOnInsertTrigger
  before insert on resourceactivity
  for each row execute procedure checkPausedAtValidity();


-- Band-Musician
--   from < to
create or replace function checkBandMusicianFromToIntegrity()
  returns trigger as 
  $$
  begin
    if new.from >= new.to then
      raise exception 'From must be <= to';
    elseif new.to > now() then
      raise exception 'To % cannot be in the future', new.to;
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkBandMusicianFromToIntegrityInsertTrigger
  before insert on bandmusician
  for each row execute procedure checkBandMusicianFromToIntegrity();
create trigger checkBandMusicianFromToIntegrityUpdateTrigger
  before update on bandmusician
  for each row execute procedure checkBandMusicianFromToIntegrity();
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