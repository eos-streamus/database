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

drop trigger if exists checkPausedAtValidityOnUpdateTrigger on resourceactivity;
create trigger checkPausedAtValidityOnUpdateTrigger
  before update on resourceactivity
  for each row execute procedure checkPausedAtValidity();

drop trigger if exists checkPausedAtValidityOnInsertTrigger on resourceactivity;
create trigger checkPausedAtValidityOnInsertTrigger
  before insert on resourceactivity
  for each row execute procedure checkPausedAtValidity();


-- Band-Musician
--   from < to
drop trigger if exists checkBandMusicianFromToIntegrityInsertTrigger on bandmusician;
drop trigger if exists checkBandMusicianFromToIntegrityUpdateTrigger on bandmusician;
create or replace function checkBandMusicianFromToIntegrity()
  returns trigger as 
  $$
  begin
    if new.memberTo is not null and new.memberfrom >= new.memberto then
      raise exception 'From must be <= to';
    elseif new.memberto is not null and new.memberto > now() then
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

drop trigger if exists checkMusicianDateOfBirthAgainstBandMembershipInsertTrigger on bandmusician;
drop trigger if exists checkMusicianDateOfBirthAgainstBandMembershipUpdateTrigger on bandmusician;
create or replace function checkMusicianDateOfBirthAgainstBandMembership()
  returns trigger as
  $$
  declare
    _idPerson integer;
    _dateOfBirth date;
  begin
    select into _idPerson
    idperson from musician where idArtist = new.idMusician;
    if 
      _idPerson is not null and (
        select dateOfBirth from person where id = _idPerson
      ) > new.memberFrom then
        raise exception 'Artist is born after band membership start';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkMusicianDateOfBirthAgainstBandMembershipInsertTrigger
  before insert on bandmusician
  for each row execute procedure checkMusicianDateOfBirthAgainstBandMembership();
create trigger checkMusicianDateOfBirthAgainstBandMembershipUpdateTrigger
  before update on bandmusician
  for each row execute procedure checkMusicianDateOfBirthAgainstBandMembership();

--   If a musician is member more than once, newer.from > older.to or older.to is null and newer.to < older.from
drop trigger if exists checkMultipleMusicianBandMembershipDateIntegrityInsertTrigger on bandmusician;
drop trigger if exists checkMultipleMusicianBandMembershipDateIntegrityUpdateTrigger on bandmusician;
create or replace function checkMultipleMusicianBandMembershipDateIntegrity()
  returns trigger as
  $$
  begin
    if
      exists (
        select 1 
        from bandmusician 
        where
          bandmusician.idband = new.idband and 
          bandmusician.idmusician = new.idmusician and 
          bandmusician.memberfrom != new.memberfrom
      ) and exists (
        select 1
        from bandmusician
        where
          bandmusician.idband = new.idband and 
          bandmusician.idmusician = new.idmusician and 
          bandmusician.memberfrom != new.memberfrom and (
            bandmusician.memberto is null or
            bandmusician.memberto >= new.memberfrom
          )
      ) then
        raise exception 'Musician cannot overlapping memberships to band';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkMultipleMusicianBandMembershipDateIntegrityInsertTrigger
  before Insert on bandmusician
  for each row execute procedure checkMultipleMusicianBandMembershipDateIntegrity();

create trigger checkMultipleMusicianBandMembershipDateIntegrityUpdateTrigger
  before Update on bandmusician
  for each row execute procedure checkMultipleMusicianBandMembershipDateIntegrity();

-- Resource
--   Resource.created_at <= now()
create or replace function checkResourceCreatedAtValidity()
  returns trigger as 
  $$
  begin
    if new.createdAt > now() then
      raise exception 'Resource cannot be created in the future';
	  end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkResourceCreatedAtValidityInsertTrigger
  before insert on resource
  for each row execute procedure checkResourceCreatedAtValidity();
create trigger checkResourceCreatedAtValidityupdateTrigger
  before update on resource
  for each row execute procedure checkResourceCreatedAtValidity();

--   Resource.duration > 0
create or replace function checkResourceDuration()
  returns trigger as 
  $$
  begin
    if new.duration <= 0 then
      raise exception 'Resource must have positive duration';
	  end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkResourceDurationInsertTrigger
  before insert on resource
  for each row execute procedure checkResourceDuration();
create trigger checkResourceDurationupdateTrigger
  before update on resource
  for each row execute procedure checkResourceDuration();


