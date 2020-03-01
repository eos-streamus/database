-- People
drop view if exists vuser cascade;
create view vuser as
select
  person.id,
  person.firstname,
  person.lastname,
  person.dateOfBirth,
  person.createdAt,
  person.updatedAt,
  streamususer.email,
  streamususer.username
from streamususer
  inner join person on streamususer.idperson = person.id;

drop view if exists vsong cascade;
create view vsong as
select
	resource.*
from song
	inner join resource on song.idresource = resource.id;
  
drop view if exists vvideo cascade;
create view vvideo as
select
	resource.*
from video
	inner join resource on video.idresource = resource.id;

drop view if exists vfilm cascade;
create view vfilm as
select
	vvideo.*
from film
	inner join vvideo on film.idvideo = vvideo.id;

drop view if exists vepisode cascade;
create view vepisode as
select
	vvideo.*,
	episode.episodenumber,
  episode.seasonnumber,
	episode.idseries
from episode
	inner join vvideo on episode.idvideo = vvideo.id
  inner join collection on episode.idseries = collection.id;

drop view if exists vvideoplaylist cascade;
create view vvideoplaylist as
select
	collection.id,
	collection.name,
	collection.createdAt,
  collection.updatedAt,
	videoplaylist.iduser,
  videoplaylistvideo.number,
	vvideo.id idvideo,
	vvideo.name videoname,
	vvideo.createdat videoCreatedAt,
	vvideo.path,
	vvideo.duration
from videoplaylist
	inner join videocollection on videoplaylist.idvideocollection = videocollection.idcollection
	inner join collection on videocollection.idcollection = collection.id
	left join videoplaylistvideo ON videoplaylist.idvideocollection = videoplaylistvideo.idvideoplaylist
	left join vvideo on videoplaylistvideo.idvideo = vvideo.id;

drop view if exists vsongcollection cascade;
create view vsongcollection as
select
	collection.id,
	collection.name,
	collection.createdat,
  collection.updatedAt,
	songcollectionsong.tracknumber,
	vsong.id idsong,
	vsong.name songname,
	vsong.createdat songcreatedat,
	vsong.duration,
	vsong.path
from songcollection
	inner join collection on songcollection.idcollection = collection.id
	left join songcollectionsong on songcollection.idcollection = songcollectionsong.idsongcollection
	left join vsong on songcollectionsong.idsong = vsong.id
order by
	collection.id,
	songcollectionsong.tracknumber;

drop view if exists valbum cascade;
create view valbum as
select
	vsongcollection.*,
	album.releasedate
from album
	inner join vsongcollection on album.idsongcollection = vsongcollection.id;

drop view if exists vsongplaylist cascade;
create view vsongplaylist as
select
	vsongcollection.*,
	songplaylist.iduser
from songplaylist
	inner join vsongcollection on songplaylist.idsongcollection = vsongcollection.id;

drop view if exists vseries cascade;
create view vseries as
select
	collection.id,
	collection.name,
	collection.createdAt,
  collection.updatedAt,
	vepisode.id idepisode,
	vepisode.seasonnumber,
	vepisode.episodenumber,
	vepisode.name episodename,
	vepisode.createdat episodecreatedat,
	vepisode.path,
	vepisode.duration
from series
	inner join videocollection on series.idvideocollection = videocollection.idcollection
	inner join collection on videocollection.idcollection = collection.id
	left join vepisode on series.idvideocollection = vepisode.idseries
order by
	collection.id,
	vepisode.seasonnumber,
	vepisode.episodenumber;
  
drop view if exists vcollectionresource cascade;
create view vcollectionresource as
  with
  number_of_episodes_by_series_season as (
    select distinct
      episode.idseries,
      episode.seasonnumber,
      count(distinct episode.idvideo) as nbepisodes
    from episode
    group by
      episode.idseries,
      episode.seasonnumber
    order by
      episode.idseries,
      episode.seasonnumber
  ),

  number_of_previous_episodes as (
    select
      episode.*,
      coalesce(sum(number_of_episodes_by_series_season.nbepisodes), 0) + episode.episodenumber - 1 previous_episodes
    from episode
      left join number_of_episodes_by_series_season on episode.idseries = number_of_episodes_by_series_season.idseries and
                                episode.seasonnumber > number_of_episodes_by_series_season.seasonnumber
    group by
      episode.episodenumber,
      episode.idseries,
      episode.idvideo,
      episode.seasonnumber,
      episode.episodenumber
  )
  
  select distinct
    collection.id idcollection,
    coalesce(videoplaylistvideo.number, songcollectionsong.tracknumber, number_of_previous_episodes.previous_episodes) + 1 as num,
    resource.id as idresource
  from collection
    left join songcollectionsong on songcollectionsong.idsongcollection = collection.id
    left join videoplaylistvideo ON collection.id = videoplaylistvideo.idvideoplaylist
    left join episode on collection.id = episode.idseries
    left join number_of_previous_episodes on episode.idvideo = number_of_previous_episodes.idvideo
    inner join resource on coalesce(songcollectionsong.idsong, videoplaylistvideo.idvideo, episode.idvideo) = resource.id;


drop view if exists vfullcollectionactivity;
create view vfullcollectionactivity as
  select
    collectionactivity.idactivity idcollectionactivity,
    collectionactivity.idcollection,
    collection.name,
    vcollectionresource.idresource,
    resource.name resourcename,
    vcollectionresource.num,
    resourceactivity.idactivity idresourceactivity,
    resourceactivity.startedat,
    resourceactivity.pausedat
  from collectionactivity
    inner join collection on collectionactivity.idcollection = collection.id
    inner join vcollectionresource on collectionactivity.idcollection = vcollectionresource.idcollection
    inner join resource on vcollectionresource.idresource = resource.id
    left join resourceactivity on collectionactivity.idactivity = resourceactivity.idcollectionactivity and
                                  vcollectionresource.idresource = resourceactivity.idresource
  order by
    idcollectionactivity,
    num;


drop view if exists vmusician;
create view vmusician as
  select
    Artist.id,
    Artist.name,
    Musician.idPerson
  from Musician
    inner join Artist on Musician.idArtist = Artist.id;

drop view if exists vband;
create view vband as
  select
    artist.id,
    artist.name,
    vmusician.id idmusician,
    vmusician.name musicianname,
    bandmusician.memberfrom,
    bandmusician.memberto
  from band
    inner join artist on band.idartist = artist.id
    left join bandmusician on band.idartist = bandmusician.idband
    left join vmusician on bandmusician.idmusician = vmusician.id;

drop view if exists vadmin;
create view vadmin as
  select
    vuser.*
  from admin
    inner join vuser on admin.iduser = vuser.id;