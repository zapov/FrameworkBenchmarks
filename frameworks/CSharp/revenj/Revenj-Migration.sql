/*MIGRATION_DESCRIPTION
--CREATE: FrameworkBench-Message
New object Message will be created in schema FrameworkBench
--CREATE: FrameworkBench-Message-message
New property message will be created for Message in FrameworkBench
--CREATE: FrameworkBench-World
New object World will be created in schema FrameworkBench
--CREATE: FrameworkBench-World-id
New property id will be created for World in FrameworkBench
--CREATE: FrameworkBench-World-randomNumber
New property randomNumber will be created for World in FrameworkBench
--CREATE: FrameworkBench-Fortune
New object Fortune will be created in schema FrameworkBench
--CREATE: FrameworkBench-Fortune-id
New property id will be created for Fortune in FrameworkBench
--CREATE: FrameworkBench-Fortune-message
New property message will be created for Fortune in FrameworkBench
--CREATE: FrameworkBench-Id10
New object Id10 will be created in schema FrameworkBench
--CREATE: FrameworkBench-Id10-id1
New property id1 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id2
New property id2 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id3
New property id3 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id4
New property id4 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id5
New property id5 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id6
New property id6 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id7
New property id7 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id8
New property id8 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id9
New property id9 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id10-id10
New property id10 will be created for Id10 in FrameworkBench
--CREATE: FrameworkBench-Id15
New object Id15 will be created in schema FrameworkBench
--CREATE: FrameworkBench-Id15-id1
New property id1 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id2
New property id2 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id3
New property id3 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id4
New property id4 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id5
New property id5 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id6
New property id6 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id7
New property id7 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id8
New property id8 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id9
New property id9 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id10
New property id10 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id11
New property id11 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id12
New property id12 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id13
New property id13 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id14
New property id14 will be created for Id15 in FrameworkBench
--CREATE: FrameworkBench-Id15-id15
New property id15 will be created for Id15 in FrameworkBench
MIGRATION_DESCRIPTION*/

DO $$ BEGIN
	IF EXISTS(SELECT * FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = '-NGS-' AND c.relname = 'database_setting') THEN	
		IF EXISTS(SELECT * FROM "-NGS-".Database_Setting WHERE Key ILIKE 'mode' AND NOT Value ILIKE 'unsafe') THEN
			RAISE EXCEPTION 'Database upgrade is forbidden. Change database mode to allow upgrade';
		END IF;
	END IF;
END $$ LANGUAGE plpgsql;

DO $$
DECLARE script VARCHAR;
BEGIN
	IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = '-NGS-') THEN
		CREATE SCHEMA "-NGS-";
		COMMENT ON SCHEMA "-NGS-" IS 'NGS generated';
	END IF;
	IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = 'public') THEN
		CREATE SCHEMA public;
		COMMENT ON SCHEMA public IS 'NGS generated';
	END IF;
	SELECT array_to_string(array_agg('DROP VIEW IF EXISTS ' || quote_ident(n.nspname) || '.' || quote_ident(cl.relname) || ' CASCADE;'), '')
	INTO script
	FROM pg_class cl
	INNER JOIN pg_namespace n ON cl.relnamespace = n.oid
	INNER JOIN pg_description d ON d.objoid = cl.oid
	WHERE cl.relkind = 'v' AND d.description LIKE 'NGS volatile%';
	IF length(script) > 0 THEN
		EXECUTE script;
	END IF;
END $$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS "-NGS-".Database_Migration
(
	Ordinal SERIAL PRIMARY KEY,
	Dsls TEXT,
	Implementations BYTEA,
	Version VARCHAR,
	Applied_At TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP)
);

CREATE OR REPLACE FUNCTION "-NGS-".Load_Last_Migration()
RETURNS "-NGS-".Database_Migration AS
$$
SELECT m FROM "-NGS-".Database_Migration m
ORDER BY Ordinal DESC 
LIMIT 1
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Persist_Concepts(dsls TEXT, implementations BYTEA, version VARCHAR)
  RETURNS void AS
$$
BEGIN
	INSERT INTO "-NGS-".Database_Migration(Dsls, Implementations, Version) VALUES(dsls, implementations, version);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "-NGS-".Generate_Uri2(text, text) RETURNS text AS 