-- Collection
--   Collection.created_at <= now()
create or replace function checkCollectionCreatedAtValidity()
  returns trigger as 
  $$
  begin
    if new.createdAt > now() then
      raise exception 'Collection cannot be created in the future';
	  end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkCollectionCreatedAtValidityInsertTrigger
  before insert on Collection
  for each row execute procedure checkCollectionCreatedAtValidity();
create trigger checkCollectionCreatedAtValidityupdateTrigger
  before update on Collection
  for each row execute procedure checkCollectionCreatedAtValidity();

--   Collection.updated_at >= Collection.created_at && Collection.updated_at <= now()
create or replace function checkCollectionUpdatedAtValidity()
  returns trigger as 
  $$
  begin
    if new.updatedAt < new.createdAt or new.updatedAt > now() then
      raise exception 'Invalid updatedAt timestamp. Must be between createdAt and now';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkCollectionUpdatedAtValidityInsertTrigger
  before insert on collection
  for each row execute procedure checkCollectionUpdatedAtValidity();
create trigger checkCollectionUpdatedAtValidityUpdateTrigger
  before update on collection
  for each row execute procedure checkCollectionUpdatedAtValidity();

-- Update songcollection updatedAt
drop trigger if exists updateSongCollectionUpdatedAtInsertTrigger on SongCollectionSong;
drop trigger if exists updateSongCollectionUpdatedAtUpdateTrigger on SongCollectionSong;
create or replace function updateSongCollectionTimestamp()
  returns trigger as 
  $$
  begin
    update collection set updatedAt = now() where collection.id = new.idsongcollection;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger updateSongCollectionUpdatedAtInsertTrigger
  before insert on SongCollectionSong
  for each row execute procedure updateSongCollectionTimestamp();
create trigger updateSongCollectionUpdatedAtUpdateTrigger
  before Update on SongCollectionSong
  for each row execute procedure updateSongCollectionTimestamp();

drop trigger if exists updateVideoPlaylistUpdatedAtInsertTrigger on VideoPlaylistVideo;
drop trigger if exists updateVideoPlaylistUpdatedAtUpdateTrigger on VideoPlaylistVideo;
create or replace function updateVideoPlaylistTimestamp()
  returns trigger as 
  $$
  begin
    update collection set updatedAt = now() where collection.id = new.idVideoPlaylist;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger updateVideoPlaylistUpdatedAtInsertTrigger
  before insert on VideoPlaylistVideo
  for each row execute procedure updateVideoPlaylistTimestamp();
create trigger updateVideoPlaylistUpdatedAtUpdateTrigger
  before Update on VideoPlaylistVideo
  for each row execute procedure updateVideoPlaylistTimestamp();

drop trigger if exists updateSeriesUpdatedAtInsertTrigger on Episode;
drop trigger if exists updateSeriesUpdatedAtUpdateTrigger on Episode;
create or replace function updateSeriesTimestamp()
  returns trigger as
  $$
  begin
    update collection set updatedAt = now() where collection.id = new.idseries;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger updateSeriesUpdatedAtInsertTrigger
  before insert on Episode
  for each row execute procedure updateSeriesTimestamp();
create trigger updateSeriesUpdatedAtUpdateTrigger
  before Update on Episode
  for each row execute procedure updateSeriesTimestamp();

-- Album
--   Album.release_date <= now()
--   Album.release_date <= Collection.created_at
create or replace function checkAlbumDateValidity()
  returns trigger as 
  $$
  begin
    if new.releaseDate > now() or new.releaseDate > (select createdAt from collection where id = new.idSongCollection) then
      raise exception 'Invalid album release date. Must be in the past and before collection creation date';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkAlbumDateValidityInsertTrigger
  before insert on Album
  for each row execute procedure checkAlbumDateValidity();
create trigger checkAlbumDateValidityUpdateTrigger
  before update on Album
  for each row execute procedure checkAlbumDateValidity();

-- SongCollectionSong
--   track_number > 0
create or replace function checkPositiveTrackNumber()
  returns trigger as 
  $$
  begin
    if new.trackNumber < 1 then
      raise exception 'Track number must be positive';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkPositiveTrackNumber
  before insert or update on SongCollectionSong
  for each row execute procedure checkPositiveTrackNumber();

