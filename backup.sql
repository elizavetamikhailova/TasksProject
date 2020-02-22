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
-- Name: check_for_active(); Type: FUNCTION; Schema: tasks; Owner: default
--

CREATE FUNCTION tasks.check_for_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare new_task_id integer;
  begin
    if old.state_id = 5 and new.state_id = 1 and old.parent_id = 0
      then 
	  update tasks.staff_task set state_id = 1 where parent_id = old.id;
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
	  update tasks.staff_task set state_id = 2 where parent_id = old.id;
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
    if old.state_id = 2 and new.state_id = 5 
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
	  update tasks.staff_task set state_id = 5 where parent_id = old.id;
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
    pass_md5 character varying(8) NOT NULL,
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
    session_key character varying(100),
    auth_token character varying(255) NOT NULL,
    original_pass character varying(8) NOT NULL,
    expires_at character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
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
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.comments (id, staff_id, task_id, text, created_at, deleted_at) FROM stdin;
1	1	111	Памагити	2020-02-19 17:16:20.770635	\N
2	1	111	:(	2020-02-19 17:24:08.486826	\N
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
1	Liza	89160525834	123123	2019-12-08 11:31:57.259851	2019-12-08 11:31:57.259851	0001-01-01 00:00:00	\N
3	Ivan	89160525834	123123	2019-12-15 12:06:38.930063	2019-12-15 12:06:38.930063	0001-01-01 00:00:00	\N
4	Alexey	89160525834	123123	2019-12-15 12:06:50.847941	2019-12-15 12:06:50.847941	0001-01-01 00:00:00	\N
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
\.


--
-- Data for Name: staff_session; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_session (id, device_code, session_key, auth_token, original_pass, expires_at, created_at, updated_at, deleted_at, push_token, staff_id) FROM stdin;
\.


--
-- Data for Name: staff_task; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.staff_task (id, type_id, staff_id, state_id, parent_id, started_at, finished_at, created_at, updated_at, deleted_at, difficulty_level, expected_lead_time) FROM stdin;
112	6	3	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-01-05 17:39:06.093371	2020-01-05 17:39:06.093371	\N	6	5
113	6	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-01-05 17:46:25.349114	2020-01-05 17:46:25.349114	\N	6	5
114	6	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-15 13:49:32.594042	2020-02-15 13:49:32.594042	\N	3	5
123	6	1	5	111	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-16 21:37:42.999192	2020-02-16 21:37:42.999192	\N	0	0
111	6	1	5	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-01-05 17:29:38.714363	2020-02-16 21:58:59.221945	\N	6	5
124	4	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-18 17:15:35.119008	2020-02-18 17:15:35.119008	\N	0	0
125	4	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-16 21:37:42	2020-02-16 21:37:42	\N	0	0
126	4	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-16 21:37:42	2020-02-16 21:37:42	\N	0	0
17	3	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2019-12-14 22:40:00.756795	2019-12-14 22:40:00.756795	0001-01-01 00:00:00	0	3
127	4	1	1	0	0001-01-01 00:00:00	0001-01-01 00:00:00	2020-02-16 21:37:42	2020-02-16 21:37:42	\N	0	0
69	5	1	3	38	\N	\N	2019-12-29 22:24:32.758245	2019-12-30 01:36:07.647289	\N	0	0
70	5	1	3	38	\N	\N	2019-12-29 22:26:26.0089	2019-12-30 01:37:48.688084	\N	0	0
71	5	1	3	38	\N	\N	2019-12-29 22:40:13.518956	2019-12-30 01:40:34.96518	\N	0	0
100	2	1	2	13	2019-12-25 12:04:20.638603	0001-01-01 00:00:00	2019-12-14 14:35:04.379662	2019-12-25 10:16:23	0001-01-01 00:00:00	1	2
13	2	1	2	0	2019-12-25 12:04:20.638603	0001-01-01 00:00:00	2019-12-14 14:35:04.379662	2020-01-05 14:48:34.691434	0001-01-01 00:00:00	1	2
\.


--
-- Data for Name: task_content; Type: TABLE DATA; Schema: tasks; Owner: default
--

COPY tasks.task_content (id, text, title, address, task_id) FROM stdin;
1	First task with content lalalalalalalallalalalalallala	First task	Laplndia	111
2	Second task with content lalalalalalalallalalalalallala	Second task	Laplndia	112
3	Task with content lalalalalalalallalalalalallala	Task	Laplndia	113
4	Покататься на сноуборде по всем трассам 	Сноуборд 	Хибины	114
5	First task with content lalalalalalalallalalalalallala	First task	Laplndia	123
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
14	111	1
15	112	1
16	113	1
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

SELECT pg_catalog.setval('tasks.awaiting_tasks_id_seq', 37, true);


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.comments_id_seq', 2, true);


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

SELECT pg_catalog.setval('tasks.staff_answers_id_seq', 9, true);


--
-- Name: staff_form_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_form_id_seq', 58, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_id_seq', 4, true);


--
-- Name: staff_session_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_session_id_seq', 1, false);


--
-- Name: staff_task_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.staff_task_id_seq', 131, true);


--
-- Name: task_content_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.task_content_id_seq', 5, true);


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

SELECT pg_catalog.setval('tasks.tasks_flags_id_seq', 16, true);


--
-- Name: tasks_state_id_seq; Type: SEQUENCE SET; Schema: tasks; Owner: default
--

SELECT pg_catalog.setval('tasks.tasks_state_id_seq', 1, true);


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