$$
BEGIN
	RETURN replace(replace($1, '\','\\'), '/', '\/')||'/'||replace(replace($2, '\','\\'), '/', '\/');
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Generate_Uri3(text, text, text) RETURNS text AS 
$$
BEGIN
	RETURN replace(replace($1, '\','\\'), '/', '\/')||'/'||replace(replace($2, '\','\\'), '/', '\/')||'/'||replace(replace($3, '\','\\'), '/', '\/');
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Generate_Uri4(text, text, text, text) RETURNS text AS 
$$
BEGIN
	RETURN replace(replace($1, '\','\\'), '/', '\/')||'/'||replace(replace($2, '\','\\'), '/', '\/')||'/'||replace(replace($3, '\','\\'), '/', '\/')||'/'||replace(replace($4, '\','\\'), '/', '\/');
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Generate_Uri5(text, text, text, text, text) RETURNS text AS 
$$
BEGIN
	RETURN replace(replace($1, '\','\\'), '/', '\/')||'/'||replace(replace($2, '\','\\'), '/', '\/')||'/'||replace(replace($3, '\','\\'), '/', '\/')||'/'||replace(replace($4, '\','\\'), '/', '\/')||'/'||replace(replace($5, '\','\\'), '/', '\/');
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Generate_Uri(text[]) RETURNS text AS 
$$
BEGIN
	RETURN (SELECT array_to_string(array_agg(replace(replace(u, '\','\\'), '/', '\/')), '/') FROM unnest($1) u);
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Safe_Notify(target varchar, name varchar, operation varchar, uris varchar[]) RETURNS VOID AS
$$
DECLARE message VARCHAR;
DECLARE array_size INT;
BEGIN
	array_size = array_upper(uris, 1);
	message = name || ':' || operation || ':' || uris::TEXT;
	IF (array_size > 0 and length(message) < 8000) THEN 
		PERFORM pg_notify(target, message);
	ELSEIF (array_size > 1) THEN
		PERFORM "-NGS-".Safe_Notify(target, name, operation, (SELECT array_agg(uris[i]) FROM generate_series(1, (array_size+1)/2) i));
		PERFORM "-NGS-".Safe_Notify(target, name, operation, (SELECT array_agg(uris[i]) FROM generate_series(array_size/2+1, array_size) i));
	ELSEIF (array_size = 1) THEN
		RAISE EXCEPTION 'uri can''t be longer than 8000 characters';
	END IF;	
END
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "-NGS-".cast_int(int[]) RETURNS TEXT AS
$$ SELECT $1::TEXT[]::TEXT $$ LANGUAGE SQL IMMUTABLE COST 1;
CREATE OR REPLACE FUNCTION "-NGS-".cast_bigint(bigint[]) RETURNS TEXT AS
$$ SELECT $1::TEXT[]::TEXT $$ LANGUAGE SQL IMMUTABLE COST 1;

DO $$ BEGIN
	IF NOT EXISTS (SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid WHERE s.typname = '_int4' AND t.typname = 'text') THEN
		CREATE CAST (int[] AS text) WITH FUNCTION "-NGS-".cast_int(int[]) AS ASSIGNMENT;
	END IF;
END $$ LANGUAGE plpgsql;
DO $$ BEGIN
	IF NOT EXISTS (SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid WHERE s.typname = '_int8' AND t.typname = 'text') THEN
		CREATE CAST (bigint[] AS text) WITH FUNCTION "-NGS-".cast_bigint(bigint[]) AS ASSIGNMENT;
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "-NGS-".Split_Uri(s text) RETURNS TEXT[] AS
$$
DECLARE i int;
DECLARE pos int;
DECLARE len int;
DECLARE res TEXT[];
DECLARE cur TEXT;
DECLARE c CHAR(1);
BEGIN
	pos = 0;
	i = 1;
	cur = '';
	len = length(s);
	LOOP
		pos = pos + 1;
		EXIT WHEN pos > len;
		c = substr(s, pos, 1);
		IF c = '/' THEN
			res[i] = cur;
			i = i + 1;
			cur = '';
		ELSE
			IF c = '\' THEN
				pos = pos + 1;
				c = substr(s, pos, 1);
			END IF;		
			cur = cur || c;
		END IF;
	END LOOP;
	res[i] = cur;
	return res;
END
$$ LANGUAGE plpgsql SECURITY DEFINER IMMUTABLE;

CREATE OR REPLACE FUNCTION "-NGS-".Load_Type_Info(
	OUT type_schema character varying, 
	OUT type_name character varying, 
	OUT column_name character varying, 
	OUT column_schema character varying,
	OUT column_type character varying, 
	OUT column_index smallint, 
	OUT is_not_null boolean,
	OUT is_ngs_generated boolean)
  RETURNS SETOF record AS
$BODY$
SELECT 
	ns.nspname::varchar, 
	cl.relname::varchar, 
	atr.attname::varchar, 
	ns_ref.nspname::varchar,
	typ.typname::varchar, 
	(SELECT COUNT(*) + 1
	FROM pg_attribute atr_ord
	WHERE 
		atr.attrelid = atr_ord.attrelid
		AND atr_ord.attisdropped = false
		AND atr_ord.attnum > 0
		AND atr_ord.attnum < atr.attnum)::smallint, 
	atr.attnotnull,
	coalesce(d.description LIKE 'NGS generated%', false)
FROM 
	pg_attribute atr
	INNER JOIN pg_class cl ON atr.attrelid = cl.oid
	INNER JOIN pg_namespace ns ON cl.relnamespace = ns.oid
	INNER JOIN pg_type typ ON atr.atttypid = typ.oid
	INNER JOIN pg_namespace ns_ref ON typ.typnamespace = ns_ref.oid
	LEFT JOIN pg_description d ON d.objoid = cl.oid
								AND d.objsubid = atr.attnum
WHERE
	(cl.relkind = 'r' OR cl.relkind = 'v' OR cl.relkind = 'c')
	AND ns.nspname NOT LIKE 'pg_%'
	AND ns.nspname != 'information_schema'
	AND atr.attnum > 0
	AND atr.attisdropped = FALSE
ORDER BY 1, 2, 6
$BODY$
  LANGUAGE SQL STABLE;

CREATE TABLE IF NOT EXISTS "-NGS-".Database_Setting
(
	Key VARCHAR PRIMARY KEY,
	Value TEXT NOT NULL
);

CREATE OR REPLACE FUNCTION "-NGS-".Create_Type_Cast(function VARCHAR, schema VARCHAR, from_name VARCHAR, to_name VARCHAR)
RETURNS void
AS
$$
DECLARE header VARCHAR;
DECLARE source VARCHAR;
DECLARE footer VARCHAR;
DECLARE col_name VARCHAR;
DECLARE type VARCHAR = '"' || schema || '"."' || to_name || '"';
BEGIN
	header = 'CREATE OR REPLACE FUNCTION ' || function || '
RETURNS ' || type || '
AS
$BODY$
SELECT ROW(';
	footer = ')::' || type || '
$BODY$ IMMUTABLE LANGUAGE sql;';
	source = '';
	FOR col_name IN 
		SELECT 
			CASE WHEN 
				EXISTS (SELECT * FROM "-NGS-".Load_Type_Info() f 
					WHERE f.type_schema = schema AND f.type_name = from_name AND f.column_name = t.column_name)
				OR EXISTS(SELECT * FROM pg_proc p JOIN pg_type t_in ON p.proargtypes[0] = t_in.oid 
					JOIN pg_namespace n_in ON t_in.typnamespace = n_in.oid JOIN pg_namespace n ON p.pronamespace = n.oid
					WHERE array_upper(p.proargtypes, 1) = 0 AND n.nspname = 'public' AND t_in.typname = from_name AND p.proname = t.column_name) THEN t.column_name
				ELSE null
			END
		FROM "-NGS-".Load_Type_Info() t
		WHERE 
			t.type_schema = schema 
			AND t.type_name = to_name
		ORDER BY t.column_index 
	LOOP
		IF col_name IS NULL THEN
			source = source || 'null, ';
		ELSE
			source = source || '$1."' || col_name || '", ';
		END IF;
	END LOOP;
	IF (LENGTH(source) > 0) THEN 
		source = SUBSTRING(source, 1, LENGTH(source) - 2);
	END IF;
	EXECUTE (header || source || footer);
END
$$ LANGUAGE plpgsql;;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_namespace WHERE nspname = 'FrameworkBench') THEN
		CREATE SCHEMA "FrameworkBench";
		COMMENT ON SCHEMA "FrameworkBench" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = '-ngs_Message_type-') THEN	
		CREATE TYPE "FrameworkBench"."-ngs_Message_type-" AS ();
		COMMENT ON TYPE "FrameworkBench"."-ngs_Message_type-" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = 'Message') THEN	
		CREATE TYPE "FrameworkBench"."Message" AS ();
		COMMENT ON TYPE "FrameworkBench"."Message" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = '-ngs_World_type-') THEN	
		CREATE TYPE "FrameworkBench"."-ngs_World_type-" AS ();
		COMMENT ON TYPE "FrameworkBench"."-ngs_World_type-" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'FrameworkBench' AND c.relname = 'World') THEN	
		CREATE TABLE "FrameworkBench"."World" ();
		COMMENT ON TABLE "FrameworkBench"."World" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'FrameworkBench' AND c.relname = 'World_sequence') THEN
		CREATE SEQUENCE "FrameworkBench"."World_sequence";
		COMMENT ON SEQUENCE "FrameworkBench"."World_sequence" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = '-ngs_Fortune_type-') THEN	
		CREATE TYPE "FrameworkBench"."-ngs_Fortune_type-" AS ();
		COMMENT ON TYPE "FrameworkBench"."-ngs_Fortune_type-" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'FrameworkBench' AND c.relname = 'Fortune') THEN	
		CREATE TABLE "FrameworkBench"."Fortune" ();
		COMMENT ON TABLE "FrameworkBench"."Fortune" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'FrameworkBench' AND c.relname = 'Fortune_sequence') THEN
		CREATE SEQUENCE "FrameworkBench"."Fortune_sequence";
		COMMENT ON SEQUENCE "FrameworkBench"."Fortune_sequence" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = '-ngs_Id10_type-') THEN	
		CREATE TYPE "FrameworkBench"."-ngs_Id10_type-" AS ();
		COMMENT ON TYPE "FrameworkBench"."-ngs_Id10_type-" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = 'Id10') THEN	
		CREATE TYPE "FrameworkBench"."Id10" AS ();
		COMMENT ON TYPE "FrameworkBench"."Id10" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = '-ngs_Id15_type-') THEN	
		CREATE TYPE "FrameworkBench"."-ngs_Id15_type-" AS ();
		COMMENT ON TYPE "FrameworkBench"."-ngs_Id15_type-" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'FrameworkBench' AND t.typname = 'Id15') THEN	
		CREATE TYPE "FrameworkBench"."Id15" AS ();
		COMMENT ON TYPE "FrameworkBench"."Id15" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Message_to_type"("FrameworkBench"."Message") RETURNS "FrameworkBench"."-ngs_Message_type-" AS $$ SELECT $1::text::"FrameworkBench"."-ngs_Message_type-" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Message_to_type"("FrameworkBench"."-ngs_Message_type-") RETURNS "FrameworkBench"."Message" AS $$ SELECT $1::text::"FrameworkBench"."Message" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION cast_to_text("FrameworkBench"."Message") RETURNS text AS $$ SELECT $1::VARCHAR $$ IMMUTABLE LANGUAGE sql COST 1;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid JOIN pg_namespace n ON n.oid = s.typnamespace AND n.oid = t.typnamespace
					WHERE n.nspname = 'FrameworkBench' AND s.typname = 'Message' AND t.typname = '-ngs_Message_type-') THEN
		CREATE CAST ("FrameworkBench"."-ngs_Message_type-" AS "FrameworkBench"."Message") WITH FUNCTION "FrameworkBench"."cast_Message_to_type"("FrameworkBench"."-ngs_Message_type-") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Message" AS "FrameworkBench"."-ngs_Message_type-") WITH FUNCTION "FrameworkBench"."cast_Message_to_type"("FrameworkBench"."Message") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Message" AS text) WITH FUNCTION cast_to_text("FrameworkBench"."Message") AS ASSIGNMENT;
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Message_type-' AND column_name = 'message') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Message_type-" ADD ATTRIBUTE "message" VARCHAR;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Message_type-"."message" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Message' AND column_name = 'message') THEN
		ALTER TYPE "FrameworkBench"."Message" ADD ATTRIBUTE "message" VARCHAR;
		COMMENT ON COLUMN "FrameworkBench"."Message"."message" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_World_type-' AND column_name = 'id') THEN
		ALTER TYPE "FrameworkBench"."-ngs_World_type-" ADD ATTRIBUTE "id" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_World_type-"."id" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'World' AND column_name = 'id') THEN
		ALTER TABLE "FrameworkBench"."World" ADD COLUMN "id" INT;
		COMMENT ON COLUMN "FrameworkBench"."World"."id" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_World_type-' AND column_name = 'randomNumber') THEN
		ALTER TYPE "FrameworkBench"."-ngs_World_type-" ADD ATTRIBUTE "randomNumber" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_World_type-"."randomNumber" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'World' AND column_name = 'randomNumber') THEN
		ALTER TABLE "FrameworkBench"."World" ADD COLUMN "randomNumber" INT;
		COMMENT ON COLUMN "FrameworkBench"."World"."randomNumber" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Fortune_type-' AND column_name = 'id') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Fortune_type-" ADD ATTRIBUTE "id" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Fortune_type-"."id" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Fortune' AND column_name = 'id') THEN
		ALTER TABLE "FrameworkBench"."Fortune" ADD COLUMN "id" INT;
		COMMENT ON COLUMN "FrameworkBench"."Fortune"."id" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Fortune_type-' AND column_name = 'message') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Fortune_type-" ADD ATTRIBUTE "message" VARCHAR;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Fortune_type-"."message" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Fortune' AND column_name = 'message') THEN
		ALTER TABLE "FrameworkBench"."Fortune" ADD COLUMN "message" VARCHAR;
		COMMENT ON COLUMN "FrameworkBench"."Fortune"."message" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."Id10") RETURNS "FrameworkBench"."-ngs_Id10_type-" AS $$ SELECT $1::text::"FrameworkBench"."-ngs_Id10_type-" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."-ngs_Id10_type-") RETURNS "FrameworkBench"."Id10" AS $$ SELECT $1::text::"FrameworkBench"."Id10" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION cast_to_text("FrameworkBench"."Id10") RETURNS text AS $$ SELECT $1::VARCHAR $$ IMMUTABLE LANGUAGE sql COST 1;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid JOIN pg_namespace n ON n.oid = s.typnamespace AND n.oid = t.typnamespace
					WHERE n.nspname = 'FrameworkBench' AND s.typname = 'Id10' AND t.typname = '-ngs_Id10_type-') THEN
		CREATE CAST ("FrameworkBench"."-ngs_Id10_type-" AS "FrameworkBench"."Id10") WITH FUNCTION "FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."-ngs_Id10_type-") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Id10" AS "FrameworkBench"."-ngs_Id10_type-") WITH FUNCTION "FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."Id10") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Id10" AS text) WITH FUNCTION cast_to_text("FrameworkBench"."Id10") AS ASSIGNMENT;
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id1') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id1" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id1" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id1') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id1" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id1" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id2') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id2" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id2" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id2') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id2" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id2" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id3') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id3" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id3" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id3') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id3" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id3" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id4') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id4" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id4" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id4') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id4" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id4" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id5') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id5" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id5" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id5') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id5" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id5" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id6') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id6" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id6" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id6') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id6" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id6" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id7') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id7" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id7" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id7') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id7" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id7" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id8') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id8" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id8" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id8') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id8" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id8" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id9') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id9" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id9" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id9') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id9" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id9" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id10_type-' AND column_name = 'id10') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id10_type-" ADD ATTRIBUTE "id10" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id10_type-"."id10" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id10' AND column_name = 'id10') THEN
		ALTER TYPE "FrameworkBench"."Id10" ADD ATTRIBUTE "id10" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id10"."id10" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."Id15") RETURNS "FrameworkBench"."-ngs_Id15_type-" AS $$ SELECT $1::text::"FrameworkBench"."-ngs_Id15_type-" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."-ngs_Id15_type-") RETURNS "FrameworkBench"."Id15" AS $$ SELECT $1::text::"FrameworkBench"."Id15" $$ IMMUTABLE LANGUAGE sql COST 1;
