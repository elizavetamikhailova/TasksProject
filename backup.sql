
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
		if new.state_id = 3 
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
		if old.state_id = 1 and new.state_id = 2 
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
48	139	3	2	2020-02-22 12:26:36.706498	2020-02-22 12:45:16.647245	\N
49	139	4	2	2020-02-22 12:26:36.710593	2020-02-22 12:45:16.647245	\N
50	139	5	2	2020-02-22 12:26:36.713072	2020-02-22 12:45:16.647245	\N
52	155	3	2	2020-02-23 21:05:10.789789	2020-02-23 21:08:56.621298	\N
53	155	5	2	2020-02-23 21:05:10.805099	2020-02-23 21:08:56.621298	\N
51	155	1	2	2020-02-23 21:05:10.781721	2020-02-23 21:08:56.621298	\N
\.


--
-- Data for Name: boss; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.boss (id, login, pass) FROM stdin;
1	Boss	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm
\.


--
-- Data for Name: boss_session; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.boss_session (id, device_code, auth_token, original_pass, expires_at, push_token, boss_id) FROM stdin;
1	1ce27d05ee3c5a48	йй	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	eSR6hg3ITSK7spdbg21Peh:APA91bEhw6yQC7ic1zZR9ol7ThPN8whCZ4pEmgunQzuD2B6i57ApLGGs7fMUhLnCCOe0tAH2ynpCeuQxFJKUjWbujxVlr3hxE7wLcwwyMbn4_Q33u273qWJOa2wRCKMY5eRL0fPOz4Fn	1
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.comments (id, staff_id, task_id, text, created_at, deleted_at) FROM stdin;
3	1	137	Личный кабинет и метрики пока отсутствуют, появятся в будущем 	2020-02-22 12:24:57.910618	\N
4	1	137	Авторизации и пушей тоже пока нет 😁	2020-02-22 12:25:19.029282	\N
5	1	136	Исследовательский раздел: краткая характеристика объекта исследования, определение места подсистемы в которую входят задачи ВКР (???), особенности проектруемой системы в сравнении с аналогичными, характеристика аналогов, оценка должна носить конкретный характер и даваться в количественных  характеристиках (вот тут вообще непонятно, какие количественные характеристики можно привести) 	2020-02-22 15:29:00.33514	\N
6	1	141	Уделите особое внимание одометру, возможно, он неверно перадет показания	2020-02-23 19:38:14.680322	\N
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
1	Liza	89160525834	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2019-12-08 11:31:57.259851	2019-12-08 11:31:57.259851	0001-01-01 00:00:00	\N
3	Ivan	89160525834	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2019-12-15 12:06:38.930063	2019-12-15 12:06:38.930063	0001-01-01 00:00:00	\N
4	Alexey	89160525834	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2019-12-15 12:06:50.847941	2019-12-15 12:06:50.847941	0001-01-01 00:00:00	\N
5	Dmitry 	7777777	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-02-22 12:17:46.285773	2020-02-22 12:17:46.285773	0001-01-01 00:00:00	\N
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
53	3	1	2020-01-05 11:26:12.030521	2020-01-05 11:26:12.030521	\N	98
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
77	5	2	2020-03-01 15:44:20.941061	2020-03-01 15:44:20.941061	\N	178
78	1	2	2020-03-01 17:59:16.442864	2020-03-01 17:59:16.442864	\N	181
\.


--
-- Data for Name: staff_session; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_session (id, device_code, auth_token, original_pass, expires_at, push_token, staff_id) FROM stdin;
3	 	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	 	1
5	 	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	 	3
6	 	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	 	4
7	 	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOjF9.Vcp2grZ53t_OG3jwSXsRwfc_UUjboNgZarkAGiX0jgM	$2a$10$yE2S3nc3O5ZJzNKYevhCKe.VMjDkaj6iWJmwHhqOnxMyarK/84rdm	2020-10-25T10:16:23.000Z	 	5
\.


