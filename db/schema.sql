
-- нужно для проверки пересекающихся записей
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE users (
    id serial PRIMARY KEY,
    name text NOT NULL,
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    role text NOT NULL DEFAULT 'client'
        CHECK (role IN ('client', 'master', 'admin')),
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE login_sessions (
    jti uuid PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users,
    expires_at timestamptz NOT NULL
);

-- мастер использует тот же id, что и пользователь
CREATE TABLE masters (
    id integer PRIMARY KEY REFERENCES users,
    specialty text NOT NULL,
    bio text NOT NULL DEFAULT '',
    experience integer NOT NULL DEFAULT 0 CHECK (experience >= 0),
    photo text NOT NULL DEFAULT ''
);

CREATE TABLE services (
    id serial PRIMARY KEY,
    name text UNIQUE NOT NULL,
    category text NOT NULL,
    duration integer NOT NULL CHECK (duration BETWEEN 5 AND 720),
    price numeric(10,2) NOT NULL CHECK (price >= 0),
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE tariffs (
    master_id integer REFERENCES masters,
    service_id integer REFERENCES services,
    price numeric(10,2) CHECK (price >= 0),
    PRIMARY KEY (master_id, service_id)
);

CREATE TABLE shifts (
    master_id integer REFERENCES masters,
    weekday integer CHECK (weekday BETWEEN 0 AND 6),
    opens time NOT NULL,
    closes time NOT NULL CHECK (closes > opens),
    PRIMARY KEY (master_id, weekday)
);

CREATE TABLE visits (
    id serial PRIMARY KEY,
    client_id integer NOT NULL REFERENCES users,
    master_id integer NOT NULL REFERENCES masters,
    service_id integer NOT NULL REFERENCES services,
    starts timestamp NOT NULL,
    ends timestamp NOT NULL CHECK (ends > starts),
    price numeric(10,2) NOT NULL CHECK (price >= 0),
    status text NOT NULL DEFAULT 'booked'
        CHECK (status IN ('booked', 'completed', 'cancelled')),

    -- запрещаем пересекающиеся записи к одному мастеру
    CONSTRAINT no_overlap EXCLUDE USING gist
        (master_id WITH =, tsrange(starts, ends, '[)') WITH &&)
        WHERE (status <> 'cancelled')
);

CREATE INDEX visits_client_time ON visits(client_id, starts);

CREATE TABLE reviews (
    visit_id integer PRIMARY KEY REFERENCES visits,
    rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body text NOT NULL
);

CREATE TABLE works (
    id serial PRIMARY KEY,
    master_id integer NOT NULL REFERENCES masters,
    title text NOT NULL,
    image text NOT NULL
);

CREATE TABLE promotions (
    id serial PRIMARY KEY,
    title text NOT NULL,
    service_id integer NOT NULL REFERENCES services,
    master_id integer REFERENCES masters,
    discount integer NOT NULL CHECK (discount BETWEEN 1 AND 90),
    begins date NOT NULL,
    ends date NOT NULL CHECK (ends >= begins)
);

CREATE TABLE trends (
    id serial PRIMARY KEY,
    month date NOT NULL,
    title text NOT NULL,
    body text NOT NULL
);

CREATE TABLE brands (
    id serial PRIMARY KEY,
    name text UNIQUE NOT NULL,
    body text NOT NULL
);

CREATE TABLE articles (
    id serial PRIMARY KEY,
    brand_id integer NOT NULL REFERENCES brands,
    author_id integer NOT NULL REFERENCES users,
    kind text NOT NULL CHECK (kind IN ('Факт', 'Совет', 'История')),
    title text NOT NULL,
    body text NOT NULL
);

CREATE TABLE seed_versions (
    version text PRIMARY KEY
);
