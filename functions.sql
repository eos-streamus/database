drop function if exists  createPerson(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date);
create or replace function createPerson(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date)
  returns table (
    id integer,
    firstname varchar(200),
    lastname varchar(200),
    dateOfBirth date,
    createdAt timestamp,
    updatedAt timestamp
  ) as 
  $$
  declare
  	_id integer;
  begin
    insert into Person(firstname, lastname, dateOfBirth) values (_firstname, _lastname, _dateOfBirth) returning Person.id into _id;
    return query
      select
        *
      from Person
      where Person.id = _id;
  end
  $$
  language 'plpgsql';

drop function if exists  createUser(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50));
create or replace function createUser(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50))
  returns table (
    id integer,
    firstname varchar(200),
    lastname varchar(200),
    dateOfBirth date,
    createdAt timestamp,
    updatedAt timestamp,
    email varchar(255),
    username varchar(50)
  ) as
  $$
  declare
  	_idPerson integer;
  begin
    with created_person as (
      select * from createPerson(_firstname, _lastname, _dateOfBirth)
    )
    insert into StreamusUser(idPerson, email, username) values ((select created_person.id from created_person), _email, _username) returning idPerson into _idPerson;
	  return query
      select
        *
      from vuser
      where vuser.id = _idPerson;
  end
  $$
  language 'plpgsql';

drop function if exists  upsertUserPassword(_idUser integer, _password varchar(191));
create or replace function upsertUserPassword(_idUser integer, _password varchar(191))
  returns integer as
  $$
  begin
    if exists (select 1 from UserPassword where idUser = _idUser) then
      update UserPassword set password = _password where idUser = _idUser;
    else
      insert into UserPassword(idUser, password) values (_idUser, _password);
    end if;
    return _idUser;
  end;
  $$
  language 'plpgsql';

drop function if exists  createAdmin(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50));
create or replace function createAdmin(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50))
  returns table (
    id integer,
    firstname varchar(200),
    lastname varchar(200),
    dateOfBirth date,
    createdAt timestamp,
    updatedAt timestamp,
    email varchar(255),
    username varchar(50)
  ) as
  $$
  declare
    _idAdmin integer;
  begin
    with created_user as (
      select * from createUser(_firstname, _lastname, _dateOfBirth, _email, _username)
    )
    insert into Admin(idUser) values ((select created_user.id from created_user)) returning idUser into _idAdmin;
    return query
      select
        *
      from vuser
      where vuser.id = _idAdmin;
  end
  $$
  language 'plpgsql';

drop function if exists  createSong(_path varchar(1041), _name varchar(200), _duration integer);
create or replace function createSong(_path varchar(1041), _name varchar(200), _duration integer)
  returns table (
    id integer,
    path varchar(1041),
    name varchar(200),
    createdAt timestamp,
    duration integer
  ) as 
  $$
  declare
    _idSong integer;
  begin
    insert into Resource(path, name, duration) values (_path, _name, _duration);
    insert into Song(idResource) values ((select resource.id from resource where resource.path = _path));
    return query
      select
        vsong.id,
        vsong.path,
        vsong.name,
        vsong.createdAt,
        vsong.duration
      from vsong where vsong.path = _path;
  end
  $$
  language 'plpgsql';

drop function if exists  createFilm(_path varchar(1041), _name varchar(200), _duration integer);
create or replace function createFilm(_path varchar(1041), _name varchar(200), _duration integer)
  returns table (
    id integer,
    path varchar(1041),
    name varchar(200),
    createdAt timestamp,
    duration integer
  ) as    
  $$
  declare
    _idFilm integer;
  begin
    with
    created_resource as (
      insert into Resource(path, name, duration) values (_path, _name, _duration) returning Resource.id
    ),
    created_video as (
      insert into Video(idResource) values ((select created_resource.id from created_resource)) returning Video.idResource
    )
    insert into Film(idVideo) values ((select created_video.idResource from created_video)) returning Film.idVideo into _idFilm;
    return query
      select
        vfilm.id,
        vfilm.path,
        vfilm.name,
        vfilm.createdAt,
        vfilm.duration
      from vfilm where vfilm.id = _idFilm;
  end
  $$
  language 'plpgsql';