CREATE OR REPLACE FUNCTION cast_to_text("FrameworkBench"."Id15") RETURNS text AS $$ SELECT $1::VARCHAR $$ IMMUTABLE LANGUAGE sql COST 1;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid JOIN pg_namespace n ON n.oid = s.typnamespace AND n.oid = t.typnamespace
					WHERE n.nspname = 'FrameworkBench' AND s.typname = 'Id15' AND t.typname = '-ngs_Id15_type-') THEN
		CREATE CAST ("FrameworkBench"."-ngs_Id15_type-" AS "FrameworkBench"."Id15") WITH FUNCTION "FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."-ngs_Id15_type-") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Id15" AS "FrameworkBench"."-ngs_Id15_type-") WITH FUNCTION "FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."Id15") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Id15" AS text) WITH FUNCTION cast_to_text("FrameworkBench"."Id15") AS ASSIGNMENT;
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id1') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id1" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id1" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id1') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id1" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id1" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id2') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id2" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id2" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id2') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id2" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id2" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id3') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id3" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id3" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id3') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id3" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id3" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id4') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id4" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id4" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id4') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id4" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id4" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id5') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id5" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id5" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id5') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id5" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id5" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id6') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id6" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id6" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id6') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id6" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id6" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id7') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id7" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id7" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id7') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id7" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id7" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id8') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id8" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id8" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id8') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id8" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id8" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id9') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id9" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id9" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id9') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id9" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id9" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id10') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id10" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id10" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id10') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id10" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id10" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id11') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id11" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id11" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id11') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id11" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id11" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id12') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id12" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id12" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id12') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id12" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id12" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id13') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id13" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id13" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id13') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id13" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id13" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id14') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id14" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id14" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id14') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id14" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id14" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '-ngs_Id15_type-' AND column_name = 'id15') THEN
		ALTER TYPE "FrameworkBench"."-ngs_Id15_type-" ADD ATTRIBUTE "id15" INT;
		COMMENT ON COLUMN "FrameworkBench"."-ngs_Id15_type-"."id15" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = 'Id15' AND column_name = 'id15') THEN
		ALTER TYPE "FrameworkBench"."Id15" ADD ATTRIBUTE "id15" INT;
		COMMENT ON COLUMN "FrameworkBench"."Id15"."id15" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW "FrameworkBench"."World_entity" AS
