--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tasks; Type: SCHEMA; Schema: -; Owner: default
--

CREATE SCHEMA tasks;


ALTER SCHEMA tasks OWNER TO "default";

--
-- Name: add_created_at(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.add_created_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
	new.created_at = current_timestamp;
	return new;
	end;

$$;


ALTER FUNCTION tasks.add_created_at() OWNER TO "default";

--
-- Name: add_finished_at(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.add_finished_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
		if new.state_id = 3 or new.state_id = 4 or new.state_id = 6
			then new.finished_at = current_timestamp;
		end if;
	return new;
	end;

$$;


ALTER FUNCTION tasks.add_finished_at() OWNER TO "default";

--
-- Name: add_started_at(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.add_started_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
		if old.state_id = 1 and new.state_id = 2 or old.state_id = 1 and new.state_id = 3
			then new.started_at = current_timestamp;
		end if;
	return new;
	end;

$$;


ALTER FUNCTION tasks.add_started_at() OWNER TO "default";

--
-- Name: add_updated_at(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.add_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
	new.updated_at = current_timestamp;
	return new;
	end;

$$;


ALTER FUNCTION tasks.add_updated_at() OWNER TO "default";

--
-- Name: check_for_active(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if old.state_id = 5 and new.state_id = 1 and old.parent_id = 0
      then 
	  update tasks.staff_task set state_id = 1 where parent_id = old.id and type_id != 5 and state_id != 3 and state_id != 4 and state_id != 6;
    end if;
  return new;
  end;


$$;


ALTER FUNCTION tasks.check_for_active() OWNER TO "default";

--
-- Name: check_for_cancel(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_cancel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare count_id integer;
declare new_id integer;
  begin
    if new.state_id = 4
      then 
      	update tasks.staff_task set state_id = 4 where parent_id = old.id;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_cancel() OWNER TO "default";

--
-- Name: check_for_change_state_from_delay_to_in_progress(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_change_state_from_delay_to_in_progress() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if old.state_id = 5 and new.state_id = 2 and old.parent_id = 0
      then 
	  update tasks.staff_task set state_id = 2 where parent_id = old.id and type_id != 5 and state_id != 3 and state_id != 4 and state_id != 6;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_change_state_from_delay_to_in_progress() OWNER TO "default";

--
-- Name: check_for_delay(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_delay() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if (old.state_id = 2 or old.state_id = 1) and new.state_id = 5 
      then 
	  insert into tasks.staff_task (type_id, staff_id, state_id, parent_id, created_at, 
	  									updated_at, difficulty_level, expected_lead_time) 
			 values (5, old.staff_id, 1, old.id, current_timestamp, current_timestamp, 0, 0) RETURNING id INTO new_task_id;
	  insert into tasks.staff_form (staff_id, group_id, created_at, 
  						            updated_at, task_id) 						       
			 values (new.staff_id, 2, current_timestamp, current_timestamp, new_task_id);
			return new;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_delay() OWNER TO "default";

--
-- Name: check_for_delay_sub_tasks(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_delay_sub_tasks() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if (old.state_id = 2 or old.state_id = 1)  and new.state_id = 5 and old.parent_id = 0
      then 
	  update tasks.staff_task set state_id = 5 where parent_id = old.id and type_id != 5 and state_id != 3 and state_id != 4 and state_id != 6;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_delay_sub_tasks() OWNER TO "default";

--
-- Name: check_for_delete(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare count_id integer;
declare new_id integer;
  begin
    if new.state_id = 6
      then 
      	update tasks.staff_task set state_id = 6 where parent_id = old.id;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_delete() OWNER TO "default";

--
-- Name: check_for_done(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_done() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare count_id integer;
declare new_id integer;
  begin
    if new.state_id = 3
      then 
        select count(st.id) from tasks.staff_task st where st.parent_id = new.parent_id and st.state_id != 3 limit 1 into count_id;
      if count_id = 1 and (select st.id from tasks.staff_task st where st.parent_id = new.parent_id and st.state_id != 3 limit 1) = new.id
      	then
      	update tasks.staff_task set state_id = 3 where id = old.parent_id;
      	return new;
      end if;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_done() OWNER TO "default";

--
-- Name: check_for_end_work_day(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_end_work_day() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare count_id integer;
  begin
    if new.type_id = 4
      then 
	  select count(st.id) from tasks.staff_task st where st.state_id != 3 and st.state_id != 4 and st.state_id != 6 limit 1 into count_id;
	  if count_id > 0
	  	then raise exception 'it is impossible to complete the work day while there are unclosed tasks';
	  else return new;
	  	end if;
	  else return new;
    end if;
  end;


$$;


ALTER FUNCTION tasks.check_for_end_work_day() OWNER TO "default";

--
-- Name: check_for_lateness(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_lateness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if (new.updated_at > new.started_at + to_char(to_timestamp((new.expected_lead_time) * 60), 'MI:SS')::interval) and (old.state_id = 2 and new.state_id = 3)
      then 
      insert into tasks.staff_task (type_id, staff_id, state_id, parent_id, created_at, 
	  									updated_at, difficulty_level, expected_lead_time) 
			 values (5, old.staff_id, 1, old.id, current_timestamp, current_timestamp, 0, 0) RETURNING id INTO new_task_id;
      insert into tasks.staff_form (staff_id, group_id, created_at, 
								       updated_at, task_id) 
			 values (new.staff_id, 1, current_timestamp, current_timestamp, new_task_id);
			return new;
    end if;
  return new;
  end;

$$;


ALTER FUNCTION tasks.check_for_lateness() OWNER TO "default";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: awaiting_task_state; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.awaiting_task_state (
    id integer NOT NULL,
    title character varying(128) NOT NULL,
    code character varying(64) NOT NULL
);


ALTER TABLE tasks.awaiting_task_state OWNER TO "default";

--
-- Name: TABLE awaiting_task_state; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON TABLE tasks.awaiting_task_state IS 'возможные состояния для ожидающих тасков';


--
-- Name: awaiting_task_state_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.awaiting_task_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.awaiting_task_state_id_seq OWNER TO "default";

--
-- Name: awaiting_task_state_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.awaiting_task_state_id_seq OWNED BY tasks.awaiting_task_state.id;


--
-- Name: awaiting_tasks; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.awaiting_tasks (
    id integer NOT NULL,
    task_id integer NOT NULL,
    staff_id integer NOT NULL,
    state_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE tasks.awaiting_tasks OWNER TO "default";

--
-- Name: TABLE awaiting_tasks; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON TABLE tasks.awaiting_tasks IS 'задания, ожидающие назначеия исполнителя';


--
-- Name: COLUMN awaiting_tasks.state_id; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON COLUMN tasks.awaiting_tasks.state_id IS 'AWAITING, DELETED';


--
-- Name: awaiting_tasks_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.awaiting_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.awaiting_tasks_id_seq OWNER TO "default";

--
-- Name: awaiting_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.awaiting_tasks_id_seq OWNED BY tasks.awaiting_tasks.id;


--
-- Name: boss; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.boss (
    id integer NOT NULL,
    login character varying NOT NULL,
    pass character varying NOT NULL
);


ALTER TABLE tasks.boss OWNER TO "default";

--
-- Name: boss_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.boss_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.boss_id_seq OWNER TO "default";

--
-- Name: boss_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.boss_id_seq OWNED BY tasks.boss.id;


--
-- Name: boss_session; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.boss_session (
    id integer NOT NULL,
    device_code character varying NOT NULL,
    auth_token character varying NOT NULL,
    original_pass character varying NOT NULL,
    expires_at character varying,
    push_token character varying,
    boss_id integer NOT NULL
);


ALTER TABLE tasks.boss_session OWNER TO "default";

--
-- Name: boss_session_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.boss_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.boss_session_id_seq OWNER TO "default";

--
-- Name: boss_session_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.boss_session_id_seq OWNED BY tasks.boss_session.id;


--
-- Name: comments; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.comments (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    task_id integer NOT NULL,
    text character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE tasks.comments OWNER TO "default";

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.comments_id_seq OWNER TO "default";

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.comments_id_seq OWNED BY tasks.comments.id;


--
-- Name: difficulty_level_to_practice; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.difficulty_level_to_practice (
    id integer NOT NULL,
    practice integer NOT NULL,
    difficulty_level integer NOT NULL
);


ALTER TABLE tasks.difficulty_level_to_practice OWNER TO "default";

--
-- Name: TABLE difficulty_level_to_practice; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON TABLE tasks.difficulty_level_to_practice IS 'зависимость сложности задачи и опыта сотрудника (вспомогательная таблица, для автоматического распределения задач по сложности)';


--
-- Name: flags; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.flags (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    code character varying(64) NOT NULL
);


ALTER TABLE tasks.flags OWNER TO "default";

--
-- Name: TABLE flags; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON TABLE tasks.flags IS 'флаги для заданий';


--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.flags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.flags_id_seq OWNER TO "default";

--
-- Name: flags_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.flags_id_seq OWNED BY tasks.flags.id;


--
-- Name: question_group; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.question_group (
    id integer NOT NULL,
    code character varying(64) NOT NULL,
    title character varying(255)
);


ALTER TABLE tasks.question_group OWNER TO "default";

--
-- Name: question_group_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.question_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.question_group_id_seq OWNER TO "default";

--
-- Name: question_group_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.question_group_id_seq OWNED BY tasks.question_group.id;


--
-- Name: questions; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.questions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    code character varying(64) NOT NULL,
    title character varying(255) NOT NULL
);


ALTER TABLE tasks.questions OWNER TO "default";

--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.questions_id_seq OWNER TO "default";

--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.questions_id_seq OWNED BY tasks.questions.id;


--
-- Name: staff; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff (
    id integer NOT NULL,
    login character varying(100) NOT NULL,
    phone character varying(11) NOT NULL,
    pass_md5 character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    practice integer
);


ALTER TABLE tasks.staff OWNER TO "default";

--
-- Name: COLUMN staff.practice; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON COLUMN tasks.staff.practice IS 'опыт сотрудника';


--
-- Name: staff_answers; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff_answers (
    id integer NOT NULL,
    form_id integer NOT NULL,
    question_code character varying(64) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE tasks.staff_answers OWNER TO "default";

--
-- Name: staff_answers_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_answers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_answers_id_seq OWNER TO "default";

--
-- Name: staff_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_answers_id_seq OWNED BY tasks.staff_answers.id;


--
-- Name: staff_form; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff_form (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    task_id integer
);


ALTER TABLE tasks.staff_form OWNER TO "default";

--
-- Name: staff_form_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_form_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_form_id_seq OWNER TO "default";

--
-- Name: staff_form_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_form_id_seq OWNED BY tasks.staff_form.id;


--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_id_seq OWNER TO "default";

--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_id_seq OWNED BY tasks.staff.id;


--
-- Name: staff_session; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff_session (
    id integer NOT NULL,
    device_code character varying(100) NOT NULL,
    auth_token character varying(255) NOT NULL,
    original_pass character varying(255) NOT NULL,
    expires_at character varying,
    push_token character varying(256),
    staff_id integer NOT NULL
);


ALTER TABLE tasks.staff_session OWNER TO "default";

--
-- Name: staff_session_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_session_id_seq OWNER TO "default";

--
-- Name: staff_session_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_session_id_seq OWNED BY tasks.staff_session.id;


--
-- Name: staff_task; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff_task (
    id integer NOT NULL,
    type_id integer NOT NULL,
    staff_id integer,
    state_id integer NOT NULL,
    parent_id integer,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    difficulty_level integer,
    expected_lead_time double precision
);


ALTER TABLE tasks.staff_task OWNER TO "default";

--
-- Name: COLUMN staff_task.difficulty_level; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON COLUMN tasks.staff_task.difficulty_level IS 'уровень сложности задачи';


--
-- Name: staff_task_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_task_id_seq OWNER TO "default";

--
-- Name: staff_task_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_task_id_seq OWNED BY tasks.staff_task.id;


--
-- Name: staff_to_boss; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.staff_to_boss (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    boss_id integer NOT NULL
);


ALTER TABLE tasks.staff_to_boss OWNER TO "default";

--
-- Name: staff_to_boss_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.staff_to_boss_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.staff_to_boss_id_seq OWNER TO "default";

--
-- Name: staff_to_boss_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.staff_to_boss_id_seq OWNED BY tasks.staff_to_boss.id;


--
-- Name: task_content; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.task_content (
    id integer NOT NULL,
    text character varying,
    title character varying,
    address character varying,
    task_id integer NOT NULL
);


ALTER TABLE tasks.task_content OWNER TO "default";

--
-- Name: task_content_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.task_content_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.task_content_id_seq OWNER TO "default";

--
-- Name: task_content_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.task_content_id_seq OWNED BY tasks.task_content.id;


--
-- Name: task_incident; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.task_incident (
    id integer NOT NULL,
    inicident_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE tasks.task_incident OWNER TO "default";

--
-- Name: task_incident_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.task_incident_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.task_incident_id_seq OWNER TO "default";

--
-- Name: task_incident_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.task_incident_id_seq OWNED BY tasks.task_incident.id;


--
-- Name: task_state_change; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.task_state_change (
    id integer NOT NULL,
    type_id integer NOT NULL,
    state_from_id integer NOT NULL,
    state_to_id integer NOT NULL
);


ALTER TABLE tasks.task_state_change OWNER TO "default";

--
-- Name: task_state_change_for_boss; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.task_state_change_for_boss (
    id integer NOT NULL,
    type_id integer NOT NULL,
    state_from_id integer NOT NULL,
    state_to_id integer NOT NULL
);


ALTER TABLE tasks.task_state_change_for_boss OWNER TO "default";

--
-- Name: task_state_change_for_boss_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.task_state_change_for_boss_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.task_state_change_for_boss_id_seq OWNER TO "default";

--
-- Name: task_state_change_for_boss_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.task_state_change_for_boss_id_seq OWNED BY tasks.task_state_change_for_boss.id;


--
-- Name: task_state_change_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.task_state_change_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.task_state_change_id_seq OWNER TO "default";

--
-- Name: task_state_change_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.task_state_change_id_seq OWNED BY tasks.task_state_change.id;


--
-- Name: task_type; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.task_type (
    id integer NOT NULL,
    title character varying(128) NOT NULL,
    code character varying(64) NOT NULL
);


ALTER TABLE tasks.task_type OWNER TO "default";

--
-- Name: task_type_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.task_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.task_type_id_seq OWNER TO "default";

--
-- Name: task_type_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.task_type_id_seq OWNED BY tasks.task_type.id;


--
-- Name: tasks_flags; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.tasks_flags (
    id integer NOT NULL,
    task_id integer NOT NULL,
    flag_id integer NOT NULL
);


ALTER TABLE tasks.tasks_flags OWNER TO "default";

--
-- Name: tasks_flags_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.tasks_flags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.tasks_flags_id_seq OWNER TO "default";

--
-- Name: tasks_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.tasks_flags_id_seq OWNED BY tasks.tasks_flags.id;


--
-- Name: tasks_state; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.tasks_state (
    id integer NOT NULL,
    title character varying(128) NOT NULL,
    code character varying(64) NOT NULL
);


ALTER TABLE tasks.tasks_state OWNER TO "default";

--
-- Name: TABLE tasks_state; Type: COMMENT; Schema: tasks; Owner: default
--

COMMENT ON TABLE tasks.tasks_state IS 'tasks for users';


--
-- Name: tasks_state_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.tasks_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.tasks_state_id_seq OWNER TO "default";

--
-- Name: tasks_state_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.tasks_state_id_seq OWNED BY tasks.tasks_state.id;


--
-- Name: who_create_confirm_lead_time; Type: TABLE; Schema: tasks; Owner: default
--

CREATE TABLE tasks.who_create_confirm_lead_time (
    id integer NOT NULL,
    creater character varying NOT NULL,
    task_id integer NOT NULL
);


ALTER TABLE tasks.who_create_confirm_lead_time OWNER TO "default";

--
-- Name: who_create_confirm_lead_time_id_seq; Type: SEQUENCE; Schema: tasks; Owner: default
--

CREATE SEQUENCE tasks.who_create_confirm_lead_time_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tasks.who_create_confirm_lead_time_id_seq OWNER TO "default";

--
-- Name: who_create_confirm_lead_time_id_seq; Type: SEQUENCE OWNED BY; Schema: tasks; Owner: default
--

ALTER SEQUENCE tasks.who_create_confirm_lead_time_id_seq OWNED BY tasks.who_create_confirm_lead_time.id;


--
-- Name: awaiting_task_state id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_task_state ALTER COLUMN id SET DEFAULT nextval('tasks.awaiting_task_state_id_seq'::regclass);


--
-- Name: awaiting_tasks id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_tasks ALTER COLUMN id SET DEFAULT nextval('tasks.awaiting_tasks_id_seq'::regclass);


--
-- Name: boss id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss ALTER COLUMN id SET DEFAULT nextval('tasks.boss_id_seq'::regclass);


--
-- Name: boss_session id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss_session ALTER COLUMN id SET DEFAULT nextval('tasks.boss_session_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.comments ALTER COLUMN id SET DEFAULT nextval('tasks.comments_id_seq'::regclass);


--
-- Name: flags id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.flags ALTER COLUMN id SET DEFAULT nextval('tasks.flags_id_seq'::regclass);


--
-- Name: question_group id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.question_group ALTER COLUMN id SET DEFAULT nextval('tasks.question_group_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.questions ALTER COLUMN id SET DEFAULT nextval('tasks.questions_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff ALTER COLUMN id SET DEFAULT nextval('tasks.staff_id_seq'::regclass);


--
-- Name: staff_answers id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_answers ALTER COLUMN id SET DEFAULT nextval('tasks.staff_answers_id_seq'::regclass);


--
-- Name: staff_form id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_form ALTER COLUMN id SET DEFAULT nextval('tasks.staff_form_id_seq'::regclass);


--
-- Name: staff_session id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_session ALTER COLUMN id SET DEFAULT nextval('tasks.staff_session_id_seq'::regclass);


--
-- Name: staff_task id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_task ALTER COLUMN id SET DEFAULT nextval('tasks.staff_task_id_seq'::regclass);


--
-- Name: staff_to_boss id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_to_boss ALTER COLUMN id SET DEFAULT nextval('tasks.staff_to_boss_id_seq'::regclass);


--
-- Name: task_content id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_content ALTER COLUMN id SET DEFAULT nextval('tasks.task_content_id_seq'::regclass);


--
-- Name: task_incident id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_incident ALTER COLUMN id SET DEFAULT nextval('tasks.task_incident_id_seq'::regclass);


--
-- Name: task_state_change id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change ALTER COLUMN id SET DEFAULT nextval('tasks.task_state_change_id_seq'::regclass);


--
-- Name: task_state_change_for_boss id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change_for_boss ALTER COLUMN id SET DEFAULT nextval('tasks.task_state_change_for_boss_id_seq'::regclass);


--
-- Name: task_type id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_type ALTER COLUMN id SET DEFAULT nextval('tasks.task_type_id_seq'::regclass);


--
-- Name: tasks_flags id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_flags ALTER COLUMN id SET DEFAULT nextval('tasks.tasks_flags_id_seq'::regclass);


--
-- Name: tasks_state id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_state ALTER COLUMN id SET DEFAULT nextval('tasks.tasks_state_id_seq'::regclass);


--
-- Name: who_create_confirm_lead_time id; Type: DEFAULT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.who_create_confirm_lead_time ALTER COLUMN id SET DEFAULT nextval('tasks.who_create_confirm_lead_time_id_seq'::regclass);


--
-- Data for Name: awaiting_task_state; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.awaiting_task_state (id, title, code) FROM stdin;
1	Ожидает	AWAITING
2	Удалено	DELETED
\.


--
-- Data for Name: awaiting_tasks; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.awaiting_tasks (id, task_id, staff_id, state_id, created_at, updated_at, deleted_at) FROM stdin;
47	139	1	2	2020-02-22 12:26:36.702545	2020-02-22 12:45:16.647245	\N
66	302	1	2	2020-05-31 21:50:45.183018	2020-05-31 21:51:01.526723	\N
\.


--
-- Data for Name: boss; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.boss (id, login, pass) FROM stdin;
1	BigBoss	$2a$10$f0al/8Z2yIVyadnpXUXD2ePnfS3Y76FyZqfCr5QocfkkrFI./GmOm
\.


--
-- Data for Name: boss_session; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.boss_session (id, device_code, auth_token, original_pass, expires_at, push_token, boss_id) FROM stdin;
5	1ce27d05ee3c5a48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$f0al/8Z2yIVyadnpXUXD2ePnfS3Y76FyZqfCr5QocfkkrFI./GmOm	2020-10-25T10:16:23.000Z	cmlWMUMdRM2cRGeYrNDN6L:APA91bFKaVwSpwwnPORCgD4ZbLpNiNfIbTSRcDIsSplWCx84PKkW_GwTmUV1UjDhFgaEu5yrCkjlw9_wX2Yqxo5ZLcU7nzKFeBU9MsAXG7QYc_gfFMB4bhmUn1J2Lz98gNBgH_OHXOJ5	1
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.comments (id, staff_id, task_id, text, created_at, deleted_at) FROM stdin;
3	1	137	Личный кабинет и метрики пока отсутствуют, появятся в будущем 	2020-02-22 12:24:57.910618	\N
4	1	137	Авторизации и пушей тоже пока нет 😁	2020-02-22 12:25:19.029282	\N
5	1	136	Исследовательский раздел: краткая характеристика объекта исследования, определение места подсистемы в которую входят задачи ВКР (???), особенности проектруемой системы в сравнении с аналогичными, характеристика аналогов, оценка должна носить конкретный характер и даваться в количественных  характеристиках (вот тут вообще непонятно, какие количественные характеристики можно привести) 	2020-02-22 15:29:00.33514	\N
\.


--
-- Data for Name: difficulty_level_to_practice; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.difficulty_level_to_practice (id, practice, difficulty_level) FROM stdin;
\.


--
-- Data for Name: flags; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.flags (id, title, code) FROM stdin;
1	Срочно	URGENTLY
\.


--
-- Data for Name: question_group; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.question_group (id, code, title) FROM stdin;
1	LATENESS	Опоздание
2	DELAY	Откладывание задания
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.questions (id, group_id, code, title) FROM stdin;
1	1	ACCIDENT	Непредвиденные обсточтельства
2	1	ROW_TASK	Нечетко сформулированное задание
3	2	UNCOMFORTABLE	Не удобно выполнять задание сейчас 
4	2	DELETE_REQUIRED	Требуется удаление задания
5	2	CANCEL_REQUIRED	Требуется отмена задания
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff (id, login, phone, pass_md5, created_at, updated_at, deleted_at, practice) FROM stdin;
1	Liza	89167337777	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2019-12-08 11:31:57.259851	2019-12-08 11:31:57.259851	0001-01-01 00:00:00	\N
8	Karl	89991112233	$2a$10$OGqXX10iPgWm0sw/ld.Mm.pL.9PSxblNdCZa8rh2EVPmZty30N4bW	2020-05-10 15:35:00.526801	2020-05-10 15:35:00.526801	\N	\N
9	Lip	89991112233	$2a$10$fBqi.5QVhYRek4ghkDGgMOHF4OEU4KoVrP/NtrQ5K7WYp.5HWWWcu	2020-05-10 15:36:51.555542	2020-05-10 15:36:51.555542	\N	\N
10	Yen	89991112233	$2a$10$kjzuFumxAov6WqvimHYFcev1dMH8wQxAkpt4Vs5HEd8aXKE1W2azm	2020-05-10 15:38:21.640246	2020-05-10 15:38:21.640246	\N	\N
\.


--
-- Data for Name: staff_answers; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_answers (id, form_id, question_code, created_at, updated_at, deleted_at) FROM stdin;
1	11	DELETE_REQUIRED	2019-12-29 19:07:12.11233	2019-12-29 19:07:12.11233	\N
2	11	DELETE_REQUIRED	2019-12-29 19:20:34.266108	2019-12-29 19:20:34.266108	\N
3	11	DELETE_REQUIRED	2019-12-29 19:34:58.796295	2019-12-29 19:34:58.796295	\N
4	29	DELETE_REQUIRED	2019-12-30 01:28:44.936336	2019-12-30 01:28:44.936336	\N
5	29	DELETE_REQUIRED	2019-12-30 01:29:41.490646	2019-12-30 01:29:41.490646	\N
6	29	DELETE_REQUIRED	2019-12-30 01:34:59.586076	2019-12-30 01:34:59.586076	\N
7	29	DELETE_REQUIRED	2019-12-30 01:36:07.644317	2019-12-30 01:36:07.644317	\N
8	30	DELETE_REQUIRED	2019-12-30 01:37:48.685022	2019-12-30 01:37:48.685022	\N
9	31	DELETE_REQUIRED	2019-12-30 01:40:34.962246	2019-12-30 01:40:34.962246	\N
10	59	UNCOMFORTABLE	2020-02-23 19:50:08.660757	2020-02-23 19:50:08.660757	\N
11	60	ACCIDENT	2020-02-23 20:21:07.792167	2020-02-23 20:21:07.792167	\N
12	61	ROW_TASK	2020-02-23 20:21:43.649156	2020-02-23 20:21:43.649156	\N
13	62	ACCIDENT	2020-02-23 20:22:21.813072	2020-02-23 20:22:21.813072	\N
14	59	DELETE_REQUIRED	2020-02-23 20:40:43.218437	2020-02-23 20:40:43.218437	\N
15	63	ROW_TASK	2020-02-23 20:41:07.267126	2020-02-23 20:41:07.267126	\N
16	64	DELETE_REQUIRED	2020-03-01 11:24:31.15706	2020-03-01 11:24:31.15706	\N
17	72	CANCEL_REQUIRED	2020-03-01 13:25:03.495175	2020-03-01 13:25:03.495175	\N
18	73	CANCEL_REQUIRED	2020-03-01 13:25:32.260081	2020-03-01 13:25:32.260081	\N
19	74	ROW_TASK	2020-03-01 13:34:20.641669	2020-03-01 13:34:20.641669	\N
20	75	CANCEL_REQUIRED	2020-03-01 14:08:35.107184	2020-03-01 14:08:35.107184	\N
21	76	ROW_TASK	2020-03-01 15:33:16.050795	2020-03-01 15:33:16.050795	\N
22	77	UNCOMFORTABLE	2020-03-01 18:44:42.672573	2020-03-01 18:44:42.672573	\N
23	77	UNCOMFORTABLE	2020-03-01 18:44:43.502487	2020-03-01 18:44:43.502487	\N
24	77	UNCOMFORTABLE	2020-03-01 18:44:45.892183	2020-03-01 18:44:45.892183	\N
25	77	UNCOMFORTABLE	2020-03-01 18:44:47.245374	2020-03-01 18:44:47.245374	\N
26	80	UNCOMFORTABLE	2020-05-10 18:31:10.039787	2020-05-10 18:31:10.039787	\N
27	81	DELETE_REQUIRED	2020-05-10 18:35:43.246863	2020-05-10 18:35:43.246863	\N
28	82	UNCOMFORTABLE	2020-05-23 19:08:27.618435	2020-05-23 19:08:27.618435	\N
29	83	ACCIDENT	2020-05-23 19:57:04.933462	2020-05-23 19:57:04.933462	\N
30	84	ROW_TASK	2020-05-23 19:57:26.784272	2020-05-23 19:57:26.784272	\N
31	85	ACCIDENT	2020-05-23 19:58:24.785947	2020-05-23 19:58:24.785947	\N
32	86	DELETE_REQUIRED	2020-05-23 20:01:24.248387	2020-05-23 20:01:24.248387	\N
33	87	CANCEL_REQUIRED	2020-05-23 20:01:42.551246	2020-05-23 20:01:42.551246	\N
34	88	DELETE_REQUIRED	2020-05-23 20:02:37.148354	2020-05-23 20:02:37.148354	\N
35	89	CANCEL_REQUIRED	2020-05-23 20:02:56.118238	2020-05-23 20:02:56.118238	\N
36	90	ROW_TASK	2020-05-24 12:41:47.183595	2020-05-24 12:41:47.183595	\N
37	91	ROW_TASK	2020-05-24 12:42:48.678967	2020-05-24 12:42:48.678967	\N
38	92	DELETE_REQUIRED	2020-05-31 19:19:07.692819	2020-05-31 19:19:07.692819	\N
39	94	CANCEL_REQUIRED	2020-05-31 19:54:21.702313	2020-05-31 19:54:21.702313	\N
40	96	ACCIDENT	2020-05-31 21:02:27.790674	2020-05-31 21:02:27.790674	\N
41	99	CANCEL_REQUIRED	2020-05-31 21:47:57.504604	2020-05-31 21:47:57.504604	\N
42	101	ACCIDENT	2020-06-01 19:40:16.798706	2020-06-01 19:40:16.798706	\N
\.


--
-- Data for Name: staff_form; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_form (id, staff_id, group_id, created_at, updated_at, deleted_at, task_id) FROM stdin;
29	1	2	2019-12-29 22:24:32.758245	2019-12-29 22:24:32.758245	\N	69
30	1	2	2019-12-29 22:26:26.0089	2019-12-29 22:26:26.0089	\N	70
31	1	2	2019-12-29 22:40:13.518956	2019-12-29 22:40:13.518956	\N	71
32	1	1	2020-01-05 08:14:41.674652	2020-01-05 08:14:41.674652	\N	72
33	1	1	2020-01-05 08:46:59.578209	2020-01-05 08:46:59.578209	\N	74
34	1	1	2020-01-05 08:56:51.844645	2020-01-05 08:56:51.844645	\N	76
51	1	1	2020-01-05 11:20:57.367335	2020-01-05 11:20:57.367335	\N	94
52	1	1	2020-01-05 11:20:57.367335	2020-01-05 11:20:57.367335	\N	95
54	1	1	2020-01-05 11:26:12.030521	2020-01-05 11:26:12.030521	\N	99
55	1	2	2020-01-05 11:40:47.418501	2020-01-05 11:40:47.418501	\N	101
56	1	2	2020-01-05 11:40:47.418501	2020-01-05 11:40:47.418501	\N	102
57	1	2	2020-02-15 12:50:17.667349	2020-02-15 12:50:17.667349	\N	115
58	1	1	2020-02-16 20:50:44.283176	2020-02-16 20:50:44.283176	\N	122
59	1	2	2020-02-23 16:48:11.993054	2020-02-23 16:48:11.993054	\N	143
60	1	1	2020-02-23 17:20:49.410854	2020-02-23 17:20:49.410854	\N	147
61	1	1	2020-02-23 17:21:30.654203	2020-02-23 17:21:30.654203	\N	148
62	1	1	2020-02-23 17:22:17.114065	2020-02-23 17:22:17.114065	\N	149
63	1	1	2020-02-23 17:41:03.265217	2020-02-23 17:41:03.265217	\N	150
64	1	2	2020-03-01 08:24:05.152668	2020-03-01 08:24:05.152668	\N	159
65	1	2	2020-03-01 08:25:16.723148	2020-03-01 08:25:16.723148	\N	160
66	1	2	2020-03-01 08:35:11.161875	2020-03-01 08:35:11.161875	\N	161
67	1	2	2020-03-01 08:35:11.161875	2020-03-01 08:35:11.161875	\N	162
68	1	2	2020-03-01 08:35:29.042311	2020-03-01 08:35:29.042311	\N	163
69	1	2	2020-03-01 08:35:29.042311	2020-03-01 08:35:29.042311	\N	164
70	1	1	2020-03-01 10:05:47.811095	2020-03-01 10:05:47.811095	\N	166
71	1	1	2020-03-01 10:07:52.710848	2020-03-01 10:07:52.710848	\N	168
72	1	2	2020-03-01 10:24:36.313385	2020-03-01 10:24:36.313385	\N	170
73	1	2	2020-03-01 10:25:28.268158	2020-03-01 10:25:28.268158	\N	171
74	1	1	2020-03-01 10:32:56.428043	2020-03-01 10:32:56.428043	\N	172
75	1	2	2020-03-01 11:08:24.90159	2020-03-01 11:08:24.90159	\N	175
76	1	1	2020-03-01 12:33:09.677557	2020-03-01 12:33:09.677557	\N	177
78	1	2	2020-03-01 17:59:16.442864	2020-03-01 17:59:16.442864	\N	181
79	1	1	2020-05-05 11:22:17.949243	2020-05-05 11:22:17.949243	\N	187
80	10	2	2020-05-10 15:24:32.606919	2020-05-10 15:24:32.606919	\N	189
81	10	2	2020-05-10 15:34:45.144663	2020-05-10 15:34:45.144663	\N	190
82	9	2	2020-05-23 16:08:10.486123	2020-05-23 16:08:10.486123	\N	212
83	10	1	2020-05-23 16:56:52.281412	2020-05-23 16:56:52.281412	\N	216
84	10	1	2020-05-23 16:57:12.47789	2020-05-23 16:57:12.47789	\N	217
85	9	1	2020-05-23 16:58:16.207717	2020-05-23 16:58:16.207717	\N	218
86	9	2	2020-05-23 17:01:11.518267	2020-05-23 17:01:11.518267	\N	219
87	9	2	2020-05-23 17:01:36.45688	2020-05-23 17:01:36.45688	\N	220
88	1	2	2020-05-23 17:02:27.791322	2020-05-23 17:02:27.791322	\N	221
89	1	2	2020-05-23 17:02:45.789827	2020-05-23 17:02:45.789827	\N	222
90	8	1	2020-05-24 09:41:39.893604	2020-05-24 09:41:39.893604	\N	225
91	1	1	2020-05-24 09:42:43.288049	2020-05-24 09:42:43.288049	\N	226
92	1	2	2020-05-31 16:18:48.605393	2020-05-31 16:18:48.605393	\N	280
93	1	2	2020-05-31 16:18:48.605393	2020-05-31 16:18:48.605393	\N	281
94	1	2	2020-05-31 16:54:01.302414	2020-05-31 16:54:01.302414	\N	285
95	1	2	2020-05-31 16:54:01.302414	2020-05-31 16:54:01.302414	\N	286
96	1	1	2020-05-31 18:02:17.402185	2020-05-31 18:02:17.402185	\N	290
97	1	2	2020-05-31 18:39:39.777146	2020-05-31 18:39:39.777146	\N	295
98	1	2	2020-05-31 18:39:39.777146	2020-05-31 18:39:39.777146	\N	296
99	1	2	2020-05-31 18:47:32.426518	2020-05-31 18:47:32.426518	\N	300
100	1	2	2020-05-31 18:47:32.426518	2020-05-31 18:47:32.426518	\N	301
101	1	1	2020-06-01 16:39:56.177698	2020-06-01 16:39:56.177698	\N	304
\.


--
-- Data for Name: staff_session; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_session (id, device_code, auth_token, original_pass, expires_at, push_token, staff_id) FROM stdin;
23	1ce27d05ee3c5a48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjh9.qg9oyegoV3XW_r40qAyjTsYN6TmoFtKFkejEtdD2Nbk	$2a$10$OGqXX10iPgWm0sw/ld.Mm.pL.9PSxblNdCZa8rh2EVPmZty30N4bW	2020-10-25T10:16:23.000Z	fqCPgopiRs6kdYiMJqKSKk:APA91bEyyzZ1ho3SWH7XcVtZ2-DqgXn2_oMXeU_zkLEjtj_FN54W69T1Ozrlo17Sv6Im7eC8kS6huXia5E7OQf1_VN-hyl3ZdzBiNn5TkxmkEyE9KSVSEyfgw32sL-j672g9dNh2IWg1	8
24	1ce27d05ee3c5a48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjl9.Zy4gt-wL1k39d2ITD7kCmlXBT1o3L4nxUkrwRCLJth8	$2a$10$fBqi.5QVhYRek4ghkDGgMOHF4OEU4KoVrP/NtrQ5K7WYp.5HWWWcu	2020-10-25T10:16:23.000Z	fqCPgopiRs6kdYiMJqKSKk:APA91bEyyzZ1ho3SWH7XcVtZ2-DqgXn2_oMXeU_zkLEjtj_FN54W69T1Ozrlo17Sv6Im7eC8kS6huXia5E7OQf1_VN-hyl3ZdzBiNn5TkxmkEyE9KSVSEyfgw32sL-j672g9dNh2IWg1	9
26	1ce27d05ee3c5a48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	fqCPgopiRs6kdYiMJqKSKk:APA91bEyyzZ1ho3SWH7XcVtZ2-DqgXn2_oMXeU_zkLEjtj_FN54W69T1Ozrlo17Sv6Im7eC8kS6huXia5E7OQf1_VN-hyl3ZdzBiNn5TkxmkEyE9KSVSEyfgw32sL-j672g9dNh2IWg1	1
22	1ce27d05ee3c5a48	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjEwfQ.N62a4206e3fAbMB5veIQM2FDqJhhGDN2j5FSJy01RyM	$2a$10$kjzuFumxAov6WqvimHYFcev1dMH8wQxAkpt4Vs5HEd8aXKE1W2azm	2020-10-25T10:16:23.000Z	fqCPgopiRs6kdYiMJqKSKk:APA91bEyyzZ1ho3SWH7XcVtZ2-DqgXn2_oMXeU_zkLEjtj_FN54W69T1Ozrlo17Sv6Im7eC8kS6huXia5E7OQf1_VN-hyl3ZdzBiNn5TkxmkEyE9KSVSEyfgw32sL-j672g9dNh2IWg1	10
\.


--
-- Data for Name: staff_task; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_task (id, type_id, staff_id, state_id, parent_id, started_at, finished_at, created_at, updated_at, deleted_at, difficulty_level, expected_lead_time) FROM stdin;
182	3	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-03-01 21:14:24.329363	2020-03-02 00:14:24.33046	\N	0	0
135	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:19:24.96143	2020-02-22 12:19:24.96143	\N	2	1
136	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:21:33.80168	2020-02-22 12:21:33.80168	\N	2	1
137	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:23:04.925219	2020-02-22 12:23:04.925219	\N	2	1
139	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:26:36.667513	2020-02-22 12:45:16.633145	\N	0	0
140	6	5	1	139	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 23:38:43.622857	2020-02-22 23:38:43.622857	\N	2	4
166	5	1	1	165	\N	\N	2020-03-01 10:05:47.811095	2020-03-01 10:05:47.811095	\N	0	0
204	6	9	3	0	2020-05-23 16:07:50.977226	2020-05-23 16:07:57.394032	2020-05-23 14:09:27.144139	2020-05-23 16:07:57.394032	\N	4	2
168	5	1	1	167	\N	\N	2020-03-01 10:07:52.710848	2020-03-01 10:07:52.710848	\N	0	0
214	6	10	3	0	2020-05-23 16:35:05.790502	2020-05-23 16:56:52.281412	2020-05-23 16:14:47.117491	2020-05-23 16:56:52.281412	\N	1	0.05
216	5	10	3	214	\N	2020-05-23 16:57:04.941511	2020-05-23 16:56:52.281412	2020-05-23 16:57:04.941511	\N	0	0
187	5	1	1	179	\N	\N	2020-05-05 11:22:17.949243	2020-05-05 11:22:17.949243	\N	0	0
213	6	10	3	0	2020-05-23 16:35:04.448256	2020-05-23 16:57:12.47789	2020-05-23 16:13:41.677525	2020-05-23 16:57:12.47789	\N	1	0.1
217	5	10	3	213	\N	2020-05-23 16:57:26.801992	2020-05-23 16:57:12.47789	2020-05-23 16:57:26.801992	\N	0	0
199	6	10	3	198	2020-05-23 16:09:21.585826	2020-05-23 16:57:35.588568	2020-05-23 14:00:32.905523	2020-05-23 16:57:35.588568	\N	1	2
198	6	10	3	0	2020-05-23 16:09:07.347088	2020-05-23 16:57:39.118512	2020-05-23 13:57:31.802987	2020-05-23 16:57:39.118512	\N	2	1
215	6	9	3	0	2020-05-23 16:34:39.020398	2020-05-23 16:58:16.207717	2020-05-23 16:16:23.236799	2020-05-23 16:58:16.207717	\N	2	0.15
218	5	9	3	215	\N	2020-05-23 16:58:24.792033	2020-05-23 16:58:16.207717	2020-05-23 16:58:24.792033	\N	0	0
210	6	8	3	0	2020-05-23 16:07:18.170753	2020-05-23 16:59:23.195303	2020-05-23 16:04:33.194741	2020-05-23 16:59:23.195303	\N	4	1
211	6	8	3	0	2020-05-23 16:07:12.039692	2020-05-23 16:59:30.29128	2020-05-23 16:07:02.248115	2020-05-23 16:59:30.29128	\N	5	3
221	5	1	6	205	\N	2020-05-23 17:02:37.160144	2020-05-23 17:02:27.791322	2020-05-23 17:03:20.032179	\N	0	0
205	6	1	6	0	2020-05-23 16:10:38.233742	0001-01-01 00:00:00	2020-05-23 15:57:11.115446	2020-05-23 17:03:20.032179	\N	3	3
212	5	9	4	206	\N	2020-05-23 16:08:27.630219	2020-05-23 16:08:10.486123	2020-05-23 17:03:31.366162	\N	0	0
219	5	9	4	206	\N	2020-05-23 17:01:24.2677	2020-05-23 17:01:11.518267	2020-05-23 17:03:31.366162	\N	0	0
206	6	9	4	0	2020-05-23 16:58:08.557495	0001-01-01 00:00:00	2020-05-23 15:58:26.35348	2020-05-23 17:03:31.366162	\N	1	4
197	6	8	3	194	2020-05-23 15:49:56.439019	2020-05-23 15:50:01.271369	2020-05-23 13:56:29.051896	2020-05-23 15:50:01.271369	\N	1	1
220	5	9	4	207	\N	2020-05-23 17:01:42.567443	2020-05-23 17:01:36.45688	2020-05-23 17:03:36.423874	\N	0	0
195	6	8	3	194	2020-05-23 15:50:05.426921	2020-05-23 15:50:07.561499	2020-05-23 13:50:07.301922	2020-05-23 15:50:07.561499	\N	3	0.15
194	6	8	3	0	2020-05-23 15:49:42.461883	2020-05-23 15:50:12.069438	2020-05-23 13:48:33.023063	2020-05-23 15:50:12.069438	\N	1	2.45
207	6	9	4	0	2020-05-23 16:08:32.68595	0001-01-01 00:00:00	2020-05-23 15:59:55.046593	2020-05-23 17:03:36.423874	\N	5	4
222	5	1	6	209	\N	2020-05-23 17:02:56.127815	2020-05-23 17:02:45.789827	2020-05-23 17:03:40.758424	\N	0	0
209	6	1	6	0	2020-05-23 16:10:40.185081	0001-01-01 00:00:00	2020-05-23 16:02:20.97206	2020-05-23 17:03:40.758424	\N	6	1.3
224	6	8	3	0	2020-05-23 17:29:02.581564	2020-05-24 09:41:39.893604	2020-05-23 17:13:08.891484	2020-05-24 09:41:39.893604	\N	1	0.1
225	5	8	3	224	\N	2020-05-24 09:41:47.195436	2020-05-24 09:41:39.893604	2020-05-24 09:41:47.195436	\N	0	0
223	6	1	3	0	2020-05-23 17:28:47.718347	2020-05-24 09:42:43.288049	2020-05-23 17:11:06.008795	2020-05-24 09:42:43.288049	\N	2	0.1
226	5	1	3	223	\N	2020-05-24 09:42:48.687952	2020-05-24 09:42:43.288049	2020-05-24 09:42:48.687952	\N	0	0
268	2	1	3	267	0001-01-01 00:00:00	2020-05-31 16:13:42.656212	2020-05-31 14:02:10.902567	2020-05-31 16:13:42.656212	\N	0	1.2
279	2	1	6	277	0001-01-01 00:00:00	2020-05-31 16:18:37.721218	2020-05-31 16:18:21.395455	2020-05-31 16:19:28.017668	\N	0	1
281	5	1	6	278	\N	\N	2020-05-31 16:18:48.605393	2020-05-31 16:19:28.017668	\N	0	0
278	6	1	6	277	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-05-31 16:17:50.927211	2020-05-31 16:19:28.017668	\N	1	2
280	5	1	6	277	\N	2020-05-31 16:19:07.720796	2020-05-31 16:18:48.605393	2020-05-31 16:19:28.017668	\N	0	0
277	6	1	6	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-05-31 16:16:57.03396	2020-05-31 16:19:28.017668	\N	1	1
290	5	1	3	289	2020-05-31 18:02:27.797529	2020-05-31 18:02:27.797529	2020-05-31 18:02:17.402185	2020-05-31 18:02:27.797529	\N	0	0
284	2	1	4	282	0001-01-01 00:00:00	2020-05-31 16:53:50.429119	2020-05-31 16:53:24.914087	2020-05-31 16:54:38.181971	\N	0	1
286	5	1	4	283	\N	\N	2020-05-31 16:54:01.302414	2020-05-31 16:54:38.181971	\N	0	0
283	6	1	4	282	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-05-31 16:52:52.059791	2020-05-31 16:54:38.181971	\N	2	2
285	5	1	4	282	\N	2020-05-31 16:54:21.711292	2020-05-31 16:54:01.302414	2020-05-31 16:54:38.181971	\N	0	0
282	6	1	4	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-05-31 16:51:41.63227	2020-05-31 16:54:38.181971	\N	1	1
267	6	1	3	0	2020-05-31 16:54:50.787355	2020-05-31 16:55:08.593761	2020-05-31 14:01:33.987164	2020-05-31 16:55:08.593761	\N	1	1.2
288	6	1	3	0	2020-05-31 17:27:09.023488	2020-05-31 17:36:20.179558	2020-05-31 17:23:17.693326	2020-05-31 17:36:20.179558	\N	2	1
289	6	1	3	0	2020-05-31 17:54:52.149139	2020-05-31 18:02:17.402185	2020-05-31 17:47:58.550865	2020-05-31 18:02:17.402185	\N	1	0.05
294	2	1	3	292	2020-05-31 18:39:27.269413	2020-05-31 18:39:27.269413	2020-05-31 18:37:04.898081	2020-05-31 18:39:27.269413	\N	0	1
300	5	1	4	297	2020-05-31 18:47:57.520081	2020-05-31 18:48:08.707576	2020-05-31 18:47:32.426518	2020-05-31 18:48:08.707576	\N	0	0
299	2	1	4	297	2020-05-31 18:47:24.265745	2020-05-31 18:48:08.707576	2020-05-31 18:47:12.293099	2020-05-31 18:48:08.707576	\N	0	1
301	5	1	4	298	\N	2020-05-31 18:48:08.707576	2020-05-31 18:47:32.426518	2020-05-31 18:48:08.707576	\N	0	0
298	6	1	4	297	0001-01-01 00:00:00	2020-05-31 18:48:08.707576	2020-05-31 18:46:44.900954	2020-05-31 18:48:08.707576	\N	1	0.15
297	6	1	4	0	0001-01-01 00:00:00	2020-05-31 18:48:08.707576	2020-05-31 18:44:51.301255	2020-05-31 18:48:08.707576	\N	1	1
291	6	1	3	0	2020-05-31 18:48:41.385907	2020-05-31 18:48:48.178819	2020-05-31 18:12:04.528414	2020-05-31 18:48:48.178819	\N	1	1
302	6	1	3	0	2020-05-31 18:51:08.692978	2020-06-01 16:39:56.177698	2020-05-31 18:50:45.164164	2020-06-01 16:39:56.177698	\N	1	1
304	5	1	3	302	2020-06-01 16:40:16.805959	2020-06-01 16:40:16.805959	2020-06-01 16:39:56.177698	2020-06-01 16:40:16.805959	\N	0	0
305	6	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-06-01 16:57:27.093095	2020-06-01 19:57:27.093916	\N	1	1
\.


--
-- Data for Name: staff_to_boss; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_to_boss (id, staff_id, boss_id) FROM stdin;
1	1	1
7	8	1
8	9	1
9	10	1
\.


--
-- Data for Name: task_content; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_content (id, text, title, address, task_id) FROM stdin;
9	Прочитать первую главу, сделать рекомендации по написанию введения, Шамиль Гасангусейнович сказал добавить "что это, зачем нужно, в каких компаниях используется" 	Первая глава 	Где угодно 	135
10	Есть методичка(могу скинуть, потому что пока нет возможности добавления файлов), в ней есть не очень понятное описание, как, что и куда нужно делить: нужно подумать  над тем какие пункты и подпункты должна содержать ВКР, дать какие-то советы по содержанию	Структуризация 	Где угодно 	136
11	Рассмотреть имеющийся функционал, подумать над тем, что можно добавить 	Функционал приложения 	Где угодно 	137
13	Тест	Тест 	Тест 	139
14	Тест тест тест 	Тест тест 	Южная, 15	140
38	Подготовить бар к мероприятию	Подготовка	Юбилейный проспект, 47, Реутов, городской округ Реутов, Московская область	194
39	Протереть стаканы полотенцем с микрофиброй	Протереть стаканы	Юбилейный проспект, 47, Реутов, городской округ Реутов, Московская область	195
41	Провести влажную и сухую уборку	Уборка	Юбилейный проспект, 47, Реутов, городской округ Реутов, Московская область	197
42	Провести инвентаризацию 	Инвентаризация 	Носовихинское шоссе, 7, Реутов, городской округ Реутов, Московская область	198
43	Данные о недостаче, об отсутствии и об остатках 	Внести данные в систему	Носовихинское шоссе, 7, Реутов, городской округ Реутов, Московская область	199
48	Развесить украшения в баре в соответствии с дизайном, дизайн в документации 	Развесить украшения 	Юбилейный проспект, 47, Реутов, городской округ Реутов, Московская область	204
49	Полить растения	Полив 	Реутов, городской округ Реутов, Московская область	205
50	Покосить траву в парке	Покос	Железнодорожная улица, 9, Реутов, городской округ Реутов, Московская область	206
51	Спилить верхушки, которые угрожают безопасности. Пила у хоз рабочего	Спилить опасные верхушки деревьев 	Железнодорожная улица, 9, Реутов, городской округ Реутов, Московская область	207
53	Пересадить растения	Пересадка	Южная улица, 15, Реутов, городской округ Реутов, Московская область	209
54	Взять у хоз работника средства для обработки деревьев от тли 	Обработать деревья 	Юбилейный проспект, 29, Реутов, городской округ Реутов, Московская область	210
55	Выбрать фильмы для показа в баре	Выбрать фильмы	Юбилейный проспект, 47, Реутов, городской округ Реутов, Московская область	211
56	Наполнить баки водой в оранжерее 	Наполнить баки	село Ольгово, 66, Дмитровский городской округ, Московская область	213
57	Закрыть огурцы пленкой	Закрыть огурцы	село Ольгово, Дмитровский городской округ, Московская область	214
58	Подготовить мангал к барбекю: сменить угли	Подготовить мангал	село Ольгово, Дмитровский городской округ, Московская область	215
59	Повернуть хавортии и эчеверии	Повернуть растения	Южная улица, 15, Реутов, городской округ Реутов, Московская область	223
60	Убрать под крышу эхеверии и пахифитумы	Убрать растения под крышу 	Южная улица, 15, Реутов, городской округ Реутов, Московская область	224
74	Отредактировать текст в хедере на сайте 	Сделать описание на сайте	Южная улица, 15, Реутов, городской округ Реутов, Московская область	267
83	Провести инвентаризацию на складе 	Инвентаризация 	Юбилейный проспект, 30/2, Реутов, городской округ Реутов, Московская область	277
84	Данные о недостаче, об отсутствии и об остатках 	Внести данные в систему 	Юбилейный проспект, 30/2, Реутов, городской округ Реутов, Московская область	278
85	Провести инвентаризацию на складе 	Инвентаризация 	Юбилейный проспект, 30/2, Реутов, городской округ Реутов, Московская область	282
86	Данные о недостаче, об отсутствии и об остатках 	Внести данные в систему 	Юбилейный проспект, 30/2, Реутов, городской округ Реутов, Московская область	283
88	Забрать посылку на почте 143965	Забрать посылку	улица Октября, 2Б, Реутов, городской округ Реутов, Московская область	288
89	Проверка	Проверка	Южная улица, 15, Реутов, городской округ Реутов, Московская область	289
90	Доставить посылку по адресу, посылка в офисе	Доставить посылку	Южная улица, 15, Реутов, городской округ Реутов, Московская область	291
93	Провести инвентаризацию на складе 	Инвентаризация 	Юбилейный проспект, 30/2, Реутов, городской округ Реутов, Московская область	297
94	Данные о недостаче 	Внести данные в систему	Южная улица, 15, Реутов, городской округ Реутов, Московская область	298
95	Получить посылку на почте 	Получить посылку	улица Октября, 2Б, Реутов, городской округ Реутов, Московская область	302
96	Полить растения, у которых на вид просох грунт	Полить офисные растения	Столярный переулок, 3к6, Москва	305
\.


--
-- Data for Name: task_incident; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_incident (id, inicident_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: task_state_change; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_state_change (id, type_id, state_from_id, state_to_id) FROM stdin;
1	2	1	2
2	2	2	3
3	1	1	2
4	1	2	3
6	1	2	5
7	5	1	2
8	5	2	3
9	5	2	6
10	5	1	6
11	1	5	2
13	2	5	2
14	2	2	5
5	6	1	2
15	6	2	5
16	6	1	5
17	6	2	3
18	6	5	1
19	6	5	2
20	3	1	3
21	4	1	3
22	2	1	3
23	2	1	4
\.


--
-- Data for Name: task_state_change_for_boss; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_state_change_for_boss (id, type_id, state_from_id, state_to_id) FROM stdin;
1	6	1	6
2	6	1	4
4	6	5	4
3	6	2	3
5	6	5	6
6	6	7	6
7	2	1	3
8	2	1	4
\.


--
-- Data for Name: task_type; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_type (id, title, code) FROM stdin;
1	Заглушка	NOPE
2	Подтверждение времени выполнения	CONFIRM_LEAD_TIME
3	Начать рабочий день	START_WORK_DAY
4	Завершить рабочий день	END_WORK_DAY
5	Заполнить анкету	FILL_TASK_FORM
6	Задание	TASK
\.


--
-- Data for Name: tasks_flags; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.tasks_flags (id, task_id, flag_id) FROM stdin;
20	135	1
21	140	1
28	207	1
29	210	1
30	214	1
31	215	1
\.


--
-- Data for Name: tasks_state; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.tasks_state (id, title, code) FROM stdin;
1	Активно	ACTIVE
2	Выполняется	IN_PROGRESS
3	Завершено	DONE
4	Отменено	CANCELLED
5	Отложено	DELAYED
6	Удалено	DELETED
7	Ожидает назначения	AWAITING
\.


--
-- Data for Name: who_create_confirm_lead_time; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.who_create_confirm_lead_time (id, creater, task_id) FROM stdin;
23	Staff	268
24	Staff	279
25	Staff	284
26	Staff	294
27	Staff	299
\.


--
-- Name: awaiting_task_state_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.awaiting_task_state_id_seq', 2, true);


--
-- Name: awaiting_tasks_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.awaiting_tasks_id_seq', 66, true);


--
-- Name: boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.boss_id_seq', 1, true);


--
-- Name: boss_session_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.boss_session_id_seq', 6, true);


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.comments_id_seq', 9, true);


--
-- Name: flags_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.flags_id_seq', 1, true);


--
-- Name: question_group_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.question_group_id_seq', 2, true);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.questions_id_seq', 5, true);


--
-- Name: staff_answers_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_answers_id_seq', 42, true);


--
-- Name: staff_form_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_form_id_seq', 101, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_id_seq', 10, true);


--
-- Name: staff_session_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_session_id_seq', 27, true);


--
-- Name: staff_task_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_task_id_seq', 306, true);


--
-- Name: staff_to_boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_to_boss_id_seq', 9, true);


--
-- Name: task_content_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_content_id_seq', 96, true);


--
-- Name: task_incident_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_incident_id_seq', 1, false);


--
-- Name: task_state_change_for_boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_state_change_for_boss_id_seq', 8, true);


--
-- Name: task_state_change_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_state_change_id_seq', 8, true);


--
-- Name: task_type_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_type_id_seq', 3, true);


--
-- Name: tasks_flags_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.tasks_flags_id_seq', 32, true);


--
-- Name: tasks_state_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.tasks_state_id_seq', 1, true);


--
-- Name: who_create_confirm_lead_time_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.who_create_confirm_lead_time_id_seq', 27, true);


--
-- Name: boss boss_pk; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss
    ADD CONSTRAINT boss_pk PRIMARY KEY (id);


--
-- Name: boss_session boss_session_pk; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss_session
    ADD CONSTRAINT boss_session_pk PRIMARY KEY (id);


--
-- Name: boss boss_un; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss
    ADD CONSTRAINT boss_un UNIQUE (login);


--
-- Name: awaiting_task_state pk_awaiting_task_state_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_task_state
    ADD CONSTRAINT pk_awaiting_task_state_id PRIMARY KEY (id);


--
-- Name: awaiting_tasks pk_awaiting_tasks_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_tasks
    ADD CONSTRAINT pk_awaiting_tasks_id PRIMARY KEY (id);


--
-- Name: difficulty_level_to_practice pk_difficulty_level_to_practice_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.difficulty_level_to_practice
    ADD CONSTRAINT pk_difficulty_level_to_practice_id PRIMARY KEY (id);


--
-- Name: flags pk_flags_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.flags
    ADD CONSTRAINT pk_flags_id PRIMARY KEY (id);


--
-- Name: question_group pk_question_group_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.question_group
    ADD CONSTRAINT pk_question_group_id PRIMARY KEY (id);


--
-- Name: questions pk_questions_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.questions
    ADD CONSTRAINT pk_questions_id PRIMARY KEY (id);


--
-- Name: staff pk_staff_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff
    ADD CONSTRAINT pk_staff_id PRIMARY KEY (id);


--
-- Name: staff_session pk_staff_session_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_session
    ADD CONSTRAINT pk_staff_session_id PRIMARY KEY (id);


--
-- Name: staff_task pk_staff_task_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_task
    ADD CONSTRAINT pk_staff_task_id PRIMARY KEY (id);


--
-- Name: task_incident pk_task_incident_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_incident
    ADD CONSTRAINT pk_task_incident_id PRIMARY KEY (id);


--
-- Name: task_state_change pk_task_state_change_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change
    ADD CONSTRAINT pk_task_state_change_id PRIMARY KEY (id);


--
-- Name: task_type pk_task_type_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_type
    ADD CONSTRAINT pk_task_type_id PRIMARY KEY (id);


--
-- Name: tasks_flags pk_tasks_flags_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_flags
    ADD CONSTRAINT pk_tasks_flags_id PRIMARY KEY (id);


--
-- Name: tasks_state pk_tasks_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_state
    ADD CONSTRAINT pk_tasks_id PRIMARY KEY (id);


--
-- Name: staff_answers staff_answers_pkey; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_answers
    ADD CONSTRAINT staff_answers_pkey PRIMARY KEY (id);


--
-- Name: staff_form staff_form_pkey; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_form
    ADD CONSTRAINT staff_form_pkey PRIMARY KEY (id);


--
-- Name: task_content task_content_pkey; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_content
    ADD CONSTRAINT task_content_pkey PRIMARY KEY (id);


--
-- Name: questions unique_key_questions; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.questions
    ADD CONSTRAINT unique_key_questions UNIQUE (code);


--
-- Name: staff unique_login; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff
    ADD CONSTRAINT unique_login UNIQUE (login);


--
-- Name: fk_staff_task_staff; Type: INDEX; Schema: tasks; Owner: default
--

CREATE INDEX fk_staff_task_staff ON tasks.staff_task USING btree (staff_id);


--
-- Name: fk_staff_task_staff_task; Type: INDEX; Schema: tasks; Owner: default
--

CREATE INDEX fk_staff_task_staff_task ON tasks.staff_task USING btree (parent_id);


--
-- Name: fk_staff_task_task_type; Type: INDEX; Schema: tasks; Owner: default
--

CREATE INDEX fk_staff_task_task_type ON tasks.staff_task USING btree (type_id);


--
-- Name: fk_staff_task_tasks_state; Type: INDEX; Schema: tasks; Owner: default
--

CREATE INDEX fk_staff_task_tasks_state ON tasks.staff_task USING btree (state_id);


--
-- Name: fk_task_state_change; Type: INDEX; Schema: tasks; Owner: default
--

CREATE INDEX fk_task_state_change ON tasks.task_state_change USING btree (state_from_id);


--
-- Name: staff_task add_created_at; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER add_created_at BEFORE INSERT ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.add_created_at();


--
-- Name: staff_task add_finished_at; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER add_finished_at BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.add_finished_at();


--
-- Name: staff_task add_updated_at; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER add_updated_at BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.add_updated_at();


--
-- Name: staff_task check_for_active; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_active BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_active();


--
-- Name: staff_task check_for_cancel; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_cancel BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_cancel();


--
-- Name: staff_task check_for_change_state_from_delay_to_in_progress; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_change_state_from_delay_to_in_progress BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_change_state_from_delay_to_in_progress();


--
-- Name: staff_task check_for_delay; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_delay BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_delay();


--
-- Name: staff_task check_for_delay_sub_tasks; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_delay_sub_tasks BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_delay_sub_tasks();


--
-- Name: staff_task check_for_delete; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_delete BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_delete();


--
-- Name: staff_task check_for_lateness; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_lateness BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_lateness();


--
-- Name: staff_task started_at_update; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER started_at_update BEFORE UPDATE ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.add_started_at();


--
-- Name: boss_session boss_session_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss_session
    ADD CONSTRAINT boss_session_fk FOREIGN KEY (boss_id) REFERENCES tasks.boss(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: comments comments_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.comments
    ADD CONSTRAINT comments_fk FOREIGN KEY (staff_id) REFERENCES tasks.staff(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: comments comments_fk_1; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.comments
    ADD CONSTRAINT comments_fk_1 FOREIGN KEY (task_id) REFERENCES tasks.staff_task(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: awaiting_tasks fk_awaiting_tasks; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_tasks
    ADD CONSTRAINT fk_awaiting_tasks FOREIGN KEY (state_id) REFERENCES tasks.awaiting_task_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: awaiting_tasks fk_awaiting_tasks_staff; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_tasks
    ADD CONSTRAINT fk_awaiting_tasks_staff FOREIGN KEY (staff_id) REFERENCES tasks.staff(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: awaiting_tasks fk_awaiting_tasks_staff_task; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.awaiting_tasks
    ADD CONSTRAINT fk_awaiting_tasks_staff_task FOREIGN KEY (task_id) REFERENCES tasks.staff_task(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: questions fk_questions_question_group; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.questions
    ADD CONSTRAINT fk_questions_question_group FOREIGN KEY (group_id) REFERENCES tasks.question_group(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_session fk_staff_session_staff; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_session
    ADD CONSTRAINT fk_staff_session_staff FOREIGN KEY (staff_id) REFERENCES tasks.staff(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_task fk_staff_task_task_type; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_task
    ADD CONSTRAINT fk_staff_task_task_type FOREIGN KEY (type_id) REFERENCES tasks.task_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_task fk_staff_task_tasks_state; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_task
    ADD CONSTRAINT fk_staff_task_tasks_state FOREIGN KEY (state_id) REFERENCES tasks.tasks_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_state_change fk_task_state_change; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change
    ADD CONSTRAINT fk_task_state_change FOREIGN KEY (state_from_id) REFERENCES tasks.tasks_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_state_change fk_task_state_change_to; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change
    ADD CONSTRAINT fk_task_state_change_to FOREIGN KEY (state_to_id) REFERENCES tasks.tasks_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tasks_flags fk_tasks_flags_flags; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_flags
    ADD CONSTRAINT fk_tasks_flags_flags FOREIGN KEY (flag_id) REFERENCES tasks.flags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tasks_flags fk_tasks_flags_staff_task; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.tasks_flags
    ADD CONSTRAINT fk_tasks_flags_staff_task FOREIGN KEY (task_id) REFERENCES tasks.staff_task(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_answers staff_answers_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_answers
    ADD CONSTRAINT staff_answers_fk FOREIGN KEY (question_code) REFERENCES tasks.questions(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_form staff_form_fk_1; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_form
    ADD CONSTRAINT staff_form_fk_1 FOREIGN KEY (staff_id) REFERENCES tasks.staff(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_form staff_form_fk_2; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_form
    ADD CONSTRAINT staff_form_fk_2 FOREIGN KEY (group_id) REFERENCES tasks.question_group(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_to_boss staff_to_boss_boss_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_to_boss
    ADD CONSTRAINT staff_to_boss_boss_fk FOREIGN KEY (boss_id) REFERENCES tasks.boss(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: staff_to_boss staff_to_boss_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_to_boss
    ADD CONSTRAINT staff_to_boss_fk FOREIGN KEY (staff_id) REFERENCES tasks.staff(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_content task_content_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_content
    ADD CONSTRAINT task_content_fk FOREIGN KEY (task_id) REFERENCES tasks.staff_task(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_state_change_for_boss task_state_change_for_boss_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change_for_boss
    ADD CONSTRAINT task_state_change_for_boss_fk FOREIGN KEY (type_id) REFERENCES tasks.task_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_state_change_for_boss task_state_change_for_boss_fk_1; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change_for_boss
    ADD CONSTRAINT task_state_change_for_boss_fk_1 FOREIGN KEY (state_from_id) REFERENCES tasks.tasks_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: task_state_change_for_boss task_state_change_for_boss_fk_2; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.task_state_change_for_boss
    ADD CONSTRAINT task_state_change_for_boss_fk_2 FOREIGN KEY (state_to_id) REFERENCES tasks.tasks_state(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: who_create_confirm_lead_time who_create_confirm_lead_time_fk; Type: FK CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.who_create_confirm_lead_time
    ADD CONSTRAINT who_create_confirm_lead_time_fk FOREIGN KEY (task_id) REFERENCES tasks.staff_task(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

