-- Sample Users

with first_person as (
  insert into Person(firstname, lastname, dateOfBirth) values ('John', 'Doe', '1990-01-01') returning id
)
insert into StreamusUser(idPerson, email, username, password) values ((select id from first_person), 'john.doe@email.com', 'johndoe', 'password');

with second_person as (
  insert into Person(firstname, lastname, dateOfBirth) values ('Jane', 'Doe', '1990-01-01') returning id
)
insert into StreamusUser(idPerson, email, username, password) values ((select id from second_person), 'jane.doe@email.com', 'janedoe', 'password');

with third_person as (
  insert into Person(firstname, lastname, dateOfBirth) values ('Jack', 'Doe', '1990-01-01') returning id
)
insert into StreamusUser(idPerson, email, username, password) values ((select id from third_person), 'jack.doe@email.com', 'janedoe', 'password');

-- Sample songs
with first_resource as (
  insert into Resource(path, name, duration) values ('Speak', 'Speak to Me', 73) returning id
)
insert into Song(idResource) values((select id from first_resource));

with second_resource as (
  insert into Resource(path, name, duration) values ('Breathe', 'Breathe', 163) returning id
)
insert into Song(idResource) values((select id from second_resource));

with third_resource as (
  insert into Resource(path, name, duration) values ('On', 'On the Run', 216) returning id
)
insert into Song(idResource) values((select id from third_resource));

with fourth_resource as (
  insert into Resource(path, name, duration) values ('Time', 'Time', 413) returning id
)
insert into Song(idResource) values((select id from fourth_resource));

with fifth_resource as (
  insert into Resource(path, name, duration) values ('The', 'The Great Gig in the Sky', 276) returning id
)
insert into Song(idResource) values((select id from fifth_resource));

-- Album
with first_collection as ( 
  insert into Collection(name) values ('The Dark Side of the Moon') returning id
),

first_song_collection as (
  insert into SongCollection(idCollection) values ((select id from first_collection)) returning idCollection
)

insert into Album(idSongCollection) values ((select idCollection from first_song_collection));

select createalbum('The Dark Side of the Moon', '1973-03-01', 1);


select createepisode('dulcinea.mp4', 'Dulcinea', 2700, 2, 1::smallint, 1::smallint);
select createepisode('theBigEmpty.mp4', 'The Big Empty', 2700, 2, 1::smallint, 2::smallint);
select createepisode('rememberTheCant.mp4', 'Remember the Cant', 2700, 2, 1::smallint, 3::smallint);
select createepisode('CQB.mp4', 'CQB (Close Quarter Battle)', 2700, 2, 1::smallint, 4::smallint);
select createepisode('backToTheButcher.mp4', 'Back to the Butcher', 2700, 2, 1::smallint, 5::smallint);
select createepisode('rockBottom.mp4', 'Rock Bottom', 2700, 2, 1::smallint, 6::smallint);
select createepisode('windmills.mp4', 'Windmills', 2700, 2, 1::smallint, 7::smallint);
select createepisode('salvage.mp4', 'Salvage', 2700, 2, 1::smallint, 8::smallint);
select createepisode('criticalMass.mp4', 'Critical Mass', 2700, 2, 1::smallint, 9::smallint);
select createepisode('leviathanWakes.mp4', 'Leviathan Wakes', 2700, 2, 1::smallint, 10::smallint);


select createepisode('safe.mp4', 'Safe', 2700, 2, 2::smallint, 1::smallint);
select createepisode('doorsAndCorners.mp4', 'Doors & Corners', 2700, 2, 2::smallint, 2::smallint);
select createepisode('static.mp4', 'Static', 2700, 2, 2::smallint, 3::smallint);
select createepisode('godspeed.mp4', 'Godspeed', 2700, 2, 2::smallint, 4::smallint);
select createepisode('home.mp4', 'Home', 2700, 2, 2::smallint, 5::smallint);
select createepisode('paradigmShift.mp4', 'Paradigm Shift', 2700, 2, 2::smallint, 6::smallint);
select createepisode('theSeventhMan.mp4', 'The Seventh Man', 2700, 2, 2::smallint, 7::smallint);
select createepisode('pyre.mp4', 'Pyre', 2700, 2, 2::smallint, 8::smallint);
select createepisode('theWeepingSomnambulist.mp4', 'The Weeping Somnambulist', 2700, 2, 2::smallint, 9::smallint);
select createepisode('cascade.mp4', 'Cascade', 2700, 2, 2::smallint, 10::smallint);
select createepisode('hereThereBeDragons.mp4', 'Here There be Dragons', 2700, 2, 2::smallint, 11::smallint);
select createepisode('theMonsterAndTheRocket.mp4', 'The Monster and the Rocket', 2700, 2, 2::smallint, 12::smallint);
select createepisode('calibansWar.mp4', 'Caliban''s War', 2700, 2, 2::smallint, 13::smallint);