SELECT _entity."id", _entity."randomNumber"
FROM
	"FrameworkBench"."World" _entity
	;
COMMENT ON VIEW "FrameworkBench"."World_entity" IS 'NGS volatile';

CREATE OR REPLACE FUNCTION "URI"("FrameworkBench"."World_entity") RETURNS TEXT AS $$
SELECT CAST($1."id" as TEXT)
$$ LANGUAGE SQL IMMUTABLE SECURITY DEFINER;

CREATE OR REPLACE VIEW "FrameworkBench"."Fortune_entity" AS
SELECT _entity."id", _entity."message"
FROM
	"FrameworkBench"."Fortune" _entity
	;
COMMENT ON VIEW "FrameworkBench"."Fortune_entity" IS 'NGS volatile';

CREATE OR REPLACE FUNCTION "URI"("FrameworkBench"."Fortune_entity") RETURNS TEXT AS $$
SELECT CAST($1."id" as TEXT)
$$ LANGUAGE SQL IMMUTABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_World_to_type"("FrameworkBench"."-ngs_World_type-") RETURNS "FrameworkBench"."World_entity" AS $$ SELECT $1::text::"FrameworkBench"."World_entity" $$ IMMUTABLE LANGUAGE sql;
CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_World_to_type"("FrameworkBench"."World_entity") RETURNS "FrameworkBench"."-ngs_World_type-" AS $$ SELECT $1::text::"FrameworkBench"."-ngs_World_type-" $$ IMMUTABLE LANGUAGE sql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid JOIN pg_namespace n ON n.oid = s.typnamespace AND n.oid = t.typnamespace
					WHERE n.nspname = 'FrameworkBench' AND s.typname = 'World_entity' AND t.typname = '-ngs_World_type-') THEN
		CREATE CAST ("FrameworkBench"."-ngs_World_type-" AS "FrameworkBench"."World_entity") WITH FUNCTION "FrameworkBench"."cast_World_to_type"("FrameworkBench"."-ngs_World_type-") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."World_entity" AS "FrameworkBench"."-ngs_World_type-") WITH FUNCTION "FrameworkBench"."cast_World_to_type"("FrameworkBench"."World_entity") AS IMPLICIT;
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."insert_World"(IN _inserted "FrameworkBench"."World_entity"[]) RETURNS VOID AS
$$
BEGIN
	INSERT INTO "FrameworkBench"."World" ("id", "randomNumber") VALUES(_inserted[1]."id", _inserted[1]."randomNumber");
	
