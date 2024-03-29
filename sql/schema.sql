CREATE SCHEMA IF not exists lbaw2391;

DROP TABLE IF exists users CASCADE;
DROP TABLE IF exists post CASCADE;
DROP TABLE IF exists groups CASCADE;
DROP TABLE IF exists group_owner CASCADE;
DROP TABLE IF exists group_request CASCADE;
DROP TABLE IF exists group_user CASCADE;
DROP TABLE IF exists friend_request CASCADE;
DROP TABLE IF exists comment CASCADE;
DROP TABLE IF exists reaction CASCADE;
DROP TABLE IF exists post_tag_not CASCADE;
DROP TABLE IF exists group_request_not CASCADE;
DROP TABLE IF exists friend_request_not CASCADE;
DROP TABLE IF exists post_tag CASCADE;
DROP TABLE IF exists comment_not CASCADE;
DROP TABLE IF exists reaction_not CASCADE;
DROP TABLE IF exists group_ban CASCADE;
DROP TABLE IF exists app_ban CASCADE;
DROP TABLE IF exists friends CASCADE;
DROP TABLE IF exists appeal CASCADE;

-----------------------------------------
-- Types
-----------------------------------------

DROP TYPE if exists reaction_types;
CREATE TYPE reaction_types AS ENUM ('LIKE', 'DISLIKE', 'HEART', 'STAR');

-----------------------------------------
-- Tables
-----------------------------------------

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL CONSTRAINT unique_username UNIQUE,
    email TEXT NOT NULL CONSTRAINT unique_email UNIQUE,
    password TEXT NOT NULL,
    image TEXT,
    academic_status TEXT,
    display_name TEXT,
    is_private BOOLEAN DEFAULT true NOT NULL,
    role INTEGER NOT NULL
);

CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL CONSTRAINT unique_group_name UNIQUE,
    is_private BOOLEAN DEFAULT true NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE post (
    id SERIAL PRIMARY KEY,
    author INTEGER REFERENCES users(id),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    attachment TEXT,
    group_id INTEGER REFERENCES groups(id),
    is_private BOOLEAN NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now())
);

CREATE TABLE friends (
    friend1 INTEGER REFERENCES users(id),
    friend2 INTEGER REFERENCES users(id),
    PRIMARY KEY (friend1, friend2)
);


CREATE TABLE group_owner(
    user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    group_id INTEGER REFERENCES groups(id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE group_request(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    group_id INTEGER REFERENCES groups(id) ON UPDATE CASCADE,
    is_accepted BOOLEAN DEFAULT false NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now())
);

CREATE TABLE group_user(
    user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    group_id INTEGER REFERENCES groups(id) ON UPDATE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE friend_request(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    friend_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    is_accepted BOOLEAN DEFAULT false,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now())
);

CREATE TABLE comment(
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES post(id) ON UPDATE CASCADE,
    author INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now()),
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now()),
    content TEXT NOT NULL
);

CREATE TABLE reaction (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES post(id) ON UPDATE CASCADE,
    comment_id INTEGER REFERENCES comment(id) ON UPDATE CASCADE,
    author INTEGER REFERENCES users(id),
    type reaction_types NOT NULL,
    CONSTRAINT valid_post_and_comment_ck CHECK((post_id IS NULL and comment_id IS NOT NULL) or (post_id IS NOT NULL and comment_id IS NULL))
);

