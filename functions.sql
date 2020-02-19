create or replace function createPerson(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date)
  returns integer as 
  $$
  declare
  	_id integer;
  begin
    insert into Person(firstname, lastname, dateOfBirth) values (_firstname, _lastname, _dateOfBirth) returning id into _id;
	return _id;
  end
  $$
  language 'plpgsql';

create or replace function createUser(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50), _password varchar(191))
  returns integer as
  $$
  declare
  	_idPerson integer;
  begin
    with created_person as (
      select * from createPerson(_firstname, _lastname, _dateOfBirth)
    )
    insert into StreamusUser(idPerson, email, username, password) values ((select * from created_person), _email, _username, _password) returning idPerson into _idPerson;
	  return _idPerson;
  end
  $$
  language 'plpgsql';

create or replace function createAdmin(_firstname varchar(200), _lastname varchar(200), _dateOfBirth date, _email varchar(255), _username varchar(50), _password varchar(191))
  returns integer as
  $$
  declare
    _idAdmin integer;
  begin
    with created_user as (
      select * from createUser(_firstname, _lastname, _dateOfBirth, _email, _username, _password)
    )
    insert into Admin(idUser) values ((select * from created_user)) returning idUser into _idAdmin;
    return _idAdmin;
  end
  $$
  language 'plpgsql';



create or replace function createSong(_path varchar(1041), _name varchar(200), _duration integer)
  returns integer as
  $$
  declare
    _idSong integer;
  begin
    with created_resource as (
      insert into Resource(path, name, duration) values (_path, _name, _duration) returning id
    )
    insert into Song(idResource) values ((select id from created_resource)) returning idResource into _idSong;
    return _idSong;
  end
  $$
  language 'plpgsql';

create or replace function createFilm(_path varchar(1041), _name varchar(200), _duration integer)
  returns integer as
  $$
  declare
    _idFilm integer;
  begin
    with
    created_resource as (
      insert into Resource(path, name, duration) values (_path, _name, _duration) returning id
    ),
    created_video as (
      insert into Video(idResource) values ((select id from created_resource)) returning idResource
    )
    insert into Film(idVideo) values ((select idResource from created_video)) returning idVideo into _idFilm;
    return _idFilm;
  end
  $$
  language 'plpgsql';

create or replace function createBand(_name varchar(191))
  returns integer as
  $$
  declare
    _idBand integer;
  begin
    with created_artist as (
      insert into Artist(name) values (_name) returning id
    )
    insert into Band(idArtist) values ((select id from created_artist)) returning idArtist into _idBand;
    return _idBand;
  end;
  $$
  language 'plpgsql';

create or replace function createMusician(_name varchar(191), _idPerson integer default null)
  returns integer as
  $$
  declare
    _idArtist integer;
  begin
    with created_artist as (
      insert into Artist(name) values (_name) returning id
    )
    insert into Musician(idArtist, idPerson) values ((select id from created_artist), _idPerson) returning idArtist into _idArtist;
    return _idArtist;
  end;
  $$
  language 'plpgsql';

create or replace function createAlbum(_name varchar(200), _releaseDate date, variadic _artistIds integer[] default null)
  returns integer as 
  $$
  declare
    _idAlbum integer;
  begin
  	with created_collection as (
		insert into collection(name) values (_name) returning id
	),
	created_song_collection as (
		insert into songcollection(idCollection) values ((select id from created_collection)) returning idCollection
	)
  	insert into album(idSongCollection, releaseDate) values ((select idCollection from created_song_collection), _releaseDate) returning idSongCollection into _idAlbum;
    for i in array_lower(_artistIds, 1) .. array_upper(_artistIds, 1)
    loop
		insert into albumartist(idAlbum, idArtist) values (_idAlbum, _artistIds[i]);
    end loop;
	return _idAlbum;
  end;
  $$
  language 'plpgsql';

create or replace function createEpisode(_path varchar(1041), _name varchar(200), _duration integer, _idSeries integer, _seasonNumber smallint, _episodeNumber smallint)
  returns integer as
  $$
  declare
    _idEpisode integer;
  begin
    with
    created_resource as (
      insert into Resource(path, name, duration) values (_path, _name, _duration) returning id
    ),
    created_video as (
      insert into Video(idResource) values ((select id from created_resource)) returning idResource
    )
    insert into Episode(idVideo, idSeries, seasonNumber, episodeNumber) values ((select idResource from created_video), _idSeries, _seasonNumber, _episodeNumber) returning idVideo into _idEpisode;
    return _idEpisode;
  end;
  $$
  language 'plpgsql';

create or replace function createSeries(_name varchar(200))
  returns integer as
  $$
  declare
    _idSeries integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning id
    ),
    created_video_collection as (
      insert into videocollection(idcollection) values((select id from created_collection)) returning idCollection
    )
	insert into series(idvideocollection) values ((select idCollection from created_video_collection)) returning idVideoCollection into _idSeries;
	return _idSeries;
  end;
  $$
  language 'plpgsql';

create or replace function createCollectionActivity(_idCollection integer)
  returns bigint as
  $$
  declare
    _idCollectionActivity bigint;
  begin
    with
    created_activity as (
      insert into Activity values(default) returning id
    )
    insert into CollectionActivity(idActivity, idCollection) values ((select id from created_activity), _idCollection) returning idActivity into _idCollectionActivity;
    return _idCollectionActivity;
  end
  $$
  language 'plpgsql';

create or replace function createVideoPlaylist(_name varchar(200), _idUser integer)
  returns integer as 
  $$
  declare
    _idVideoPlaylist integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning id
    ),
    created_video_collection as (
      insert into videocollection(idcollection) values((select id from created_collection)) returning idCollection
    )
    insert into videoplaylist(idVideoCollection, idUser) values ((select idCollection from created_video_collection), _idUser) returning idVideoCollection into _idVideoPlaylist;
    return _idVideoPlaylist;
  end;
  $$
  language 'plpgsql';

create or replace function createSongPlaylist(_name varchar(200), _idUser integer)
  returns integer as 
  $$
  declare
    _idSongPlaylist integer;
  begin
    with
    created_collection as (
		  insert into collection(name) values (_name) returning id
    ),
    created_song_collection as (
      insert into SongCollection(idcollection) values((select id from created_collection)) returning idCollection
    )
    insert into SongPlaylist(idSongCollection, idUser) values ((select idCollection from created_song_collection), _idUser) returning idSongCollection into _idSongPlaylist;
    return _idSongPlaylist;
  end;
  $$
  language 'plpgsql';

create or replace function addSongToPlaylist(_idSong integer, _idSongPlaylist integer)
  returns void as
  $$
  declare
    _trackNumber smallint;
  begin
    if not exists(select 1 from songcollectionsong where idsongcollection = _idSongPlaylist) then
      select 1 into _trackNumber;
    else
      select max(trackNumber) + 1 into _trackNumber from songcollectionsong where idsongcollection = _idSongPlaylist;
    end if;
    insert into SongCollectionSong(idSong, idSongCollection, trackNumber) values (_idSong, _idSongPlaylist, _trackNumber);
  end;
  $$
  language 'plpgsql';