END
$$
LANGUAGE plpgsql SECURITY DEFINER;;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '>update-World-pair<' AND column_name = 'original') THEN
		DROP TYPE IF EXISTS "FrameworkBench".">update-World-pair<";
		CREATE TYPE "FrameworkBench".">update-World-pair<" AS (original "FrameworkBench"."World_entity", changed "FrameworkBench"."World_entity");
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."persist_World"(
IN _inserted "FrameworkBench"."World_entity"[], IN _updated "FrameworkBench".">update-World-pair<"[], IN _deleted "FrameworkBench"."World_entity"[]) 
	RETURNS VARCHAR AS
$$
DECLARE cnt int;
DECLARE uri VARCHAR;
DECLARE tmp record;
DECLARE _update_count int = array_upper(_updated, 1);
DECLARE _delete_count int = array_upper(_deleted, 1);

BEGIN

	SET CONSTRAINTS ALL DEFERRED;

	

	INSERT INTO "FrameworkBench"."World" ("id", "randomNumber")
	SELECT _i."id", _i."randomNumber" 
	FROM unnest(_inserted) _i;

	

	UPDATE "FrameworkBench"."World" as _tbl SET "id" = (_u.changed)."id", "randomNumber" = (_u.changed)."randomNumber"
	FROM unnest(_updated) _u
	WHERE _tbl."id" = (_u.original)."id";

	GET DIAGNOSTICS cnt = ROW_COUNT;
	IF cnt != _update_count THEN 
		RETURN 'Updated ' || cnt || ' row(s). Expected to update ' || _update_count || ' row(s).';
	END IF;

	

	DELETE FROM "FrameworkBench"."World"
	WHERE ("id") IN (SELECT _d."id" FROM unnest(_deleted) _d);

	GET DIAGNOSTICS cnt = ROW_COUNT;
	IF cnt != _delete_count THEN 
		RETURN 'Deleted ' || cnt || ' row(s). Expected to delete ' || _delete_count || ' row(s).';
	END IF;

	

	SET CONSTRAINTS ALL IMMEDIATE;

	RETURN NULL;
END
$$
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "FrameworkBench"."update_World"(IN _original "FrameworkBench"."World_entity"[], IN _updated "FrameworkBench"."World_entity"[]) RETURNS VARCHAR AS
$$
BEGIN
	
	UPDATE "FrameworkBench"."World" AS _tab SET "id" = _updated[1]."id", "randomNumber" = _updated[1]."randomNumber" WHERE _tab."id" = _original[1]."id";
	
	RETURN NULL;
END
$$
LANGUAGE plpgsql SECURITY DEFINER;;

CREATE OR REPLACE VIEW "FrameworkBench"."World_unprocessed_events" AS
SELECT _aggregate."id"
FROM
	"FrameworkBench"."World_entity" _aggregate
;
COMMENT ON VIEW "FrameworkBench"."World_unprocessed_events" IS 'NGS volatile';

CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."-ngs_Fortune_type-") RETURNS "FrameworkBench"."Fortune_entity" AS $$ SELECT $1::text::"FrameworkBench"."Fortune_entity" $$ IMMUTABLE LANGUAGE sql;
CREATE OR REPLACE FUNCTION "FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."Fortune_entity") RETURNS "FrameworkBench"."-ngs_Fortune_type-" AS $$ SELECT $1::text::"FrameworkBench"."-ngs_Fortune_type-" $$ IMMUTABLE LANGUAGE sql;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM pg_cast c JOIN pg_type s ON c.castsource = s.oid JOIN pg_type t ON c.casttarget = t.oid JOIN pg_namespace n ON n.oid = s.typnamespace AND n.oid = t.typnamespace
					WHERE n.nspname = 'FrameworkBench' AND s.typname = 'Fortune_entity' AND t.typname = '-ngs_Fortune_type-') THEN
		CREATE CAST ("FrameworkBench"."-ngs_Fortune_type-" AS "FrameworkBench"."Fortune_entity") WITH FUNCTION "FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."-ngs_Fortune_type-") AS IMPLICIT;
		CREATE CAST ("FrameworkBench"."Fortune_entity" AS "FrameworkBench"."-ngs_Fortune_type-") WITH FUNCTION "FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."Fortune_entity") AS IMPLICIT;
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."insert_Fortune"(IN _inserted "FrameworkBench"."Fortune_entity"[]) RETURNS VOID AS
$$
BEGIN
	INSERT INTO "FrameworkBench"."Fortune" ("id", "message") VALUES(_inserted[1]."id", _inserted[1]."message");
	