drop function if exists  createBand(_name varchar(191));
create or replace function createBand(_name varchar(191))
  returns table(
    id integer,
    name varchar(191)
  ) as
  $$
  declare
    _idBand integer;
  begin
    with created_artist as (
      insert into Artist(name) values (_name) returning Artist.id
    )
    insert into Band(idArtist) values ((select created_artist.id from created_artist)) returning idArtist into _idBand;
    return query
      select
        artist.id,
        artist.name
      from Band
        inner join artist on band.idartist = artist.id
      where band.idartist = _idBand;
  end;
  $$
  language 'plpgsql';

drop function if exists  createMusician(_name varchar(191), _idPerson integer);
create or replace function createMusician(_name varchar(191), _idPerson integer default null)
  returns table(
    id integer,
    name varchar(191),
    idPerson integer
  ) as
  $$
  declare
    _idArtist integer;
  begin
    if _name is null and _idPerson is null then raise exception 'Musician name and idPerson cannot both be null'; end if;
    with created_artist as (
      insert into Artist(name) values (_name) returning Artist.id
    )
    insert into Musician(idArtist, idPerson) values ((select created_artist.id from created_artist), _idPerson) returning idArtist into _idArtist;
    return query
      select
        artist.id,
        artist.name,
        musician.idPerson
      from musician
        inner join artist on musician.idArtist = artist.id
      where musician.idArtist = _idArtist;
  end;
  $$
  language 'plpgsql';

drop function if exists  createAlbum(_name varchar(200), _releaseDate date, variadic _artistIds integer[]);
create or replace function createAlbum(_name varchar(200), _releaseDate date, variadic _artistIds integer[] default null)
  returns table(
    id integer,
    name varchar(200),
    createdAt timestamp,
    updatedAt timestamp,
    releaseDate date
  ) as 
  $$
  declare
    _idAlbum integer;
  begin
  	with created_collection as (
		insert into collection(name) values (_name) returning collection.id
	),
	created_song_collection as (
		insert into songcollection(idCollection) values ((select created_collection.id from created_collection)) returning SongCollection.idCollection
	)
  insert into album(idSongCollection, releaseDate) values ((select idCollection from created_song_collection), _releaseDate) returning idSongCollection into _idAlbum;
  if _artistIds is not null then
    for i in array_lower(_artistIds, 1) .. array_upper(_artistIds, 1)
    loop
    insert into albumartist(idAlbum, idArtist) values (_idAlbum, _artistIds[i]);
    end loop;
  end if;
	return query
    select
      collection.*,
      album.releaseDate
    from album
      inner join songcollection on album.idsongcollection = songcollection.idcollection
      inner join collection on songcollection.idcollection = collection.id
    where album.idsongcollection = _idAlbum;
  end;
  $$
  language 'plpgsql';

drop function if exists  createEpisode(_path varchar(1041), _name varchar(200), _duration integer, _idSeries integer, _seasonNumber smallint, _episodeNumber smallint);
create or replace function createEpisode(_path varchar(1041), _name varchar(200), _duration integer, _idSeries integer, _seasonNumber smallint, _episodeNumber smallint)
  returns table (
    id integer,
    path varchar(1041),
    name varchar(200),
    duration integer,
    createdAt timestamp,
    idSeries integer,
    seasonNumber smallint,
    episodeNumber smallint
  ) as
  $$
  declare
    _idEpisode integer;
  begin
    with
    created_resource as (
      insert into Resource(path, name, duration) values (_path, _name, _duration) returning Resource.id
    ),
    created_video as (
      insert into Video(idResource) values ((select created_resource.id from created_resource)) returning idResource
    )
    insert into Episode(idVideo, idSeries, seasonNumber, episodeNumber) values ((select idResource from created_video), _idSeries, _seasonNumber, _episodeNumber) returning idVideo into _idEpisode;
    return query
      select 
        vepisode.id,
        vepisode.path,
        vepisode.name,
        vepisode.duration,
        vepisode.createdAt,
        vepisode.idseries,
        vepisode.seasonnumber,
        vepisode.episodenumber
      from vepisode where vepisode.id = _idEpisode;
  end;
  $$
  language 'plpgsql';

