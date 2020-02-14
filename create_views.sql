drop view if exists vsong;
create view vsong as
select
	resource.*
from song
	inner join resource on song.idresource = resource.id;
  
drop view if exists vvideo;
create view vvideo as
select
	resource.*
from video
	inner join resource on video.idresource = resource.id;

drop view if exists vfilm;
create view vfilm as
select
	vvideo.*
from film
	inner join vvideo on film.idvideo = vvideo.id;

drop view if exists vepisode
create view vepisode as
select
	vvideo.*,
	episode.episodenumber,
	episode.idseries,
	collection.name
from episode
	inner join vvideo on episode.idvideo = vvideo.id
  inner join collection on episode.idseries = collection.id;