END
$$
LANGUAGE plpgsql SECURITY DEFINER;;

DO $$ BEGIN
	IF NOT EXISTS(SELECT * FROM "-NGS-".Load_Type_Info() WHERE type_schema = 'FrameworkBench' AND type_name = '>update-Fortune-pair<' AND column_name = 'original') THEN
		DROP TYPE IF EXISTS "FrameworkBench".">update-Fortune-pair<";
		CREATE TYPE "FrameworkBench".">update-Fortune-pair<" AS (original "FrameworkBench"."Fortune_entity", changed "FrameworkBench"."Fortune_entity");
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "FrameworkBench"."persist_Fortune"(
IN _inserted "FrameworkBench"."Fortune_entity"[], IN _updated "FrameworkBench".">update-Fortune-pair<"[], IN _deleted "FrameworkBench"."Fortune_entity"[]) 
	RETURNS VARCHAR AS
$$
DECLARE cnt int;
DECLARE uri VARCHAR;
DECLARE tmp record;
DECLARE _update_count int = array_upper(_updated, 1);
DECLARE _delete_count int = array_upper(_deleted, 1);

BEGIN

	SET CONSTRAINTS ALL DEFERRED;

	

	INSERT INTO "FrameworkBench"."Fortune" ("id", "message")
	SELECT _i."id", _i."message" 
	FROM unnest(_inserted) _i;

	

	UPDATE "FrameworkBench"."Fortune" as _tbl SET "id" = (_u.changed)."id", "message" = (_u.changed)."message"
	FROM unnest(_updated) _u
	WHERE _tbl."id" = (_u.original)."id";

	GET DIAGNOSTICS cnt = ROW_COUNT;
	IF cnt != _update_count THEN 
		RETURN 'Updated ' || cnt || ' row(s). Expected to update ' || _update_count || ' row(s).';
	END IF;

	

	DELETE FROM "FrameworkBench"."Fortune"
	WHERE ("id") IN (SELECT _d."id" FROM unnest(_deleted) _d);

	GET DIAGNOSTICS cnt = ROW_COUNT;
	IF cnt != _delete_count THEN 
		RETURN 'Deleted ' || cnt || ' row(s). Expected to delete ' || _delete_count || ' row(s).';
	END IF;

	

	SET CONSTRAINTS ALL IMMEDIATE;

	RETURN NULL;
END
$$
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "FrameworkBench"."update_Fortune"(IN _original "FrameworkBench"."Fortune_entity"[], IN _updated "FrameworkBench"."Fortune_entity"[]) RETURNS VARCHAR AS
$$
BEGIN
	
	UPDATE "FrameworkBench"."Fortune" AS _tab SET "id" = _updated[1]."id", "message" = _updated[1]."message" WHERE _tab."id" = _original[1]."id";
	
	RETURN NULL;
END
$$
LANGUAGE plpgsql SECURITY DEFINER;;

CREATE OR REPLACE VIEW "FrameworkBench"."Fortune_unprocessed_events" AS
SELECT _aggregate."id"
FROM
	"FrameworkBench"."Fortune_entity" _aggregate
;
COMMENT ON VIEW "FrameworkBench"."Fortune_unprocessed_events" IS 'NGS volatile';

SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Message_to_type"("FrameworkBench"."-ngs_Message_type-")', 'FrameworkBench', '-ngs_Message_type-', 'Message');
SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Message_to_type"("FrameworkBench"."Message")', 'FrameworkBench', 'Message', '-ngs_Message_type-');

SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."-ngs_Id10_type-")', 'FrameworkBench', '-ngs_Id10_type-', 'Id10');
SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Id10_to_type"("FrameworkBench"."Id10")', 'FrameworkBench', 'Id10', '-ngs_Id10_type-');

SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."-ngs_Id15_type-")', 'FrameworkBench', '-ngs_Id15_type-', 'Id15');
SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Id15_to_type"("FrameworkBench"."Id15")', 'FrameworkBench', 'Id15', '-ngs_Id15_type-');

SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_World_to_type"("FrameworkBench"."-ngs_World_type-")', 'FrameworkBench', '-ngs_World_type-', 'World_entity');
SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_World_to_type"("FrameworkBench"."World_entity")', 'FrameworkBench', 'World_entity', '-ngs_World_type-');

SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."-ngs_Fortune_type-")', 'FrameworkBench', '-ngs_Fortune_type-', 'Fortune_entity');
SELECT "-NGS-".Create_Type_Cast('"FrameworkBench"."cast_Fortune_to_type"("FrameworkBench"."Fortune_entity")', 'FrameworkBench', 'Fortune_entity', '-ngs_Fortune_type-');
UPDATE "FrameworkBench"."World" SET "id" = 0 WHERE "id" IS NULL;
UPDATE "FrameworkBench"."World" SET "randomNumber" = 0 WHERE "randomNumber" IS NULL;
UPDATE "FrameworkBench"."Fortune" SET "id" = 0 WHERE "id" IS NULL;
UPDATE "FrameworkBench"."Fortune" SET "message" = '' WHERE "message" IS NULL;
CREATE OR REPLACE FUNCTION "FrameworkBench"."Queries5"("id1" INT DEFAULT 0, "id2" INT DEFAULT 0, "id3" INT DEFAULT 0, "id4" INT DEFAULT 0, "id5" INT DEFAULT 0) RETURNS record AS 
$$
DECLARE "world1" "FrameworkBench"."World_entity";
DECLARE "world2" "FrameworkBench"."World_entity";
DECLARE "world3" "FrameworkBench"."World_entity";
DECLARE "world4" "FrameworkBench"."World_entity";
DECLARE "world5" "FrameworkBench"."World_entity";