CREATE TABLE post_tag_not(
    id SERIAL PRIMARY KEY, 
    post_id INTEGER REFERENCES post(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK (date <= now())
);

CREATE TABLE post_tag(
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES post(id) ON UPDATE CASCADE,
    user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE group_request_not(
    id SERIAL PRIMARY KEY, 
    group_request_id INTEGER REFERENCES group_request(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);

CREATE TABLE friend_request_not(
    id SERIAL PRIMARY KEY, 
    friend_request INTEGER REFERENCES friend_request(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);

CREATE TABLE comment_not(
    id SERIAL PRIMARY KEY, 
    comment_id INTEGER REFERENCES comment(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);

CREATE TABLE reaction_not(
    id SERIAL PRIMARY KEY, 
    reaction_id INTEGER REFERENCES reaction(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);

CREATE TABLE appeal(
    id SERIAL PRIMARY KEY,
    reason TEXT NOT NULL
);

CREATE TABLE group_ban(
    id SERIAL PRIMARY KEY,
    reason TEXT NOT NULL,
    group_owner_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    banned_user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    group_id INTEGER REFERENCES groups(id) ON UPDATE CASCADE,
    appeal INTEGER REFERENCES appeal(id) ON UPDATE CASCADE,
    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);

CREATE TABLE app_ban(
    id SERIAL PRIMARY KEY,
    reason TEXT NOT NULL,
    admin_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,
    banned_user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE,

    appeal INTEGER REFERENCES appeal(id) ON UPDATE CASCADE,

    date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL CHECK(date <= now())
);


CREATE INDEX user_index ON users USING hash(id);
CREATE INDEX post_comment ON comment USING btree(post_id);
CREATE INDEX author_post ON post USING btree(author);

-----------------------------------------
-- Full-text search
-----------------------------------------

-- Search users by username
ALTER TABLE users ADD COLUMN tsvectors TSVECTOR;

CREATE OR REPLACE FUNCTION update_users_search() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = setweight(to_tsvector('english', NEW.username), 'A') ||
            setweight(to_tsvector('english', NEW.display_name), 'B');
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF (NEW.username <> OLD.username OR NEW.display_name <> OLD.display_name) THEN
        NEW.tsvectors = setweight(to_tsvector('english', NEW.username), 'A') ||
            setweight(to_tsvector('english', NEW.display_name), 'B');
        END IF;
    END IF;
    RETURN NEW;
END $$
LANGUAGE plpgsql;

CREATE TRIGGER update_users_search
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE update_users_search();

CREATE INDEX user_search_idx ON users USING GIN (tsvectors);

-----------------------------------------

-- Search posts
ALTER TABLE post ADD COLUMN tsvectors TSVECTOR;

CREATE OR REPLACE FUNCTION update_post_search() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = setweight(to_tsvector('english', NEW.title), 'A') 
            || setweight(to_tsvector('english', NEW.content), 'B');
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF (OLD.title <> NEW.title OR NEW.content <> OLD.content) THEN
            NEW.tsvectors = setweight(to_tsvector('english', NEW.title), 'A') 
            || setweight(to_tsvector('english', NEW.content), 'B');
        END IF;
    END IF;
    RETURN NEW;
END$$
LANGUAGE plpgsql;

CREATE TRIGGER update_post_search
    BEFORE INSERT OR UPDATE ON post
    FOR EACH ROW
    EXECUTE PROCEDURE update_post_search();

CREATE INDEX post_search_idx ON post USING GIN(tsvectors);

-- Search groups
ALTER TABLE groups ADD COLUMN tsvectors TSVECTOR;

CREATE OR REPLACE FUNCTION update_groups_search() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = setweight(to_tsvector('english', NEW.name), 'A') ||
            setweight(to_tsvector('english', NEW.description), 'B');
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF (NEW.name <> OLD.name OR NEW.description <> OLD.description) THEN
            NEW.tsvectors = setweight(to_tsvector('english', NEW.name), 'A') ||
                setweight(to_tsvector('english', NEW.description), 'B');
        END IF;
    END IF;
    RETURN NEW;
END$$
LANGUAGE plpgsql;

CREATE TRIGGER update_groups_search
    BEFORE INSERT OR UPDATE ON groups
    FOR EACH ROW
    EXECUTE PROCEDURE update_groups_search();

CREATE INDEX groups_search_idx ON groups USING GIN(tsvectors);

-----------------------------------------
-- Triggers
-----------------------------------------

-- (TRIGGER01) If a user is deleted, it will change all his activity to anonymous
CREATE OR REPLACE FUNCTION update_deleted_user() RETURNS TRIGGER AS 
$BODY$
BEGIN
    DELETE FROM post_tag_not WHERE id = (
        SELECT post_tag.id 
        FROM post_tag_not JOIN post_tag ON post_tag_not.post_id = post_tag.id
        JOIN users ON users.id = post_tag.user_id
        WHERE users.id = OLD.id
    );
    DELETE FROM post_tag_not WHERE id = (
        SELECT post_tag.id 
        FROM post_tag_not JOIN post_tag ON post_tag_not.post_id = post_tag.id
        JOIN users ON users.id = post_tag.user_id
        WHERE users.id = OLD.id
    );
    DELETE FROM group_request_not WHERE id = (
        SELECT group_request.id 
        FROM group_request_not JOIN group_request ON group_request_not.group_request_id = group_request.id
        JOIN users ON users.id = group_request.user_id
        WHERE users.id = OLD.id
    );
    DELETE FROM friend_request_not WHERE id = (
        SELECT friend_request.id 
        FROM friend_request_not JOIN friend_request ON friend_request_not.friend_req_id = friend_request.id
        JOIN users ON users.id = friend_request.user_id OR users.id = friend_request.friend_id
        WHERE users.id = OLD.id
    );
    DELETE FROM comment_not WHERE comment = (
        SELECT comment.id 
        FROM comment_not JOIN comment ON comment_not.comment = comment.id
        JOIN users ON users.id = comment.author
        WHERE users.id = OLD.id
    );
    DELETE FROM reaction_not WHERE reaction_id = (
        SELECT reaction.id 
        FROM reaction_not JOIN reaction ON reaction_not.reaction_id = reaction.id
        JOIN users ON users.id = reaction.author_id
        WHERE users.id = OLD.id
    );
    UPDATE post SET author = 0 WHERE author = OLD.id;
    UPDATE comment SET author = 0 WHERE user_id = OLD.id;
    UPDATE reaction SET author = 0 WHERE user_id = OLD.id;
    DELETE FROM group_owner WHERE user_id = OLD.id;
    RETURN OLD;
END
$BODY$ 
LANGUAGE plpgsql;

CREATE TRIGGER update_deleted_user_trigger
    AFTER DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_deleted_user();

-----------------------------------------

-- (TRIGGER02) Insert a notification when a comment is made in owner post
CREATE OR REPLACE FUNCTION update_comment_not() RETURNS TRIGGER AS
$BODY$
BEGIN 
    INSERT INTO comment_not (comment_id, date) 
    VALUES (NEW.id, now());
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_comment_not_trigger
    AFTER INSERT ON comment
    FOR EACH ROW
    EXECUTE FUNCTION update_comment_not();

-----------------------------------------

-- (TRIGGER03) When a user is tagged, a tagged notification is created
CREATE OR REPLACE FUNCTION update_tag_not() RETURNS TRIGGER AS
$BODY$
BEGIN 
    INSERT INTO post_tag_not (post_tag_id, date) 
    VALUES (NEW.id, now());
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_tag_not_trigger
    AFTER INSERT ON post_tag
    FOR EACH ROW
    EXECUTE FUNCTION update_comment_not();

-----------------------------------------

-- (TRIGGER04) When a reaction is made, a reaction notification is created
CREATE OR REPLACE FUNCTION update_reaction_not() RETURNS TRIGGER AS
$BODY$
BEGIN 
    INSERT INTO reaction_not (reaction_id, date) 
    VALUES (NEW.id, now());
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_reaction_not_trigger
    AFTER INSERT ON reaction
    FOR EACH ROW
    EXECUTE FUNCTION update_reaction_not();


-----------------------------------------

-- (TRIGGER05) When a user receives a group request, a notification is created
CREATE OR REPLACE FUNCTION update_group_request_not() RETURNS TRIGGER AS
$BODY$
BEGIN 
    INSERT INTO group_request_not (group_request_id, date) 
    VALUES (NEW.id, now());
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_group_request_not_trigger
    AFTER INSERT ON group_request
    FOR EACH ROW
    EXECUTE FUNCTION update_group_request_not();

-----------------------------------------

-- (TRIGGER06) When a friend request is added, a notification will be inserted
CREATE OR REPLACE FUNCTION update_friend_request_not() RETURNS TRIGGER AS
$BODY$
BEGIN 
    INSERT INTO friend_request_not (friend_request, date) 
    VALUES (NEW.id, now());
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_friend_request_not_trigger
    AFTER INSERT ON friend_request
    FOR EACH ROW
    EXECUTE FUNCTION update_friend_request_not();

-----------------------------------------

-- (TRIGGER07)  A user can only add posts to groups which he belongs
CREATE OR REPLACE FUNCTION check_belongs_group() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF (NOT EXISTS (SELECT * FROM group_user where group_user.user_id = NEW.author and group_user.group_id = NEW.group_id)
        AND (NEW.group_id <> null)) THEN
        RAISE EXCEPTION 'The user must belong to the group to add a post';
	END IF;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER check_belongs_group_trigger
    BEFORE INSERT ON post
    FOR EACH ROW
    EXECUTE FUNCTION check_belongs_group();

-----------------------------------------

-- (TRIGGER08) A user cannot be friend with himself
CREATE OR REPLACE FUNCTION check_friend_himself() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF (NEW.user_id = NEW.friend_id) THEN
        RAISE EXCEPTION 'A user cannot send friend request to himself.';
	END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER check_friend_of_himself
    BEFORE INSERT ON friend_request
    EXECUTE FUNCTION check_friend_himself();


-----------------------------------------

-- (TRIGGER09)  A friend request must only be sent to non-friends
CREATE OR REPLACE FUNCTION check_friendship_exists() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS (SELECT * FROM friends where (friend1 = NEW.user_id and friend2 = NEW.friend_id) or 
                                           (friend2 = NEW.user_id and friend1 = NEW.friend_id)) THEN
        RAISE EXCEPTION 'The users are already friends';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER check_friendship_exists
    BEFORE INSERT ON friend_request
    EXECUTE FUNCTION check_friendship_exists();

-----------------------------------------

-- (TRIGGER10) A group request must only be sent to non-members of group
CREATE OR REPLACE FUNCTION check_group_request() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF EXISTS (SELECT * FROM group_user where user_id = NEW.user_id and group_id = NEW.group_id) THEN
        RAISE EXCEPTION 'The user is already a member of the group';
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER check_group_request
    BEFORE INSERT ON group_request
    EXECUTE FUNCTION check_group_request();

-----------------------------------------
    
-- (TRIGGER11) When a group request is accepted, the user is added to the groupr
CREATE OR REPLACE FUNCTION add_user_to_group() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF NEW.is_accepted = true THEN
        INSERT INTO group_user (user_id, group_id) VALUES (NEW.user_id, NEW.group_id);
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_user_to_group
    AFTER INSERT OR UPDATE ON group_request
    FOR EACH ROW
    WHEN (NEW.is_accepted = true)
    EXECUTE FUNCTION add_user_to_group();

----------------------------------------
    
-- (TRIGGER12) When a friend request is accepted, the users are now friends

CREATE OR REPLACE FUNCTION add_friend() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF NEW.is_accepted = true THEN
        INSERT INTO friends (friend1, friend2) VALUES (NEW.user_id, NEW.friend_id);
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_friend
    AFTER INSERT OR UPDATE ON friend_request
    FOR EACH ROW
    WHEN (NEW.is_accepted = true)
    EXECUTE FUNCTION add_friend();
