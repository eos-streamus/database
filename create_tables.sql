/*
-- Database: streamus

-- DROP DATABASE streamus;

CREATE DATABASE streamus
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
*/

drop schema if exists public cascade;
create schema public;

-- People
create table Person(
	id serial primary key,
  firstname varchar(200) not null,
  lastname varchar(200) not null,
  dateOfBirth date,
  createdAt timestamp not null default now(),
  updatedAt timestamp not null default now()
);

create table StreamusUser(
	idPerson integer primary key,
  email varchar(255) not null unique,
  username varchar(50) not null,
  foreign key(idPerson) references Person(id) on delete cascade on update cascade
);

create table UserPassword(
  idUser integer primary key,
  password varchar(191) not null,
  foreign key(idUser) references StreamusUser(idPerson) on delete cascade on update cascade
);

create table Admin(
	idUser integer primary key,
  foreign key(idUser) references StreamusUser(idPerson) on delete cascade on update cascade
);

-- Collections

create table Collection(
	id serial primary key,
  name varchar(200) not null,
  createdAt timestamp not null default now(),
  updatedAt timestamp not null default now()
);

create table SongCollection(
	idCollection integer primary key,
  foreign key (idCollection) references Collection(id) on delete cascade on update cascade
);

create table Album(
	idSongCollection integer primary key,
  releaseDate date,
  foreign key(idSongCollection) references SongCollection(idCollection) on delete cascade on update cascade
);

create table SongPlaylist(
	idSongCollection integer primary key,
  idUser integer not null,
  foreign key(idSongCollection) references SongCollection(idCollection) on delete cascade on update cascade,
  foreign key(idUser) references StreamusUser(idPerson) on delete cascade on update cascade
);

create table VideoCollection(
	idCollection integer primary key,
  foreign key (idCollection) references Collection(id) on delete cascade on update cascade
);

create table VideoPlaylist(
	idVideoCollection integer primary key,
  idUser integer not null,
  foreign key(idVideoCollection) references VideoCollection(idCollection) on delete cascade on update cascade,
  foreign key(idUser) references StreamusUser(idPerson) on delete cascade on update cascade
);

create table Series(
	idVideoCollection integer primary key,
  foreign key(idVideoCollection) references VideoCollection(idCollection) on delete cascade on update cascade
);

-- Resources

create table Language(
	id serial primary key,
  name varchar(50) unique,
	abreviation varchar(5) unique
);

create table Resource (
	id serial primary key,
  path varchar(1041) unique not null,
  name varchar(200) not null,
  createdAt timestamp not null default now(),
  duration integer
);

create table Song(
	idResource integer primary key,
  foreign key(idResource) references Resource(id) on delete cascade on update cascade
);

create table Video(
	idResource integer primary key,
  foreign key(idResource) references Resource(id) on delete cascade on update cascade
);

create table VideoSubtitle(
	idVideo integer,
  idLanguage integer,
  primary key(idVideo, idLanguage),
  foreign key(idVideo) references Video(idResource) on delete cascade on update cascade,
  foreign key(idLanguage) references Language(id) on delete cascade on update cascade
);

create table Film(
	idVideo integer primary key,
  foreign key (idVideo) references Video(idResource) on delete cascade on update cascade
);

create table Episode(
	idVideo integer primary key,
  idSeries integer,
  seasonNumber smallint,
  episodeNumber smallint,
  foreign key(idVideo) references Video(idResource) on delete cascade on update cascade,
  foreign key(idSeries) references Series(idVideoCollection) on delete cascade,
  unique(idSeries, seasonNumber, episodeNumber)
);

-- CollectionResources
create table VideoPlaylistVideo(
	idVideoPlaylist integer,
  idVideo integer,
  number smallint,
  primary key(idVideoPlaylist, idVideo),
  foreign key(idVideoPlaylist) references VideoPlaylist(idVideoCollection) on delete cascade on update cascade,
  foreign key(idVideo) references Video(idResource) on delete cascade on update cascade,
  unique(idVideoPlaylist, idVideo, number)
);

create table SongCollectionSong(
	idSongCollection integer,
  idSong integer,
  trackNumber smallint,
  primary key(idSongCollection, idSong),
	foreign key(idSongCollection) references SongCollection(idCollection) on delete cascade on update cascade,
  foreign key(idSong) references Song(idResource) on delete cascade on update cascade,
  unique(idSongCollection, idSong, trackNumber)
);

-- Artists
create table Artist(
	id serial primary key,
  name varchar(191)
);

create table Musician(
	idArtist integer primary key,
  idPerson integer,
  foreign key(idArtist) references Artist(id) on delete cascade on update cascade,
  foreign key(idPerson) references Person(id) on delete set null
);

create table Band(
	idArtist integer primary key,
  foreign key(idArtist) references Artist(id) on delete cascade on update cascade
);

create table BandMusician(
  id serial,
	idMusician integer,
  idBand integer,
	memberFrom date not null,
  memberTo date,
  primary key(idMusician, idBand, memberFrom),
  foreign key(idMusician) references Musician(idArtist) on delete cascade on update cascade,
  foreign key(idBand) references Band(idArtist) on delete cascade on update cascade
);

-- Song and Album Artists
create table SongArtist(
	idSong integer,
  idArtist integer,
  primary key(idSong, idArtist),
  foreign key(idSong) references Song(idResource) on delete cascade on update cascade,
  foreign key(idArtist) references Artist(id) on delete cascade on update cascade
);

create table AlbumArtist(
	idAlbum integer,
  idArtist integer,
	primary key(idAlbum, idArtist),
  foreign key(idAlbum) references Album(idSongCollection) on delete cascade on update cascade,
  foreign key(idArtist) references Artist(id) on delete cascade on update cascade
);

-- Activities
create table Activity(
	id bigserial primary key
);

create table CollectionActivity(
	idActivity bigint primary key,
  idCollection integer not null,
  foreign key(idActivity) references Activity(id) on delete cascade on update cascade,
  foreign key(idCollection) references Collection(id) on delete cascade on update cascade
);

create table ResourceActivity(
	idActivity bigint primary key,
  idResource integer not null,
  idCollectionActivity bigint,
  startedAt timestamp default null,
  pausedAt integer,
	foreign key(idActivity) references Activity(id) on delete cascade on update cascade,
  foreign key(idResource) references Resource(id) on delete cascade on update cascade,
  foreign key(idCollectionActivity) references CollectionActivity(idActivity) on delete cascade on update cascade
);

create table UserActivity(
	idUser integer,
  idActivity bigint,
	manages boolean not null default true,
  primary key(idUser, idActivity),
  foreign key(idUser) references StreamusUser(idPerson) on delete cascade on update cascade,
  foreign key(idActivity) references Activity(id) on delete cascade on update cascade
);

create table ActivityMessage(
  id serial primary key,
  idActivity bigint,
  idUser integer,
  content varchar(255) not null,
  postedAt timestamp not null default now(),
  foreign key (idActivity) references Activity(id) on delete cascade on update cascade,
  foreign key (idUser) references StreamusUser(idPerson) on delete cascade on update cascade
);