DECLARE __result record;
BEGIN
	SELECT * INTO "world1" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = "Queries5"."id1") LIMIT 1;
	SELECT * INTO "world2" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = "Queries5"."id2") LIMIT 1;
	SELECT * INTO "world3" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = "Queries5"."id3") LIMIT 1;
	SELECT * INTO "world4" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = "Queries5"."id4") LIMIT 1;
	SELECT * INTO "world5" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = "Queries5"."id5") LIMIT 1;
	
	SELECT null, CASE WHEN "world1" IS NULL THEN NULL ELSE "world1" END, CASE WHEN "world2" IS NULL THEN NULL ELSE "world2" END, CASE WHEN "world3" IS NULL THEN NULL ELSE "world3" END, CASE WHEN "world4" IS NULL THEN NULL ELSE "world4" END, CASE WHEN "world5" IS NULL THEN NULL ELSE "world5" END INTO __result;
	RETURN __result;
END;
$$ LANGUAGE PLPGSQL STABLE SECURITY DEFINER;
CREATE OR REPLACE FUNCTION "FrameworkBench"."Queries10"("id" "FrameworkBench"."Id10" DEFAULT null) RETURNS record AS 
$$
DECLARE "world1" "FrameworkBench"."World_entity";
DECLARE "world2" "FrameworkBench"."World_entity";
DECLARE "world3" "FrameworkBench"."World_entity";
DECLARE "world4" "FrameworkBench"."World_entity";
DECLARE "world5" "FrameworkBench"."World_entity";
DECLARE "world6" "FrameworkBench"."World_entity";
DECLARE "world7" "FrameworkBench"."World_entity";
DECLARE "world8" "FrameworkBench"."World_entity";
DECLARE "world9" "FrameworkBench"."World_entity";
DECLARE "world10" "FrameworkBench"."World_entity";

DECLARE __result record;
BEGIN
	SELECT * INTO "world1" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id1") LIMIT 1;
	SELECT * INTO "world2" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id2") LIMIT 1;
	SELECT * INTO "world3" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id3") LIMIT 1;
	SELECT * INTO "world4" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id4") LIMIT 1;
	SELECT * INTO "world5" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id5") LIMIT 1;
	SELECT * INTO "world6" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id6") LIMIT 1;
	SELECT * INTO "world7" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id7") LIMIT 1;
	SELECT * INTO "world8" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id8") LIMIT 1;
	SELECT * INTO "world9" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id9") LIMIT 1;
	SELECT * INTO "world10" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries10"."id")."id10") LIMIT 1;
	
	SELECT null, CASE WHEN "world1" IS NULL THEN NULL ELSE "world1" END, CASE WHEN "world2" IS NULL THEN NULL ELSE "world2" END, CASE WHEN "world3" IS NULL THEN NULL ELSE "world3" END, CASE WHEN "world4" IS NULL THEN NULL ELSE "world4" END, CASE WHEN "world5" IS NULL THEN NULL ELSE "world5" END, CASE WHEN "world6" IS NULL THEN NULL ELSE "world6" END, CASE WHEN "world7" IS NULL THEN NULL ELSE "world7" END, CASE WHEN "world8" IS NULL THEN NULL ELSE "world8" END, CASE WHEN "world9" IS NULL THEN NULL ELSE "world9" END, CASE WHEN "world10" IS NULL THEN NULL ELSE "world10" END INTO __result;
	RETURN __result;
END;
$$ LANGUAGE PLPGSQL STABLE SECURITY DEFINER;
CREATE OR REPLACE FUNCTION "FrameworkBench"."Queries15"("id" "FrameworkBench"."Id15" DEFAULT null) RETURNS record AS 
$$
DECLARE "world1" "FrameworkBench"."World_entity";
DECLARE "world2" "FrameworkBench"."World_entity";
DECLARE "world3" "FrameworkBench"."World_entity";
DECLARE "world4" "FrameworkBench"."World_entity";
DECLARE "world5" "FrameworkBench"."World_entity";
DECLARE "world6" "FrameworkBench"."World_entity";
DECLARE "world7" "FrameworkBench"."World_entity";
DECLARE "world8" "FrameworkBench"."World_entity";
DECLARE "world9" "FrameworkBench"."World_entity";
DECLARE "world10" "FrameworkBench"."World_entity";
DECLARE "world11" "FrameworkBench"."World_entity";
DECLARE "world12" "FrameworkBench"."World_entity";
DECLARE "world13" "FrameworkBench"."World_entity";
DECLARE "world14" "FrameworkBench"."World_entity";
DECLARE "world15" "FrameworkBench"."World_entity";

DECLARE __result record;
BEGIN
	SELECT * INTO "world1" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id1") LIMIT 1;
	SELECT * INTO "world2" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id2") LIMIT 1;
	SELECT * INTO "world3" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id3") LIMIT 1;
	SELECT * INTO "world4" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id4") LIMIT 1;
	SELECT * INTO "world5" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id5") LIMIT 1;
	SELECT * INTO "world6" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id6") LIMIT 1;
	SELECT * INTO "world7" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id7") LIMIT 1;
	SELECT * INTO "world8" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id8") LIMIT 1;
	SELECT * INTO "world9" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id9") LIMIT 1;
	SELECT * INTO "world10" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id10") LIMIT 1;
	SELECT * INTO "world11" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id11") LIMIT 1;
	SELECT * INTO "world12" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id12") LIMIT 1;
	SELECT * INTO "world13" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id13") LIMIT 1;
	SELECT * INTO "world14" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id14") LIMIT 1;
	SELECT * INTO "world15" FROM "FrameworkBench"."World_entity" "it" WHERE 	 ((("it"))."id" = ("Queries15"."id")."id15") LIMIT 1;
	
	SELECT null, CASE WHEN "world1" IS NULL THEN NULL ELSE "world1" END, CASE WHEN "world2" IS NULL THEN NULL ELSE "world2" END, CASE WHEN "world3" IS NULL THEN NULL ELSE "world3" END, CASE WHEN "world4" IS NULL THEN NULL ELSE "world4" END, CASE WHEN "world5" IS NULL THEN NULL ELSE "world5" END, CASE WHEN "world6" IS NULL THEN NULL ELSE "world6" END, CASE WHEN "world7" IS NULL THEN NULL ELSE "world7" END, CASE WHEN "world8" IS NULL THEN NULL ELSE "world8" END, CASE WHEN "world9" IS NULL THEN NULL ELSE "world9" END, CASE WHEN "world10" IS NULL THEN NULL ELSE "world10" END, CASE WHEN "world11" IS NULL THEN NULL ELSE "world11" END, CASE WHEN "world12" IS NULL THEN NULL ELSE "world12" END, CASE WHEN "world13" IS NULL THEN NULL ELSE "world13" END, CASE WHEN "world14" IS NULL THEN NULL ELSE "world14" END, CASE WHEN "world15" IS NULL THEN NULL ELSE "world15" END INTO __result;
	RETURN __result;