--
-- Data for Name: staff_task; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_task (id, type_id, staff_id, state_id, parent_id, started_at, finished_at, created_at, updated_at, deleted_at, difficulty_level, expected_lead_time) FROM stdin;
181	5	1	1	180	\N	\N	2020-03-01 17:59:16.442864	2020-03-01 17:59:16.442864	\N	0	0
180	6	1	5	0	2020-03-01 17:59:00.241476	0001-01-01 00:00:00	2020-03-01 17:58:52.858054	2020-03-01 17:59:16.442864	\N	1	0
182	3	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-03-01 21:14:24.329363	2020-03-02 00:14:24.33046	\N	0	0
100	2	1	3	13	2019-12-25 12:04:20.638603	0001-01-01 00:00:00	2019-12-14 14:35:04.379662	2019-12-25 10:16:23	0001-01-01 00:00:00	1	2
69	5	1	3	38	\N	\N	2019-12-29 22:24:32.758245	2019-12-30 01:36:07.647289	\N	0	0
70	5	1	3	38	\N	\N	2019-12-29 22:26:26.0089	2019-12-30 01:37:48.688084	\N	0	0
71	5	1	3	38	\N	\N	2019-12-29 22:40:13.518956	2019-12-30 01:40:34.96518	\N	0	0
135	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:19:24.96143	2020-02-22 12:19:24.96143	\N	2	1
136	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:21:33.80168	2020-02-22 12:21:33.80168	\N	2	1
137	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:23:04.925219	2020-02-22 12:23:04.925219	\N	2	1
139	6	5	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 12:26:36.667513	2020-02-22 12:45:16.633145	\N	0	0
158	2	1	3	156	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-03-01 11:23:53.220331	2020-03-01 11:29:48.317538	\N	0	1
140	6	5	1	139	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-22 23:38:43.622857	2020-02-22 23:38:43.622857	\N	2	4
17	3	1	3	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2019-12-14 22:40:00.756795	2020-02-23 18:23:30.394881	0001-01-01 00:00:00	0	3
161	5	1	1	156	\N	\N	2020-03-01 08:35:11.161875	2020-03-01 08:35:11.161875	\N	0	0
162	5	1	1	157	\N	\N	2020-03-01 08:35:11.161875	2020-03-01 08:35:11.161875	\N	0	0
163	5	1	1	156	\N	\N	2020-03-01 08:35:29.042311	2020-03-01 08:35:29.042311	\N	0	0
164	5	1	1	157	\N	\N	2020-03-01 08:35:29.042311	2020-03-01 08:35:29.042311	\N	0	0
157	6	1	5	156	2020-03-01 08:24:59.526186	0001-01-01 00:00:00	2020-03-01 11:23:05.936595	2020-03-01 11:24:59.525888	\N	1	1
146	6	1	3	144	2020-02-23 17:20:40.195174	0001-01-01 00:00:00	2020-02-23 20:19:50.018075	2020-02-23 20:20:49.410727	\N	1	1
147	5	1	3	146	\N	\N	2020-02-23 17:20:49.410854	2020-02-23 20:21:07.802735	\N	0	0
156	6	1	5	0	2020-03-01 08:23:59.030648	0001-01-01 00:00:00	2020-03-01 11:22:08.066595	2020-03-01 11:35:29.042016	\N	2	3
145	6	1	3	144	2020-02-23 17:21:21.772677	0001-01-01 00:00:00	2020-02-23 20:18:31.104922	2020-02-23 20:21:30.654029	\N	3	1
148	5	1	3	145	\N	\N	2020-02-23 17:21:30.654203	2020-02-23 20:21:43.658222	\N	0	0
166	5	1	1	165	\N	\N	2020-03-01 10:05:47.811095	2020-03-01 10:05:47.811095	\N	0	0
144	6	1	3	0	2020-02-23 17:22:13.271307	0001-01-01 00:00:00	2020-02-23 20:17:05.394893	2020-02-23 20:22:17.113891	\N	3	1
149	5	1	3	144	\N	\N	2020-02-23 17:22:17.114065	2020-02-23 20:22:21.821248	\N	0	0
165	6	1	3	0	2020-03-01 09:59:30.991951	0001-01-01 00:00:00	2020-03-01 12:58:58.138267	2020-03-01 13:05:47.810722	\N	3	1
142	2	1	3	141	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-23 18:22:38.141967	2020-02-23 20:40:27.756684	\N	0	1
143	5	1	3	141	\N	\N	2020-02-23 16:48:11.993054	2020-02-23 20:40:43.231531	\N	0	0
141	6	1	3	0	2020-02-23 17:38:24.308845	0001-01-01 00:00:00	2020-02-23 18:15:09.414895	2020-02-23 20:41:03.265053	\N	1	2
150	5	1	3	141	\N	\N	2020-02-23 17:41:03.265217	2020-02-23 20:41:07.275521	\N	0	0
123	6	1	4	111	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-16 21:37:42.999192	2020-02-16 21:37:42.999192	\N	0	0
168	5	1	1	167	\N	\N	2020-03-01 10:07:52.710848	2020-03-01 10:07:52.710848	\N	0	0
167	6	1	3	0	2020-03-01 10:06:53.616717	0001-01-01 00:00:00	2020-03-01 13:06:18.934945	2020-03-01 13:07:52.710289	\N	1	1
155	6	1	4	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-23 21:05:10.736079	2020-02-23 21:09:47.699142	\N	4	2
170	5	1	3	169	\N	2020-03-01 10:25:03.566443	2020-03-01 10:24:36.313385	2020-03-01 13:25:03.564937	\N	0	0
171	5	1	3	169	\N	2020-03-01 10:25:32.267254	2020-03-01 10:25:28.268158	2020-03-01 13:25:32.266931	\N	0	0
169	6	1	3	0	2020-03-01 10:32:25.908369	2020-03-01 10:32:56.428043	2020-03-01 13:08:16.721937	2020-03-01 13:32:56.427481	\N	2	1
159	5	1	3	156	\N	\N	2020-03-01 08:24:05.152668	2020-03-01 11:24:31.169084	\N	0	0
172	5	1	3	169	\N	2020-03-01 10:34:20.654018	2020-03-01 10:32:56.428043	2020-03-01 13:34:20.653824	\N	0	0
175	5	1	3	174	\N	2020-03-01 11:08:35.117953	2020-03-01 11:08:24.90159	2020-03-01 11:08:35.117953	\N	0	0
174	6	1	3	0	2020-03-01 11:12:24.527933	2020-03-01 11:12:27.775001	2020-03-01 11:07:52.180515	2020-03-01 11:12:27.775001	\N	2	1
173	6	1	3	0	2020-03-01 11:05:27.958824	2020-03-01 11:12:45.688248	2020-03-01 14:05:11.377125	2020-03-01 11:12:45.688248	\N	2	4
160	5	1	1	157	\N	\N	2020-03-01 08:25:16.723148	2020-03-01 08:25:16.723148	\N	0	0
176	6	1	3	0	2020-03-01 11:13:23.246887	2020-03-01 12:33:09.677557	2020-03-01 11:13:16.155597	2020-03-01 12:33:09.677557	\N	1	1
177	5	1	3	176	\N	2020-03-01 12:33:16.06608	2020-03-01 12:33:09.677557	2020-03-01 12:33:16.06608	\N	0	0
138	6	5	5	137	2020-03-01 15:44:17.732542	0001-01-01 00:00:00	2020-02-22 12:24:33.191051	2020-03-01 15:44:20.941061	\N	3	1
178	5	5	3	138	\N	2020-03-01 15:44:47.269688	2020-03-01 15:44:20.941061	2020-03-01 15:44:47.269688	\N	0	0
179	6	1	2	0	2020-03-18 09:32:17.996965	0001-01-01 00:00:00	2020-03-01 17:58:52.077563	2020-03-18 09:32:17.996965	\N	1	0
\.