drop function if exists  createSeries(_name varchar(200));
create or replace function createSeries(_name varchar(200))
  returns table(
    id integer,
    name varchar(200),
    createdAt timestamp,
    updatedAt timestamp
  ) as
  $$
  declare
    _idSeries integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning collection.id
    ),
    created_video_collection as (
      insert into videocollection(idcollection) values((select created_collection.id from created_collection)) returning VideoCollection.idCollection
    )
	insert into series(idvideocollection) values ((select created_video_collection.idCollection from created_video_collection)) returning series.idVideoCollection into _idSeries;
	return query
    select
      collection.id,
      collection.name,
      collection.createdAt,
      collection.updatedAt
    from series
      inner join collection on series.idVideoCollection = Collection.id
    where series.idvideocollection = _idSeries;
  end;
  $$
  language 'plpgsql';

drop function if exists  createVideoPlaylist(_name varchar(200), _idUser integer);
create or replace function createVideoPlaylist(_name varchar(200), _idUser integer)
  returns table(
    id integer,
    name varchar(200),
    createdAt timestamp,
    updatedAt timestamp,
    idUser integer
  ) as 
  $$
  declare
    _idVideoPlaylist integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning collection.id
    ),
    created_video_collection as (
      insert into videocollection(idcollection) values((select created_collection.id from created_collection)) returning videocollection.idCollection
    )
    insert into videoplaylist(idVideoCollection, idUser) values ((select created_video_collection.idCollection from created_video_collection), _idUser) returning VideoPlaylist.idVideoCollection into _idVideoPlaylist;
    return query
      select
        collection.id,
        collection.name,
        collection.createdAt,
        collection.updatedAt,
        videoplaylist.idUser
      from videoplaylist
        inner join collection on videoplaylist.idvideocollection = collection.id
      where videoplaylist.idvideocollection = _idVideoPlaylist;
  end;
  $$
  language 'plpgsql';

drop function if exists  createSongPlaylist(_name varchar(200), _idUser integer);
create or replace function createSongPlaylist(_name varchar(200), _idUser integer)
  returns table (
    id integer,
    name varchar(200),
    createdAt timestamp,
    updatedAt timestamp,
    userId integer
  ) as 
  $$
  declare
    _idSongPlaylist integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning collection.id
    ),
    created_song_collection as (
      insert into SongCollection(idcollection) values((select created_collection.id from created_collection)) returning Songcollection.idCollection
    )
    insert into SongPlaylist(idSongCollection, idUser) values ((select created_song_collection.idCollection from created_song_collection), _idUser) returning idSongCollection into _idSongPlaylist;
    return query
      select
        collection.id,
        collection.name,
        collection.createdAt,
        collection.updatedAt,
        SongPlaylist.idUser
      from SongPlaylist
        inner join collection on songplaylist.idsongcollection = collection.id
      where SongPlaylist.idSongCollection = _idSongPlaylist;
  end;
  $$
  language 'plpgsql';
  
drop function if exists  addSongToSongCollection(_idSong integer, _idSongCollection integer);
create or replace function addSongToSongCollection(_idSong integer, _idSongCollection integer)
  returns integer as
  $$
  declare
    _trackNumber smallint;
  begin
    if not exists(select 1 from songcollectionsong where idsongcollection = _idSongCollection) then
      select 1 into _trackNumber;
    else
      select max(trackNumber) + 1 into _trackNumber from songcollectionsong where idsongcollection = _idSongCollection;
    end if;
    insert into SongCollectionSong(idSong, idSongCollection, trackNumber) values (_idSong, _idSongCollection, _trackNumber);
	return _trackNumber;
  end;
  $$
  language 'plpgsql';