--   track_numbers are continuous integers.
create or replace function checkContinuousTrackNumbers()
  returns trigger as 
  $$
  declare
    _max smallint;
    _min smallint;
    _count smallint;
  begin
  	if not exists(select 1 from songcollectionsong where songcollectionsong.idsongcollection = new.idsongcollection) and new.tracknumber != 1
		then raise exception 'Invalid track numbers';
	end if;
    select
      count(SongCollectionSong.trackNumber), max(SongCollectionSong.trackNumber), min(SongCollectionSong.trackNumber)
      into _count, _max, _min
    from SongCollectionSong
    where SongCollectionSong.idsongcollection = new.idsongcollection
	  group by SongCollectionSong.idsongcollection;
    if _min != 1 or _max != _count then
      raise exception 'Invalid track numbers';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkContinuousTrackNumbersTrigger
  after insert or update on SongCollectionSong
  for each row execute procedure checkContinuousTrackNumbers();

-- Episode
--   SeasonNumber > 0
--   EpisodeNumber > 0
create or replace function checkPositiveSeasonAndEpisodeNumber()
  returns trigger as 
  $$
  begin
    if new.seasonNumber < 1 then
      raise exception 'Season number must be positive';
    elseif new.episodeNumber < 1 then
      raise exception 'Episode number must be positive';
    end if;
    return new;
  end
  $$
  language 'plpgsql';
create trigger checkPositiveSeasonAndEpisodeNumberTrigger
  before insert or update on Episode
  for each row execute procedure checkPositiveSeasonAndEpisodeNumber();

--   EpisodeNumbers follow each other starting at 1
create or replace function checkContinuousEpisodeNumbersInSeason()
  returns trigger as 
  $$
  declare
    _max smallint;
    _min smallint;
    _count smallint;
  begin
  	if not exists(select 1 from episode where episode.idseries = new.idseries and episode.seasonnumber = new.seasonnumber) and new.episodenumber != 1
		then raise exception 'Invalid episode numbers';
	end if;
    select
      count(episode.episodenumber), max(episode.episodenumber), min(episode.episodenumber)
      into _count, _max, _min
    from episode
    where episode.seasonnumber = new.seasonnumber and episode.idseries = new.idseries
	  group by episode.seasonnumber, episode.idseries;
    if _min != 1 or _max != _count then
      raise exception 'Invalid episode numbers';
    end if;
    return new;
  end;
  $$
  language 'plpgsql';
create trigger checkContinuousEpisodeNumbersInSeasonTrigger
  after insert or update on episode
  for each row execute procedure checkContinuousEpisodeNumbersInSeason();

-- VideoPlaylist
--   number > 0
--   numbers follow eachother
create or replace function checkPositiveVideoPlaylistVideoNumber()
  returns trigger as 
  $$
  begin
    if new.number < 1 then
      raise exception 'VideoPlaylistVideo number must be positive';
    end if;
    return new;
  end
  $$
  language 'plpgsql';
create trigger checkPositiveVideoPlaylistVideoNumberTrigger
  before insert or update on VideoPlaylistVideo
  for each row execute procedure checkPositiveVideoPlaylistVideoNumber();

drop trigger if exists checkContinuousVideoPlaylistVideoNumbersTrigger on VideoPlaylistVideo;
create or replace function checkContinuousVideoPlaylistVideoNumbers()
  returns trigger as 
  $$
  declare
    _max smallint;
    _min smallint;
    _count smallint;
  begin
    if not exists (select 1 from VideoPlaylistVideo where VideoPlaylistVideo.idVideoPlaylist = new.idVideoPlaylist) and new.number != 1
      then raise exception 'First video in playlist number should be 1';
    end if;
    select
      count(*),
      max(VideoPlaylistVideo.number),
      min(VideoPlaylistVideo.number)
    into
      _count,
      _max,
      _min
    from VideoPlaylistVideo
    where VideoPlaylistVideo.idVideoPlaylist = new.idVideoPlaylist;
    if _min != 1 or _max != _count then
      raise exception 'Invalid VideoPlaylistVideo number';
    end if;
    return new;
  end;
  $$
  language plpgsql;
create trigger checkContinuousVideoPlaylistVideoNumbersTrigger
  after insert or update on VideoPlaylistVideo
  for each row execute procedure checkContinuousVideoPlaylistVideoNumbers();

-- Delete resource when deleting song
create or replace function deleteResourceOnDeleteSong()
  returns trigger as
  $$
  begin
    delete from resource where id = old.idresource;
    return old;
  end;
  $$
  language 'plpgsql';
create trigger deleteResourceOnDeleteSongTrigger
  after delete on song
  for each row execute procedure deleteResourceOnDeleteSong();