--
-- Data for Name: staff_to_boss; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_to_boss (id, staff_id, boss_id) FROM stdin;
1	1	1
2	3	1
3	4	1
4	5	1
\.


--
-- Data for Name: task_content; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_content (id, text, title, address, task_id) FROM stdin;
5	First task with content lalalalalalalallalalalalallala	First task	Laplndia	123
9	Прочитать первую главу, сделать рекомендации по написанию введения, Шамиль Гасангусейнович сказал добавить "что это, зачем нужно, в каких компаниях используется" 	Первая глава 	Где угодно 	135
10	Есть методичка(могу скинуть, потому что пока нет возможности добавления файлов), в ней есть не очень понятное описание, как, что и куда нужно делить: нужно подумать  над тем какие пункты и подпункты должна содержать ВКР, дать какие-то советы по содержанию	Структуризация 	Где угодно 	136
11	Рассмотреть имеющийся функционал, подумать над тем, что можно добавить 	Функционал приложения 	Где угодно 	137
12	Приложение для руководителей:В нижнем меню, если нажать на галочку появится поле "Метрики", сообщите, если есть предложения 	Метрики	Где угодно 	138
13	Тест	Тест 	Тест 	139
14	Тест тест тест 	Тест тест 	Южная, 15	140
15	Прибыть на точку осмотра тех.средств и провести осмотр, занести показания одометра и рефрижиранта в соответствующие формы	Осмотр транспортного средства	Москва, ул. Механическая, 47	141
16	Для автомобиля с номерным знаком А777АА заменить омывающую жидкость и проверить тормозные колодки	Провести тех. обслуживание 	Механическая, 47	144
17	Правая фара плохо светит, выяснить причину поломки	Проверить фары	Механическая 47	145
18	Провести проверку давления в шинах, подкачать, если потребуется 	Проверить давление в шинах	Механическая, 47	146
19	Помыть автомобиль с номерным знаком А777АА 	Помыть автомобиль	Механическая, 47	155
20	Тест 1 тест 1	Тест 1	Тест	156
21	Тест 	Тест	Тест 	157
22	Время время	Тест времени	Адрес 	165
23	Тест времени 2	Тест времени 1	Адрес 	167
24	Ттии	Тест времени 3	Нвоклеь	169
25	Рэ	Тест времени 5	Под	173
26	Талпд	Тест создания 	Плплдп	174
27	Тест	Проверка 1 час	Теси	176
28	Анкета 	Тест анкеты 	Олш	179
29	Анкета 	Тест анкеты 	Олш	180
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
22	141	1
23	142	1
24	155	1
25	158	1
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
-- Name: awaiting_task_state_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.awaiting_task_state_id_seq', 2, true);