END;
$$ LANGUAGE PLPGSQL STABLE SECURITY DEFINER;

DO $$ 
DECLARE _pk VARCHAR;
BEGIN
	IF EXISTS(SELECT * FROM pg_index i JOIN pg_class c ON i.indrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE i.indisprimary AND n.nspname = 'FrameworkBench' AND c.relname = 'World') THEN
		SELECT array_to_string(array_agg(sq.attname), ', ') INTO _pk
		FROM
		(
			SELECT atr.attname
			FROM pg_index i
			JOIN pg_class c ON i.indrelid = c.oid 
			JOIN pg_attribute atr ON atr.attrelid = c.oid 
			WHERE 
				c.oid = '"FrameworkBench"."World"'::regclass
				AND atr.attnum = any(i.indkey)
				AND indisprimary
			ORDER BY (SELECT i FROM generate_subscripts(i.indkey,1) g(i) WHERE i.indkey[i] = atr.attnum LIMIT 1)
		) sq;
		IF ('id' != _pk) THEN
			RAISE EXCEPTION 'Different primary key defined for table FrameworkBench.World. Expected primary key: id. Found: %', _pk;
		END IF;
	ELSE
		ALTER TABLE "FrameworkBench"."World" ADD CONSTRAINT "pk_World" PRIMARY KEY("id");
		COMMENT ON CONSTRAINT "pk_World" ON "FrameworkBench"."World" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;

DO $$ 
DECLARE _pk VARCHAR;
BEGIN
	IF EXISTS(SELECT * FROM pg_index i JOIN pg_class c ON i.indrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE i.indisprimary AND n.nspname = 'FrameworkBench' AND c.relname = 'Fortune') THEN
		SELECT array_to_string(array_agg(sq.attname), ', ') INTO _pk
		FROM
		(
			SELECT atr.attname
			FROM pg_index i
			JOIN pg_class c ON i.indrelid = c.oid 
			JOIN pg_attribute atr ON atr.attrelid = c.oid 
			WHERE 
				c.oid = '"FrameworkBench"."Fortune"'::regclass
				AND atr.attnum = any(i.indkey)
				AND indisprimary
			ORDER BY (SELECT i FROM generate_subscripts(i.indkey,1) g(i) WHERE i.indkey[i] = atr.attnum LIMIT 1)
		) sq;
		IF ('id' != _pk) THEN
			RAISE EXCEPTION 'Different primary key defined for table FrameworkBench.Fortune. Expected primary key: id. Found: %', _pk;
		END IF;
	ELSE
		ALTER TABLE "FrameworkBench"."Fortune" ADD CONSTRAINT "pk_Fortune" PRIMARY KEY("id");
		COMMENT ON CONSTRAINT "pk_Fortune" ON "FrameworkBench"."Fortune" IS 'NGS generated';
	END IF;
END $$ LANGUAGE plpgsql;
ALTER TABLE "FrameworkBench"."World" ALTER "id" SET NOT NULL;
ALTER TABLE "FrameworkBench"."World" ALTER "randomNumber" SET NOT NULL;
ALTER TABLE "FrameworkBench"."Fortune" ALTER "id" SET NOT NULL;
ALTER TABLE "FrameworkBench"."Fortune" ALTER "message" SET NOT NULL;

SELECT "-NGS-".Persist_Concepts('"Revenj.Bench\\model.dsl"=>"defaults {
	notifications disabled;
}
module FrameworkBench {
	value Message {
		String message;
	}
	aggregate World(id) {
		int id;
		int randomNumber;
	}
	aggregate Fortune(id) {
		int id;
		string message;
	}
	report Queries5 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		World world1 ''it => it.id == id1'';
		World world2 ''it => it.id == id2'';
		World world3 ''it => it.id == id3'';
		World world4 ''it => it.id == id4'';
		World world5 ''it => it.id == id5'';
	}
	value Id10 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		int id6;
		int id7;
		int id8;
		int id9;
		int id10;
	}
	report Queries10 {
		Id10 id;
		World world1 ''it => it.id == id.id1'';
		World world2 ''it => it.id == id.id2'';
		World world3 ''it => it.id == id.id3'';
		World world4 ''it => it.id == id.id4'';
		World world5 ''it => it.id == id.id5'';
		World world6 ''it => it.id == id.id6'';
		World world7 ''it => it.id == id.id7'';
		World world8 ''it => it.id == id.id8'';
		World world9 ''it => it.id == id.id9'';
		World world10 ''it => it.id == id.id10'';
	}
	value Id15 {
		int id1;
		int id2;
		int id3;
		int id4;
		int id5;
		int id6;
		int id7;
		int id8;
		int id9;
		int id10;
		int id11;
		int id12;
		int id13;
		int id14;
		int id15;
	}
	report Queries15 {
		Id15 id;
		World world1 ''it => it.id == id.id1'';
		World world2 ''it => it.id == id.id2'';
		World world3 ''it => it.id == id.id3'';
		World world4 ''it => it.id == id.id4'';
		World world5 ''it => it.id == id.id5'';
		World world6 ''it => it.id == id.id6'';
		World world7 ''it => it.id == id.id7'';
		World world8 ''it => it.id == id.id8'';
		World world9 ''it => it.id == id.id9'';
		World world10 ''it => it.id == id.id10'';
		World world11 ''it => it.id == id.id11'';
		World world12 ''it => it.id == id.id12'';
		World world13 ''it => it.id == id.id13'';
		World world14 ''it => it.id == id.id14'';
		World world15 ''it => it.id == id.id15'';
	}
}"', '\x','1.2.5570.28421');