drop function if exists  addVideoToPlaylist(_idVideo integer, _idVideoPlaylist integer);
create or replace function addVideoToPlaylist(_idVideo integer, _idVideoPlaylist integer)
  returns table (idVideoPlaylist integer, idVideo integer, number smallint) as 
  $$
  declare
    _number integer;
  begin
    if not exists(select 1 from VideoPlaylistVideo where VideoPlaylistVideo.idVideoPlaylist = _idVideoPlaylist) then
      select 1 into _number;
    else
      select max(VideoPlaylistVideo.number) + 1 into _number from VideoPlaylistVideo where VideoPlaylistVideo.idVideoPlaylist = _idVideoPlaylist;
    end if;
    insert into VideoPlaylistVideo(idVideo, idVideoPlaylist, number) values (_idVideo, _idVideoPlaylist, _number);
    return query
      select
        VideoPlaylistVideo.idVideoPlaylist,
        VideoPlaylistVideo.idVideo,
        VideoPlaylistVideo.number
      from VideoPlaylistVideo
      where VideoPlaylistVideo.idVideo = _idVideo and VideoPlaylistVideo.idVideoPlaylist = _idVideoPlaylist;
  end;
  $$
  language 'plpgsql';

  drop function if exists createResourceActivity(_idResource integer, _idUser integer);
  create or replace function createResourceActivity(_idResource integer, _idUser integer default null, _idCollectionActivity bigint default null)
    returns table (
      id bigint,
      idResource integer,
      idCollectionActivity bigint,
      idUser integer,
      manages boolean
    ) as
    $$
    declare
      _idActivity integer;
    begin
      with
      created_activity as (
        insert into activity values(default) returning activity.id
      ),

      created_resource_activity as (
        insert into resourceactivity(idActivity, idresource, idCollectionActivity) values ((select created_activity.id from created_activity), _idResource, _idCollectionActivity) returning resourceactivity.idactivity
      )
      select into _idActivity created_resource_activity.idActivity from created_resource_activity;
      if _idUser is not null then
        insert into useractivity(idActivity, idUser, manages) values (_idActivity, _idUser, true);
      end if;
      return query
        select
          activity.id,
          ResourceActivity.idResource,
          ResourceActivity.idCollectionActivity,
          UserActivity.idUser,
          UserActivity.manages
        from Activity
          inner join ResourceActivity on Activity.id = ResourceActivity.idActivity
          left join UserActivity on ResourceActivity.idActivity = UserActivity.idActivity
        where
          activity.id = _idActivity;
    end;
    $$
    language 'plpgsql';

  drop function if exists createCollectionActivity(_idCollection integer, _idUser integer);
  create or replace function createCollectionActivity(_idCollection integer, _idUser integer)
    returns table (
      id bigint,
      idCollection integer,
      idUser integer,
      manages boolean
    ) as
    $$
    declare
      _idActivity integer;
    begin
      with
      created_activity as (
        insert into activity values(default) returning activity.id
      ),

      created_Collection_activity as (
        insert into Collectionactivity(idActivity, idCollection) values ((select created_activity.id from created_activity), _idCollection) returning Collectionactivity.idactivity
      )
      insert into useractivity(idActivity, idUser, manages) values ((select idactivity from created_Collection_activity), _idUser, true) returning useractivity.idactivity into _idActivity;
      return query
        select
          activity.id,
          CollectionActivity.idCollection,
          UserActivity.idUser,
          UserActivity.manages
        from Activity
          inner join CollectionActivity on Activity.id = CollectionActivity.idActivity
          inner join UserActivity on CollectionActivity.idActivity = UserActivity.idActivity
        where
          activity.id = _idActivity;
    end;
    $$
    language 'plpgsql';

  drop function if exists swapTrackNumbers(_idSongCollection integer, _idSong1 integer, _idSong2 integer);
  create function swapTrackNumbers(_idSongCollection integer, _idSong1 integer, _idSong2 integer)
    returns void as
    $$
      declare
        _trackNumber1 smallint;
        _trackNumber2 smallint;
      begin
        select
          tracknumber
        from SongCollectionSong
        where
          SongCollectionSong.idSongCollection = _idSongCollection and
          SongCollectionSong.idSong = _idSong1 into _trackNumber1;
        select
          tracknumber
        from SongCollectionSong
        where
          SongCollectionSong.idSongCollection = _idSongCollection and
          SongCollectionSong.idSong = _idSong2 into _trackNumber1;
        update SongCollectionSong set trackNumber = _trackNumber2 where idSongCollection = _idSongCollection and idSong = _idSong1;
        update SongCollectionSong set trackNumber = _trackNumber1 where idSongCollection = _idSongCollection and idSong = _idSong2;
        return;
      end;

    $$
    language 'plpgsql';