--
-- Name: awaiting_tasks_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.awaiting_tasks_id_seq', 53, true);


--
-- Name: boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.boss_id_seq', 1, true);


--
-- Name: boss_session_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.boss_session_id_seq', 1, true);


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.comments_id_seq', 6, true);


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

SELECT pg_catalog.setval('tasks.staff_answers_id_seq', 25, true);


--
-- Name: staff_form_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_form_id_seq', 78, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_id_seq', 5, true);


--
-- Name: staff_session_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_session_id_seq', 7, true);


--
-- Name: staff_task_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_task_id_seq', 182, true);


--
-- Name: staff_to_boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_to_boss_id_seq', 4, true);


--
-- Name: task_content_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_content_id_seq', 29, true);


--
-- Name: task_incident_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_incident_id_seq', 1, false);


--
-- Name: task_state_change_for_boss_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_state_change_for_boss_id_seq', 6, true);


--
-- Name: task_state_change_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_state_change_id_seq', 7, true);


--
-- Name: task_type_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_type_id_seq', 3, true);


--
-- Name: tasks_flags_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.tasks_flags_id_seq', 25, true);


--
-- Name: tasks_state_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.tasks_state_id_seq', 1, true);


--
-- Name: boss boss_pk; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.boss
    ADD CONSTRAINT boss_pk PRIMARY KEY (id);


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
-- Name: staff_session unq_staff_session_staff_id; Type: CONSTRAINT; Schema: tasks; Owner: default
--

ALTER TABLE ONLY tasks.staff_session
    ADD CONSTRAINT unq_staff_session_staff_id UNIQUE (staff_id);


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
-- Name: staff_task check_for_end_work_day; Type: TRIGGER; Schema: tasks; Owner: default
--

CREATE TRIGGER check_for_end_work_day BEFORE INSERT ON tasks.staff_task FOR EACH ROW EXECUTE FUNCTION tasks.check_for_end_work_day();


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
-- PostgreSQL database dump complete
--

