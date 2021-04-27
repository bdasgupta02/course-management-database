--q1 add_employee
create or replace procedure add_employee(ename char(20), addr char(100), num char(20), 
    email char(100), salary_info text, salary real, join_date date, category text, 
    course_areas_array char(100)[]) 
    as $$
declare
    course_area char(100);
    eid integer;
begin
    if category = 'administrator' then
        if array_length(course_areas_array, 1) = 0 then
            insert into Employees(name, address, email, phone, join_date) 
            values (ename, addr, email, num, join_date);
            select currval(pg_get_serial_sequence('Employees', 'eid')) into eid;
            insert into Full_time_Emp values (eid, salary);
            insert into Administrators values (eid);
        end if;
        -- there is course area for admin
        raise exception 'Course areas should not be specified for admins.';
    else
        if array_length(course_areas_array, 1) <> 0 
        and (category = 'manager' or (category = 'instructor'
        and (salary_info = 'full time' or salary_info = 'part time'))) then
            foreach course_area in array course_areas_array loop
                if not exists (select * from Course_areas where name = course_area) then
                    raise exception 'Invalid course area.';
                end if;
            end loop;
            insert into Employees (name, address, email, phone, join_date) 
            values (ename, addr, email, num, join_date);
            select currval(pg_get_serial_sequence('Employees', 'eid')) into eid;
            if category = 'manager' then
                insert into Full_time_Emp values (eid, salary);
                insert into Managers values (eid);
            end if;
            if category = 'instructor' then
                if salary_info = 'part time' then
                    insert into Part_time_Emp values (eid, salary);
                    insert into Instructors values (eid);
                    insert into Part_time_instructors values (eid);
                else 
                -- full time
                    insert into Full_time_Emp values (eid, salary);
                    insert into Instructors values (eid);
                    insert into Full_time_instructors values (eid);
                end if;
                foreach course_area in array course_areas_array loop
                    insert into Specializes
                    select eid, course_area;
                end loop;
            end if;
        end if;
        -- no course areas for manager or instructor, or category is invalid
    end if;
end;
$$ language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------
--q2 remove_employee

CREATE OR REPLACE PROCEDURE remove_employee(IN input_eid int, IN departure_date date)
AS $$
BEGIN
        UPDATE Employees SET depart_date = input_departure_date WHERE eid = input_eid;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_employee_trigger ()
    RETURNS TRIGGER
    AS $$
BEGIN
    IF (EXISTS (
        SELECT 1 FROM Offerings WHERE eid = NEW.eid AND registration_deadline > NEW.depart_date) OR
        EXISTS (SELECT 1 FROM Sessions WHERE eid = NEW.eid AND session_date > NEW.depart_date) OR
        EXISTS (SELECT 1 FROM Course_areas WHERE eid = NEW.eid)) THEN
        RETURN NULL;
    ELSE
        OLD.depart_date := NEW.depart_date;
        RETURN OLD;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER remove_employee_trigger
    BEFORE UPDATE ON Employees
    FOR EACH ROW
    EXECUTE FUNCTION remove_employee_trigger();


-------------------------------------------------------------------------------------------------------------------------------

--q3 add_customer
create or replace procedure add_customer(name char(100), home_addr char(100), contact_num char(20),
    email char(100), cc_num bigint, cc_expiry date, cc_cvv integer)
as $$
begin
    insert into Customers(name, address, phone, email) values
    (name, home_addr, contact_num, email);
    insert into Credit_cards(number, expiry_date, CVV) values
    (cc_num, cc_expiry, cc_cvv);
    insert into Owns(number, cust_id, from_date) values
    (cc_num,
    nextval(pg_get_serial_sequence('Customers', 'cust_id')),
    current_date);
end;
$$ language plpgsql;

------------------------------------------------------------------------------------------------------------------------------

-- q4 update_credit_card
CREATE OR REPLACE PROCEDURE update_credit_card(customer_id INT, new_num BIGINT, new_expiry DATE, new_CVV INT)
AS $$
	DECLARE
		old_num BIGINT;
	BEGIN
		IF new_expiry < CURRENT_DATE THEN
			RAISE EXCEPTION 'Your card has expired!';
		END IF;
	
		SELECT number INTO old_num
		FROM Owns
		WHERE cust_id=customer_id;

		UPDATE Credit_cards
		SET number=new_num,
				expiry_date=new_expiry,
				CVV=new_cvv
		WHERE number=old_num;

		UPDATE Owns
		SET from_date=CURRENT_DATE
		WHERE number=new_num;
	END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

--q5 add_course
create or replace procedure add_course(title char(20), descriptn char(100), 
    course_area char(100), duration integer) 
    as $$
begin
    if exists (select name from Course_areas where name = course_area) then
        insert into Courses(title, description, duration, name) 
        select title, descriptn, duration, course_area;
    else
        raise exception 'Invalid course area.';
    end if;
end;
$$ language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------
--q6 find_instructors
CREATE OR REPLACE FUNCTION find_instructors (
        IN input_course_id int,
        IN input_session_date date,
        IN input_start_time time
    ) RETURNS TABLE (eid int, name char) AS $$
DECLARE
curs CURSOR FOR (
        SELECT I.eid, E.name
        FROM Instructors I NATURAL JOIN Employees E
    );
r RECORD;
curr_spec_name name;
BEGIN OPEN curs;
LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;
        SELECT C.name INTO curr_spec_name
        FROM Sessions S NATURAL JOIN Courses C
        WHERE course_id = input_course_id;
IF NOT EXISTS (
    SELECT 1
    FROM Sessions S
    WHERE S.eid = r.eid
        AND S.course_id = input_course_id
        AND S.session_date = input_session_date
        AND input_start_time BETWEEN S.start_time AND S.end_time + INTERVAL '1 HOUR'
)
AND EXISTS (
    SELECT 1
    FROM Specializes S
    WHERE S.name = curr_spec_name
        AND S.eid = r.eid
) THEN eid := r.eid;
name := r.name;
RETURN NEXT;
END IF;
END LOOP;
CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

--q7 get_available_instructors
-- Assumptions:
-- 1. Sessions are all valid tuples according to problem contraints
-- 2. If an employee is in Specializes, he/she is an instructor
create or replace function get_available_instructors(id_course integer, date_start date, date_end date)
returns table(eid integer, name char(100), num_hours integer, day date, hours integer[])
as $$
begin
    return query
    with Specializers as(
        select A.eid, E.name
        from
        (select distinct S.eid
            from Specializes S
            where S.name in (select C.name from Courses C where C.course_id = id_course)) A,
        Employees E
        where A.eid = E.eid),
    with_num_hours as(
        select Sp.eid, Sp.name, coalesce(sum(duration)::integer, 0) as num_hours
        from Specializers Sp left join
        (select S.eid, S.session_date, extract(hour from (S.end_time - S.start_time)) as duration
        from Sessions S) Se on
        Sp.eid = Se.eid
        and extract(month from Se.session_date) = extract(month from current_date)
        group by Sp.eid, Sp.name),
    possibilities as(
        select W.eid, W.name, W.num_hours, D.day, array[9, 10, 11, 14, 15, 16, 17] as hours
        from with_num_hours W,
        -- exclude weekends
        (select Dates.day::date from generate_series(date_start, date_end, '1 day') Dates(day)
            where extract('isodow' from Dates.day) < 6) D
        -- exclude part time instructors with hours more than 30
        where W.eid not in (select P.eid from Part_time_instructors P
            where P.eid = W.eid and W.num_hours >= 30)),
    hours_busy as(
        select S.eid, S.session_date as busy_date,
        (select array(
            -- 9,10,11,12 extracted from a session of 10-12 to cater 1 hour break
            select generate_series(extract(hour from S.start_time)::integer - 1,
                extract(hour from S.end_time)::integer, 1))) as hours
        from Sessions S),
    all_hours_busy_per_day as(
        select distinct H1.eid, H1.busy_date,
        (select array_agg(aa.hour) from (select unnest(H2.hours) from hours_busy H2
                where H1.eid = H2.eid and H1.busy_date = H2.busy_date) aa(hour)) as all_hours
        from hours_busy H1)
    select P.eid, P.name, P.num_hours::integer, P.day,
    (select array_agg(e order by e) from (select unnest(P.hours) except
            select unnest(x.hours) from (select all_hours from all_hours_busy_per_day A
                    where A.eid = P.eid and A.busy_date = P.day) x(hours)) t(e)) as hours
    from possibilities P
    order by P.eid, P.day;
end;
$$ language plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

-- q8 find_rooms
CREATE OR REPLACE FUNCTION find_rooms(search_date DATE, start_hour TIME, duration_hours INT)
RETURNS TABLE(rid INT) AS $$
DECLARE
	added_duration_time TIME;
	duration_string TEXT;
BEGIN
	duration_string := duration_hours::TEXT || ' hour';
	added_duration_time := start_hour + duration_string::INTERVAL;
	
	RETURN QUERY
	SELECT R1.rid FROM Rooms R1
	EXCEPT
	SELECT R2.rid   
	FROM Sessions S
	NATURAL JOIN Rooms R2 
	WHERE S.session_date=search_date 
	AND (S.start_time, S.end_time) OVERLAPS (start_hour, added_duration_time);
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

--q9 get_available_rooms
--range of hours given as per 24h clock
--assume that a room is not available from 12-2 according to session constraints
create or replace function get_available_rooms(start_date date, end_date date)
returns table (room_id int, capacity integer, day date, hours int[])
as $$
declare
    session_curs cursor for (
        select R.rid, R.seating_capacity, S.session_date, S.start_time, S.end_time
        from Rooms R left join Sessions S on R.rid = S.rid
        where S.session_date <= end_date and S.session_date >= start_date 
        order by R.rid, S.session_date, S.start_time);
    r record;
begin
    DROP TABLE IF EXISTS rooms_all_timings CASCADE;
    create temp table rooms_all_timings as (
        select rid, seating_capacity, d::date, array[9, 10, 11, 2, 3, 4, 5] as timing
        from Rooms, generate_series(start_date, end_date, '1 day') as d
        order by rid, d
    );
    open session_curs;
    loop
        fetch session_curs into r;
        exit when not found;
        update rooms_all_timings
        set timing = array_cat(
            coalesce(timing[1:array_position(timing, extract(hour from r.start_time)::int)-1],array[]::integer[]),
            coalesce(timing[array_position(timing, extract(hour from r.end_time)::int):],array[]::integer[]))
        where rid = r.rid and d = r.session_date;
    end loop;
    close session_curs;
    return query select * from rooms_all_timings order by rid, d;
end;
$$ language plpgsql;

------------------------------------------------------------------------------------------------------------------------------

-- q10 add_course_offering
-- multiple sessions in the char 2d array
-- better to have a 2d array for organization than 3 different type 1d arrays for sessions
-- in sessions 2d array, [x][1] is the session date, [x][2] is the session start time and [x][3] is the room id, in char form
CREATE OR REPLACE PROCEDURE add_course_offering(id_course INT, date_launch DATE, fees NUMERIC(10,2), deadline_registration DATE, target_registrations INT, eid_admin INT, sessions CHAR(20)[][])
AS $$
DECLARE
	one_session CHAR(20)[];
	id_session INT;
	iterations INT;
	course_duration INT;
	course_duration_interval INTERVAL;
	hour_end TIME;
	
	-- converted values to extra from one_session
	date_session DATE;
	hour_start TIME;
	id_room INT;

	-- first and last dates for offering table
	first_date DATE;
	last_date DATE;

	-- instructor and room details per session
	id_instructor INT;
	room_capacity INT;

	-- checking offerings insertion
	offerings_added BOOLEAN;

	-- capacity counter
	total_capacity INT;
BEGIN
	iterations := 0;
	SELECT duration INTO course_duration FROM Courses WHERE course_id=id_course LIMIT 1;
	course_duration_interval := (course_duration::TEXT || ' hours')::INTERVAL;
	offerings_added := false;
	total_capacity := 0;
	FOREACH one_session SLICE 1 IN ARRAY sessions
	LOOP
		-- extra data first
		date_session := one_session[1]::DATE;
		hour_start := one_session[2]::TIME;
		id_room := one_session[3]::INT;
		iterations := iterations + 1;
		
		-- changing first and last dates
		IF iterations = 1 THEN
			first_date := date_session;
			last_date := date_session;
		ELSE
			IF date_session < first_date THEN
				first_date := date_session;
			END IF;
			IF date_session > last_date THEN
				last_date := date_session;
			END IF;
		END IF;

		-- setting capacity and instructor
		id_instructor := NULL; 
		SELECT eid
		INTO id_instructor
		FROM get_available_instructors(id_course, date_session, date_session)
		LIMIT 1;
		room_capacity := NULL;
		SELECT capacity
		INTO room_capacity
		FROM get_available_rooms(date_session, date_session)
		WHERE room_id=id_room
		LIMIT 1;

		-- check for instructors and rooms and creating session if it passes conditions
		IF id_instructor = NULL THEN
			RAISE NOTICE 'No instructors are available! Creation of course session date % and time % was skipped.', date_session, hour_start;
			CONTINUE;
		ELSIF room_capacity = NULL THEN
			RAISE NOTICE 'No rooms are available! Creation of course session date % and time % was skipped.', date_session, hour_start;
			CONTINUE;
		ELSE
			id_session := (SELECT MAX(sid) FROM Sessions S) + 1;
			hour_end := hour_start + course_duration_interval;
			IF offerings_added=false AND deadline_registration >= date_launch THEN
				INSERT INTO Offerings VALUES (date_launch, id_course, first_date, last_date, deadline_registration, target_registrations, fees, 0, eid_admin);
				total_capacity := total_capacity + room_capacity;
				INSERT INTO Sessions VALUES (id_session, hour_start, hour_end, date_session, date_launch, id_course, id_room, id_instructor);
				offerings_added := true;
			ELSIF offerings_added THEN
				total_capacity := total_capacity + room_capacity;
				INSERT INTO Sessions VALUES (id_session, hour_start, hour_end, date_session, date_launch, id_course, id_room, id_instructor);
			END IF;
		END IF;

		-- nullifying values for check later
		id_instructor := NULL;
		room_capacity := NULL;
	END LOOP;
		
	IF total_capacity>=target_registrations THEN
		UPDATE Offerings 
		SET start_date=first_date,
				end_date=last_date,
				seating_capacity=total_capacity
		WHERE launch_date=date_launch AND course_id=id_course;		
	ELSE
		DELETE FROM Offerings
		WHERE launch_date=date_launch AND course_id=id_course;	
		RAISE EXCEPTION 'No offering was added because you have not added enough sessions to meet the target registration numbers.';
	END IF;
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

--q11 add_course_package
create or replace procedure add_course_package(pname char(100), free_sessions integer, date_start date,
    date_end date, pprice numeric(10,2))
as $$
begin
    -- check conditions
    if free_sessions <= 0 then
        raise exception 'Number of free course sessions must be a positive integer!';
    elsif date_start > date_end then
        raise exception 'Start date cannot be after end date!';
    elsif date_end <= current_date then
        raise exception 'End date cannot be today or before today!';
    elsif pprice <= 0 then
        raise exception 'Price cannot be negative!';
    end if;
    
    insert into Course_packages(package_id, name, num_free_registrations,
        sale_start_date, sale_end_date, price) values
        (nextval(pg_get_serial_sequence('Course_packages', 'package_id')),
            pname, free_sessions, date_start, date_end, pprice);
end;
$$ language plpgsql;

--------------------------------------------------------------------------------------------------------------------

-- q12 get_available_course_packages
CREATE OR REPLACE FUNCTION get_available_course_packages(OUT package_name TEXT, OUT num_registrations INT, OUT end_date DATE, OUT package_price NUMERIC(10,2))
RETURNS SETOF RECORD AS $$
	BEGIN
		SELECT name, num_free_registrations, sale_end_date, price
		INTO package_name, num_registrations, end_date, package_price 
		FROM Course_packages
		WHERE sale_start_date <= CURRENT_DATE AND sale_end_date >= CURRENT_DATE;
	END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------------------------------

--q13 buy_course_package
create or replace procedure buy_course_package(customer_id int, coursepackage_id int)
as $$
begin
    -- no other package with more than 0 redemptions or partially active
    if not exists (select B.package_id
    from Buys B natural left join Redeems R natural left join Sessions S
        where B.cust_id = customer_id 
        and (B.num_remaining_redemptions > 0
            or (B.num_remaining_redemptions = 0 
                and current_date + interval '7 days' <= S.session_date)))
    -- check valid sale date
    and exists (select package_id 
        from Course_packages
        where package_id = coursepackage_id and current_date >= sale_start_date 
        and current_date <= sale_end_date)
    then
        insert into Buys
        select current_date, 
            (select num_free_registrations from Course_packages 
            where package_id = coursepackage_id),
            coursepackage_id,
            number, cust_id
        -- check if there is credit card
        from Owns
        where cust_id = customer_id;
    else
        raise exception 'Some other package with more than 0 redemptions or partially active
        or invalid sale date.';
    end if;
end;
$$ language plpgsql;

-----------------------------------------------------------------------------------------------------------------------

--q14 get_my_course_package
CREATE OR REPLACE FUNCTION get_my_course_package(customer_id int)
RETURNS JSON
AS $$
DECLARE
        package_name CHAR(500);
        result_date DATE;
        result_price NUMERIC;
        num_free_sess INT;
        num_unredeemed INT;
        redeemed_arr TEXT[];
        pid INT;

BEGIN
        SELECT P.name, B.buy_date, P.price, P.num_free_registrations,
            B.num_remaining_redemptions, P.package_id
        INTO package_name, result_date, result_price, num_free_sess, num_unredeemed, pid
        FROM (((Buys B NATURAL LEFT JOIN Course_packages P) NATURAL LEFT JOIN Redeems R)
                NATURAL JOIN Sessions S)
        WHERE B.cust_id = customer_id
        AND (B.num_remaining_redemptions > 0
            OR (B.num_remaining_redemptions = 0
                AND current_date + interval '7 days' <= S.session_date));

        redeemed_arr := ARRAY(
                SELECT ROW(C.title, S.session_date, S.start_time)
                FROM Courses C NATURAL JOIN Sessions S NATURAL JOIN Redeems R
                WHERE R.cust_id = customer_id AND R.package_id = pid
                ORDER BY S.session_date, S.start_time
        );
        RETURN json_build_object(
                'package_name', package_name,
                'purchase_date', result_date,
                'price', result_price,
                'num_free_sessions', num_free_sess,
                'num_unredeemed_session', num_unredeemed,
                'redeemed_sessions', redeemed_arr
        );

end;
$$ language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

--q15 get_available_course_offerings
-- Assumptions:
-- 1. all tuples in Registers and Redeems are valid and each tuple represents one registration
-- 2. all Offerings have a valid entry in Courses i.e course id in Offerings is in Courses
create or replace function get_available_course_offerings()
returns table(c_title char(100), c_area char(100), date_start date, date_end date,
    reg_deadline date, c_fees numeric(10,2), remain_seats integer)
as $$
begin
    return query
    with valid_offerings as(
        select O1.launch_date, O1.course_id, O1.start_date, O1.end_date, O1.registration_deadline,
        O1.fees, O1.seating_capacity
        from Offerings O1
        where O1.end_date > current_date
        and O1.registration_deadline >= current_date
        and O1.launch_date <= current_date),
    num_regis_per_offering as(
        select VO.launch_date, VO.course_id, count(*) as number_regis
        from valid_offerings VO, Registers R
        where VO.launch_date = R.launch_date and VO.course_id = R.course_id
        group by VO.launch_date, VO.course_id),
    num_redem_per_offering as(
        select VO.launch_date, VO.course_id, count(*) as number_regis
        from valid_offerings VO, Redeems R
        where VO.launch_date = R.launch_date and VO.course_id = R.course_id
        group by VO.launch_date, VO.course_id),
    num_total_regis as(
        select N.launch_date, N.course_id, sum(N.number_regis) as total_regis_count
        from (select * from num_regis_per_offering union all select * from num_redem_per_offering) N
        group by N.launch_date, N.course_id)
    select C.title, C.name, O.start_date, O.end_date, O.registration_deadline, O.fees,
    case when total_regis_count is null then O.seating_capacity
    else (O.seating_capacity - total_regis_count)::integer end as remaining_seats
    from (valid_offerings O join Courses C on O.course_id = C.course_id)
    left join num_total_regis N on O.launch_date = N.launch_date and O.course_id = N.course_id
    and O.seating_capacity > N.total_regis_count;
end;
$$ language plpgsql;

--------------------------------------------------------------------------------------------------------------------

-- q16 get_available_course_sessions
CREATE OR REPLACE FUNCTION get_available_course_sessions(IN offering_launch DATE, IN id_course INT, OUT date_session DATE, OUT start_hour TIME, OUT instr_name TEXT, OUT seats INT)
RETURNS SETOF RECORD AS $$
	DECLARE
		seats_registered INT;
		seats_redeemed INT;
		curs CURSOR FOR (SELECT * 
			FROM Sessions S 
			JOIN Offerings O ON S.launch_date=O.launch_date AND S.course_id=O.course_id
			JOIN Employees E ON S.eid=E.eid
			JOIN Rooms R ON S.rid=R.rid
			WHERE O.course_id=id_course AND O.launch_date=offering_launch);
		r RECORD;
	BEGIN
		OPEN curs;
		LOOP
			FETCH curs INTO r;
			EXIT WHEN NOT FOUND;
			SELECT COUNT(*) INTO seats_registered FROM Registers Reg WHERE Reg.sid = r.sid;
			SELECT COUNT(*) INTO seats_redeemed FROM Redeems Red WHERE Red.sid = r.sid;
			IF r.seating_capacity > (seats_registered + seats_redeemed) AND r.registration_deadline >= CURRENT_DATE THEN
				date_session := r.session_date;
				start_hour := r.start_time;
				instr_name := r.name;
				seats := r.seating_capacity - (seats_registered + seats_redeemed);
				RETURN NEXT;
			END IF;
		END LOOP;
		CLOSE curs;
	END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------

--q17 register_session
--assume course offering identifier includes launch date and course id
create or replace procedure register_session(customer_id int, offering_launch_date date,
    offering_course_id int, session_number int, payment text) as $$
declare
    count_of_registrations int;
    count_of_redemptions int;
    seating_cap int;
    sessions_registered int;
    sessions_redeemed int;
    deadline_not_passed int;
    cc_num int;
begin
    -- no other sessions registered in the course offering
    select count(sid) from Registers R
    into sessions_registered
    where R.cust_id = customer_id
    and R.launch_date = offering_launch_date and R.course_id = offering_course_id;
    select count(sid) from Redeems
    into sessions_redeemed
    where cust_id = customer_id
    and launch_date = offering_launch_date and course_id = offering_course_id;
    -- registration deadline not passed
    select count(*) from Offerings O
    into deadline_not_passed
    where O.launch_date = offering_launch_date and O.course_id = offering_course_id
    and O.registration_deadline >= current_date;
    -- seating capacity not over, count sess registration vs rm limit
    select count(*)
    into count_of_registrations
    from Registers R
    where R.sid = session_number 
    and R.launch_date = offering_launch_date and R.course_id = offering_course_id;
    select count(*)
    into count_of_redemptions
    from Redeems
    where sid = session_number 
    and launch_date = offering_launch_date and course_id = offering_course_id;

    select distinct Ro.seating_capacity
    into seating_cap
    from Registers R natural join Sessions S natural join Rooms Ro
    where S.sid = session_number 
    and S.launch_date = offering_launch_date and S.course_id = offering_course_id;
    -- customer has credit card
    select count(number) into cc_num from Owns where cust_id = customer_id;

    if sessions_registered + sessions_redeemed = 0
    and deadline_not_passed > 0
    and count_of_registrations + count_of_redemptions < seating_cap 
    and cc_num > 0 then
        if payment = 'card' then
            insert into Registers
            select current_date, number, customer_id, session_number, 
                offering_launch_date, offering_course_id
            from Owns
            where cust_id = customer_id;
        else
            -- if redeeming, check if has package
            if payment = 'redeem' then
                insert into Redeems
                select current_date, session_number, offering_launch_date,
                offering_course_id, buy_date, package_id, cust_id, number
                from Buys 
                where cust_id = customer_id
                and exists (
                    select 1 from Buys
                    where cust_id = customer_id and num_remaining_redemptions > 0)
                and num_remaining_redemptions > 0;
            else 
                raise notice 'Payment must be card or redeem.';
            end if;
        end if;
    else 
        if sessions_registered + sessions_redeemed > 0 then
            raise notice 'Already registered for a session in the offering.';
        end if;
        if deadline_not_passed = 0 then
            raise notice 'Offering registration date has passed or no such offering.';
        end if;
        if count_of_registrations + count_of_redemptions = seating_cap then
            raise notice 'Seating capacity for session is full.';
        end if;
    end if;
end;
$$ language plpgsql;
-------------------------------------------------------------------------------------------------------------------------------
--q18 get_my_registrations
CREATE OR REPLACE FUNCTION get_my_registrations (IN cust_id int) RETURNS TABLE (
        title char,
        fees numeric,
        session_date date,
        session_start_hour time,
        session_duration time,
        instructor_name char
    ) AS $$
DECLARE curs CURSOR FOR (
        SELECT *
        FROM Registers
            NATURAL JOIN Sessions
            NATURAL JOIN Instructors
        ORDER BY session_date,
            session_start_hour
    );
r RECORD;
BEGIN
        OPEN curs;
        LOOP
                FETCH curs INTO r;
                EXIT WHEN NOT FOUND;
                        IF r.cust_id = cust_id AND (now() < r.session_date OR (now() = r.session_date AND now()::time < r.end_time)) THEN
                        title := (SELECT DISTINCT C.title FROM Courses C WHERE course_id = r.course_id);
                        fees := (SELECT DISTINCT O.fees FROM Offerings O WHERE course_id = r.course_id);
                        session_date := r.session_date;
                        session_start_hour := r.start_time;
                        session_duration := r.end_time - r.start_time;
                        instructor_name := (SELECT DISTINCT E.name FROM Employees E where eid = r.eid);
                        RETURN NEXT;
                        END IF;
        END LOOP;
        CLOSE curs;
        RETURN;
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

--q19 update_course_session
-- Assumption:
-- 1. only one entry either in Registers or Redeems (constraint that Customers can
    -- only register for at most 1 session from a specific course Offering)
-- 2. user do not call this procedure with the session number that customer 
    -- is already registered with
create or replace procedure update_course_session(id_cust integer, date_launch date,
    id_course integer, ses_num integer)
as $$
begin
    create temp table if not exists RR as(
        select R1.launch_date, R1.course_id, R1.sid, R1.cust_id
        from Registers R1
        union
        select R2.launch_date, R2.course_id, R2.sid, R2.cust_id
        from Redeems R2);
    -- check that course offering does not exist in Register or Redeems for this customer
    -- i.e. customer did not register for any session in this course offering
    if not exists(select 1 from RR RR1 where RR1.cust_id = id_cust
            and RR1.launch_date = date_launch and RR1.course_id = id_course) then
        raise exception 'Customer did not register for a session in the specified course offering!';
    -- check if customer registered for a session in Registers
    elsif exists(select 1 from Registers Rg1 where Rg1.cust_id = id_cust
        and Rg1.launch_date = date_launch and Rg1.course_id = id_course) then
        -- check if session number is valid
        if exists(select 1 from Sessions S where S.launch_date = date_launch
            and S.course_id = id_course and S.sid = ses_num) and
        -- check if there is an available seat in the new session
        exists(select 1 from (select count(*) from RR RR2
            where RR2.launch_date = date_launch and RR2.course_id = id_course and RR2.sid = ses_num) X1(num),
            (select Ro.seating_capacity from Sessions S, Rooms Ro where S.launch_date = date_launch
                and S.course_id = id_course and S.sid = ses_num and S.rid = Ro.rid) X2(num)
            where X2.num > X1.num) then
        update Registers
        set sid = ses_num,
        register_date = current_date
        where launch_date = date_launch and course_id = id_course and cust_id = id_cust;
        else raise exception 'Session number is invalid or there is no available seat in the new session';
        end if;
    elsif exists(select 1 from Redeems Rd1 where Rd1.cust_id = id_cust
        and Rd1.launch_date = date_launch and Rd1.course_id = id_course) then
        -- check if session number is valid
        if exists(select 1 from Sessions S where S.launch_date = date_launch
            and S.course_id = id_course and S.sid = ses_num) and
        -- check if there is an available seat in the new session
        exists(select 1 from (select count(*) from RR RR3
            where RR3.launch_date = date_launch and RR3.course_id = id_course and RR3.sid = ses_num) X3(num),
            (select Ro.seating_capacity from Sessions S, Rooms Ro where S.launch_date = date_launch
                and S.course_id = id_course and S.sid = ses_num and S.rid = Ro.rid) X4(num)
            where X4.num > X3.num) then
        update Redeems
        set sid = ses_num,
        redeem_date = current_date
        where launch_date = date_launch and course_id = id_course and cust_id = id_cust;
        else raise exception 'Session number is invalid or there is no available seat in the new session';
        end if;
    end if;
    drop table RR;
end;
$$ language plpgsql;

------------------------------------------------------------------------------------------------------------------------------

-- q20 cancel_registration
CREATE OR REPLACE PROCEDURE cancel_registration(id_cust INT, id_course INT, date_launch DATE)
AS $$
DECLARE 
	session_price NUMERIC(10,2);
	refund_amount NUMERIC(10,2);
	refund_credits INT;
	date_session DATE;
	id_session INT;
BEGIN	
	-- basic condition
	IF EXISTS (SELECT 1 FROM Cancels C WHERE id_cust=C.cust_id AND id_course=C.course_id AND date_launch=C.launch_date) THEN
		RAISE EXCEPTION 'Registration has already been cancelled!';
	END IF;
	
	-- getting more details for inserting later
	SELECT session_date, sid INTO date_session, id_session FROM Sessions S WHERE id_course=S.course_id AND date_launch=S.launch_date;
	SELECT fees INTO session_price FROM Offerings O WHERE id_course=O.course_id AND date_launch=O.launch_date;
	
	-- refund process
	IF EXISTS (SELECT 1 FROM Registers R WHERE id_cust=R.cust_id AND id_course=R.course_id AND date_launch=R.launch_date) THEN
		IF (CURRENT_DATE <= date_session - '7 days'::INTERVAL) THEN
			refund_amount := 0.9 * session_price;
		ELSE
			RAISE NOTICE 'Nothing was refunded as the session date is less than 7 days from now!';
		END IF;
		-- emptying up slots
		DELETE FROM Registers R WHERE id_cust=R.cust_id AND id_course=R.course_id AND date_launch=R.launch_date;
	ELSIF EXISTS (SELECT 1 FROM Redeems R WHERE id_cust=R.cust_id AND id_course=R.course_id AND date_launch=R.launch_date) THEN
		IF (CURRENT_DATE <= date_session - '7 days'::INTERVAL) THEN
			refund_credits := 1;
		ELSE
			RAISE NOTICE 'Nothing was refunded as the session date is less than 7 days from now!';
		END IF;
		-- emptying up slots + 1 FROM NUM PACKAGES PLEASE
		DELETE FROM Redeems R WHERE id_cust=R.cust_id AND id_course=R.course_id AND date_launch=R.launch_date;
	ELSE
		RAISE EXCEPTION 'Registration or redemption does not exist!';
	END IF;
	
	-- if registration exists, check session date
	IF date_session < CURRENT_DATE THEN
		RAISE EXCEPTION 'Session has already been attended!';
	END IF;

	-- cancel
	INSERT INTO Cancels VALUES (CURRENT_DATE, refund_amount, refund_credits, id_cust, id_session, date_launch, id_course);
END; 
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

--q21 update_instructor
-- assume course offering id includes course id and launch date
create or replace procedure update_instructor(offering_course_id int, 
    offering_launch_date date, session_number int, new_id int) as $$
declare
    startt time;
    endt time;
    sessiond date;
    r record;
    sumhours int;
    area char(100);
    specialization char(100);
begin
    select S.start_time, S.end_time, S.session_date
    into startt, endt, sessiond
    from Sessions S
    where S.course_id = offering_course_id and S.sid = session_number
    and S.launch_date = offering_launch_date;
    startt := startt - interval '1 hour';
    endt := endt + interval '1 hour';
    select name into specialization from Specializes where eid = new_id;
    select name into area from Courses where course_id = offering_course_id;
    if (select eid from Sessions 
        where course_id = offering_course_id and sid = session_number) = new_id then
        raise exception 'Instructors are the same.';
    end if;
    -- instructor does not have consecutive sessions
    -- or does not teach another session at the same time => no sessions around +- 1hr
    if not exists (select sid from Sessions
        where eid = new_id and (start_time, end_time) overlaps (startt, endt))
    -- specializes in the course area
    and specialization = area and specialization is not null and 
    -- if part time, number of hours cannot exceed 30
    exists (select eid from Part_time_instructors where eid = new_id) then
        for r in (
            select S2.start_time, S2.end_time
            from Sessions S2
            where extract(month from S2.session_date) = extract(month from sessiond) 
            and extract(year from S2.session_date) = extract(year from sessiond)
            and eid = new_id 
        )
        loop
            exit when not found;
            sumhours := sumhours + extract(hour from (r.end_time - r.start_time));
        end loop;
        if sumhours + extract(hour from (endt - startt)) <= 30 
        or sumhours is null then
            update Sessions set eid = new_id 
            where sid = session_number and course_id = offering_course_id
            and launch_date = offering_launch_date;
            raise notice 'Updated Sessions with part time instructor.';
        else 
        -- working for more than 30 hours
            raise notice 'Part time instructor cannot work for more than 30 hours: %', sumhours;
        end if;
    else 
        if not exists (select sid from Sessions
        where eid = new_id and (start_time, end_time) overlaps (startt, endt))
        and specialization = area and specialization is not null then
            update Sessions set eid = new_id
            where sid = session_number and course_id = offering_course_id
            and launch_date = offering_launch_date;
            raise notice 'Updated Sessions with full time instructor.';
        else 
        -- invalid session
            if exists (select sid from Sessions
            where eid = new_id 
            and (start_time, end_time) overlaps (startt, endt)) then
                raise notice 'Instructor is teaching another session around the same time.';
            end if;
            if specialization <> area or specialization is null then
                raise notice 'Instructor is not specializing in the session.';
            end if;
        end if;
    end if;
end;
$$ language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------
--q22 update_room
CREATE OR REPLACE PROCEDURE update_room(curr_course_id INT, curr_launch_date DATE, session_num INT, new_rid INT)
AS $$
        DECLARE
                session_start_time TIME;
                session_start_date DATE;
                num_registrations INT;
                curr_seating_capacity INT;

        BEGIN
                SELECT S.start_time, S.session_date INTO session_start_time, session_start_date
                FROM Sessions S
                WHERE S.sid = session_num
                AND S.launch_date = curr_launch_date AND S.course_id = curr_course_id;

                SELECT COUNT(*) INTO num_registrations FROM
                (SELECT R1.sid FROM Registers R1
                WHERE R1.sid=session_num AND R1.launch_date=curr_launch_date AND R1.course_id=curr_course_id
                        UNION
                SELECT R2.sid FROM Redeems R2
                WHERE R2.sid=session_num AND R2.launch_date=curr_launch_date AND R2.course_id=curr_course_id)
                AS allRegistrations;

                SELECT R.seating_capacity INTO curr_seating_capacity
                FROM Rooms R WHERE R.rid = new_rid;

                IF ((now() < session_start_date
                OR (now() = session_start_date AND now()::time < session_start_time))
                AND num_registrations <= curr_seating_capacity AND
                NOT EXISTS (SELECT 1 FROM Sessions S --check if room occupied by other sessions
                        WHERE S.rid = new_rid
                        AND S.session_date = session_start_date
                        AND session_start_time BETWEEN S.start_time AND S.end_time)) THEN
                        UPDATE Sessions S
                        SET rid = new_rid
                        WHERE S.sid = session_num
                        AND S.launch_date = curr_launch_date AND S.course_id = curr_course_id;
                ELSE
                        RAISE EXCEPTION 'Invalid room';
                END IF;
        END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------
--q23 remove_session
-- Assumption:
-- 1. customer only register for only one session per offering and is either in registers
-- redeems table
-- 2. Offerings table is already correctly keeping track of the seating capacity
-- 3. don't have to update the session number for the rest of the sessions
create or replace procedure remove_session(date_launch date, id_course integer, ses_num integer)
as $$
declare
    num_seatings integer;
    new_start_date date;
    new_end_date date;
begin
    create temp table if not exists RR1 as(
        select R1.launch_date, R1.course_id, R1.sid, R1.cust_id
        from Registers R1
        union
        select R2.launch_date, R2.course_id, R2.sid, R2.cust_id
        from Redeems R2);
    create temp table if not exists SS as(
        select * from Sessions S where S.launch_date = date_launch
        and S.course_id = id_course and S.sid = ses_num);
    -- check if the input session exists in the Sessions table
    if not exists(select 1 from SS) then
        raise exception 'Session does not exist!';
    -- check if this session is the only session for the course offering
    -- since each course offering must have at least 1 session
    elsif not exists(select 1 from Sessions S1 where S1.launch_date = date_launch
        and S1.course_id = id_course and S1.sid <> ses_num) then
        raise exception 'Cannot remove session because it is the only session for the course offering!';
    -- check if session is already over (date)
    elsif exists(select 1 from SS ss1 where ss1.session_date < current_date) then
        raise exception 'Cannot remove session because it is already over!';
    -- check if session is today but it has already started (date + time)
    -- when testing, server's current time =/= our timezone
    -- but this check is working if test data is adjusted for the difference in timezone
    elsif exists(select 1 from SS ss2 where ss2.session_date = current_date
        and ss2.start_time < current_time) then
        raise exception 'Cannot remove session because the session has already started!';
    -- check if there is at least one registeration for the session
    elsif exists(select 1 from RR1 rr where rr.launch_date = date_launch
        and rr.course_id = id_course and rr.sid = ses_num) then
        raise exception 'Cannot remove session because there is at least one registration for the session!';
    end if;
    
    select Ro.seating_capacity into num_seatings
    from SS ss3, Rooms Ro
    where ss3.rid = Ro.rid;

    delete from Sessions
    where launch_date = date_launch and course_id = id_course and sid = ses_num;

    create temp table if not exists SS1 as(
        select * from Sessions S where S.launch_date = date_launch
        and S.course_id = id_course);
    
    select sss1.session_date into new_start_date
    from SS1 sss1
    order by sss1.session_date
    limit 1;

    select sss2.session_date into new_end_date
    from SS1 sss2
    order by sss2.session_date desc
    limit 1;

    -- update offerings table
    update Offerings
    set seating_capacity = seating_capacity - num_seatings,
    start_date = new_start_date, end_date = new_end_date
    where launch_date = date_launch and course_id = id_course;

    drop table RR1;
    drop table SS;
    drop table SS1;
end;
$$ language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

-- q24 add_session
-- assumption: offering capacity, start and end times are determined and changed by the trigger, outside this function
CREATE OR REPLACE PROCEDURE add_session(id_course INT, date_launch DATE, session_num INT, session_date DATE, session_hour TIME, instr_id INT, id_room INT)
AS $$
DECLARE
	duration_course INT;
	duration_course_char TEXT;
	session_end TIME;
BEGIN
	-- init
	SELECT duration
	INTO duration_course
	FROM Courses 
	WHERE id_course=course_id
	LIMIT 1;

	duration_course_char := duration_course::TEXT || ' hour';
	session_end := session_hour + duration_course_char::INTERVAL;

	-- check conditions
	IF NOT EXISTS(SELECT * FROM Offerings WHERE course_id=id_course AND date_launch=launch_date) THEN 
		RAISE EXCEPTION 'Offering does not exist with the course id and launch date!'; 
	ELSIF session_hour < '09:00'::TIME THEN 
		RAISE EXCEPTION 'Sessions cannot start before 9am!'; 
	ELSIF session_end > '18:00'::TIME THEN 
		RAISE EXCEPTION 'Session cannot end after 6pm!'; 
	ELSIF (session_hour >= '12:00'::TIME AND session_hour < '14:00'::TIME) OR 
		(session_end > '12:00'::TIME AND session_end <= '14:00'::TIME) OR 
		(session_hour < '12:00'::TIME AND session_end > '14:00'::TIME) THEN 
		RAISE EXCEPTION 'Sessions cannot take place between 12pm and 2pm!'; 
	ELSIF ((EXTRACT(DOW FROM session_date)) IN (0,6)) THEN 
		RAISE EXCEPTION 'Session cannot be on weekends!';
	END IF;

	-- insert into sessions
	INSERT INTO Sessions VALUES (session_num, session_hour, session_end, session_date, date_launch, id_course, id_room, instr_id);
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

--q25 pay_salary()
create or replace function pay_salary() 
returns table(emp_id int, name char(100), status text, work_days int,
    work_hours int, h_rate numeric(10,2), m_salary numeric(10,2),
    paid numeric(10,2)) as $$
declare
    emp_curs cursor for (select * from Employees);
    r record;
    start_work_date date;
    end_work_date date;
    end_month_date date;
    session record;
begin
    open emp_curs;
    loop 
        work_days := null;
        work_hours := null;
        h_rate := null;
        m_salary := null;
        paid := 0;
        fetch emp_curs into r;
        exit when not found;
        emp_id = r.eid;
        name = r.name;
        -- if part time count from sessions and calc salary
        if exists (select eid from Part_time_Emp where eid = r.eid) then
            status := 'part-time';
            work_hours := 0;
            select hourly_rate into h_rate from Part_time_Emp where eid = r.eid;
            for session in (
                select end_time, start_time
                from Sessions
                where eid = r.eid 
                and extract(month from session_date) = extract(month from current_timestamp) 
                and extract(year from session_date) = extract(year from current_timestamp)
            ) loop
                work_hours = work_hours + extract(
                    hour from (session.end_time - session.start_time));
            end loop;
            paid := work_hours*h_rate;
            -- insert into payslips
            insert into Pay_slips
            select current_date, paid, work_hours, work_days, r.eid;
            return next;
        else
            status := 'full-time';
            start_work_date := date_trunc('month', current_timestamp);
            end_work_date := date(date_trunc('month', current_timestamp) + interval '1 month' - interval '1 day');
            end_month_date := date(date_trunc('month', current_timestamp) + interval '1 month' - interval '1 day');
            -- check join and depart date to count work days and pro rate salary
            if extract(month from r.join_date) = extract(month from current_timestamp) 
            and extract(year from r.join_date) = extract(year from current_timestamp) then
                start_work_date := extract(day from r.join_date);
            end if;
            if r.depart_date is not null then
                if extract(month from r.depart_date) = extract(month from current_timestamp)
                and extract(year from r.depart_date) = extract(year from current_timestamp) then
                    end_work_date := extract(day from r.depart_date);
                end if;
            end if;
            if end_work_date = end_month_date then
                work_days := extract(day from end_month_date);
            else 
                work_days := end_work_date - start_work_date;
            end if;
            select monthly_salary into m_salary from Full_time_Emp where eid = r.eid;
            paid := (work_days/extract(day from end_month_date))*m_salary;
            -- insert into payslips
            insert into Pay_slips
            select current_date, paid, work_hours, work_days, r.eid;
            return next;
        end if;
    end loop;
    close emp_curs;
end;
$$ language plpgsql;
-------------------------------------------------------------------------------------------------------------------------------
--q26 promote_courses
CREATE OR REPLACE FUNCTION promote_courses()
RETURNS TABLE (cust_id INT,
    cust_name CHAR,
    course_area CHAR,
    course_id INT,
    course_title CHAR,
    launch_date DATE,
    registration_deadline DATE,
    offering_fee NUMERIC) as $$

declare
        r record;
        s record;
begin
        CREATE TEMP TABLE IF NOT EXISTS inactiveCustomers AS
                SELECT DISTINCT helperTable.cust_id, helperTable.course_id, helperTable.register_date FROM
                (SELECT R1.cust_id, R1.course_id, R1.register_date FROM Registers R1
                        WHERE R1.register_date < date_trunc('month', now()) - interval '6 month'
                UNION
                SELECT R2.cust_id, R2.course_id, R2.redeem_date FROM Redeems R2
                        WHERE R2.redeem_date < date_trunc('month', now()) - interval '6 month') AS helperTable;


        FOR r IN
                SELECT * FROM
                (SELECT ROW_NUMBER() OVER
                        (PARTITION BY t.cust_id ORDER BY t.register_date DESC)
                        AS r, t.*
                        FROM inactiveCustomers t) x
                where x.r <= 3
        LOOP

            cust_id:=r.cust_id;
            cust_name:= (SELECT DISTINCT C.name FROM Customers C WHERE C.cust_id = r.cust_id);
            course_area:= (SELECT DISTINCT CA.name FROM Course_areas CA NATURAL JOIN Courses C WHERE C.course_id = r.course_id);
            course_id:= (r.course_id);
            course_title:= (SELECT DISTINCT C.title FROM Courses C WHERE C.course_id = r.course_id);
            launch_date:= (SELECT DISTINCT O.launch_date FROM Offerings O NATURAL JOIN Courses C WHERE C.course_id = r.course_id AND O.registration_deadline > NOW());
            registration_deadline:= (SELECT DISTINCT O.registration_deadline FROM Offerings O NATURAL JOIN Courses C WHERE C.course_id = r.course_id AND O.registration_deadline > NOW());
            offering_fee:= (SELECT DISTINCT O.fees FROM Offerings O NATURAL JOIN Courses C WHERE C.course_id = r.course_id);
            RETURN NEXT;
        end loop;

        FOR s IN
                SELECT * FROM (SELECT C.cust_id FROM Customers C except SELECT R1.cust_id FROM Registers R1 except SELECT R2.cust_id FROM Redeems R2) as M, Courses natural join Offerings O WHERE O.registration_deadline > NOW()
        LOOP
            cust_id:=s.cust_id;
            cust_name:=(SELECT DISTINCT C.name FROM Customers C WHERE C.cust_id = s.cust_id);
            course_area:= s.name;
            course_id:= s.course_id;
            course_title:= s.title;
            launch_date:= s.launch_date;
            registration_deadline:= s.registration_deadline;
            offering_fee:= s.fees;
            RETURN NEXT;
        END LOOP;

END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

--q27 top_packages
-- Assumptions
-- 1. dont need to check end date
create or replace function top_packages(n integer)
returns table(id_package integer, num_sessions integer, price numeric(10,2), date_start date,
    date_end date, num_sold integer)
as $$
declare
    nth_num_sold integer;
begin
    if (n < 0) then
        raise exception 'n cannot be less than 0!';
    end if;
    create temp table if not exists packages_this_year as(
        select CP.package_id, CP.num_free_registrations as num_sessions, CP.price,
        CP.sale_start_date, CP.sale_end_date, count(B.cust_id)::integer as num_sold
        from Course_packages CP left join Buys B on CP.package_id = B.package_id
        where extract(year from CP.sale_start_date) = extract(year from current_date) 
        group by CP.package_id);
    create temp table if not exists first_try as(
        select *
        from packages_this_year P1
        order by P1.num_sold desc
        limit n);
    
    -- retrieve num_sold for nth package
    select F.num_sold into nth_num_sold
    from first_try F
    order by F.num_sold
    limit 1;

    return query
    select * from packages_this_year P2
    where P2.num_sold >= nth_num_sold
    order by P2.num_sold desc, P2.price desc;

    drop table packages_this_year;
    drop table first_try;
end;
$$ language plpgsql;

------------------------------------------------------------------------------------------------------------------------------

-- q28 popular_courses
CREATE OR REPLACE FUNCTION popular_courses_unsorted(OUT id_course INT, OUT title_course TEXT, OUT area_course TEXT, OUT num_offerings INT, OUT num_registrations_latest_offering INT)
RETURNS SETOF RECORD AS $$
DECLARE
	-- 3 records for triple loops
	r_course RECORD;
	r_offering_a RECORD;
	r_offering_b RECORD;
	r_offering_latest RECORD;

	valid BOOLEAN;
	num_offerings_buffer INT;
	num_registrations_a INT;
	num_redeems_a INT;
	num_reg_total_a INT;
	num_registrations_b INT;
	num_redeems_b INT;
	num_reg_total_b INT;
	num_registrations_latest INT;
	num_redeems_latest INT;
BEGIN
	
	FOR r_course IN SELECT * FROM Courses C 
	WHERE (SELECT COUNT(*) FROM Offerings O WHERE C.course_id = O.course_id AND DATE_PART('year', O.start_date) = DATE_PART('year', CURRENT_DATE)) >= 2
	LOOP
		
		valid := false;
		SELECT * INTO r_offering_latest FROM Offerings O WHERE O.course_id=r_course.course_id LIMIT 1;
		SELECT COUNT(*) INTO num_offerings_buffer FROM Offerings O 
		WHERE r_course.course_id = O.course_id AND DATE_PART('year', O.start_date) = DATE_PART('year', CURRENT_DATE);
		IF num_offerings_buffer <> 0 THEN 
			valid := true;
		END IF;	

		FOR r_offering_a IN SELECT * FROM Offerings O 
		WHERE DATE_PART('year', O.start_date) = DATE_PART('year', CURRENT_DATE)
		LOOP			
			
			IF r_offering_latest.start_date < r_offering_a.start_date THEN
				r_offering_latest := r_offering_a;
			END IF;

			SELECT COUNT(*) INTO num_registrations_a FROM Registers R 
			WHERE R.course_id = r_offering_a.course_id AND R.launch_date = r_offering_a.launch_date; 
			SELECT COUNT(*) INTO num_redeems_a FROM Redeems R 
			WHERE R.course_id = r_offering_a.course_id AND R.launch_date = r_offering_a.launch_date;
			num_reg_total_a := num_registrations_a + num_redeems_a;
			FOR r_offering_b IN SELECT * FROM Offerings O 
			WHERE DATE_PART('year', O.start_date) = DATE_PART('year', CURRENT_DATE) 
			AND r_offering_a.course_id = O.course_id 
			AND r_offering_a.launch_date <> O.launch_date 
			AND r_offering_a.start_date > O.start_date
			LOOP
				IF r_offering_a.course_id = 1 THEN
				END IF;
				-- checking if the offering with the later start date, different launch date, has less registrations than the other
				SELECT COUNT(*) INTO num_registrations_b FROM Registers R 
				WHERE R.course_id = r_offering_b.course_id AND R.launch_date = r_offering_b.launch_date;
				SELECT COUNT(*)INTO num_redeems_b FROM Redeems R 
				WHERE R.course_id = r_offering_b.course_id AND R.launch_date = r_offering_b.launch_date;
				num_reg_total_b := num_registrations_b + num_redeems_b;
				IF num_registrations_a <= num_registrations_b THEN
					valid := false;
				END IF;
			END LOOP;
		END LOOP;

		-- set fields and return next;
		IF valid THEN
			SELECT COUNT(*) INTO num_registrations_latest FROM Registers R WHERE R.course_id = r_offering_latest.course_id AND R.launch_date = r_offering_latest.launch_date; 
			SELECT COUNT(*) INTO num_redeems_latest FROM Redeems R WHERE R.course_id = r_offering_latest.course_id AND R.launch_date = r_offering_latest.launch_date;

			id_course := r_course.course_id;
			title_course := r_course.title;
			area_course := r_course.name;
			num_offerings := num_offerings_buffer;
			num_registrations_latest_offering := num_registrations_latest + num_redeems_latest;
			RETURN NEXT;
		END IF;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION popular_courses(OUT id_course INT, OUT title_course TEXT, OUT area_course TEXT, OUT num_offerings INT, OUT num_registrations_latest_offering INT)
RETURNS SETOF RECORD AS $$
	BEGIN
		RETURN QUERY
		SELECT * FROM popular_courses_unsorted() P 
		ORDER BY P.num_registrations_latest_offering DESC, P.id_course ASC;
	END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------------------------------------------------------

--q29 view_summary_report
create or replace function view_summary_report(n int)
returns table (report_month int, report_year int, total_paid numeric(10,2), 
packages_sold int, cc_payment numeric(10,2), refunds numeric(10,2), 
package_redemptions int)
as $$
declare
    record_date date;
begin
    if n > 0 then
        record_date := current_date;
        loop
            if n = 0 then exit; end if;
            report_month = extract(month from record_date);
            report_year = extract(year from record_date);
            -- total salary paid for the month
            select coalesce(sum(amount), 0)
            into total_paid
            from Pay_slips 
            where extract(month from payment_date) = report_month
                and extract(year from payment_date) = report_year;
            -- total amount of sales of course packages for the month
            select count(*)
            into packages_sold
            from Buys
            where extract(month from buy_date) = report_month
                and extract(year from buy_date) = report_year;
            -- total registration fees paid via credit card payment
            select coalesce(sum(fees), 0)
            into cc_payment
            from (Registers natural join Sessions S) left join Offerings O
            on S.launch_date = O.launch_date and S.course_id = O.course_id
            where extract(month from register_date) = report_month
                and extract(year from register_date) = report_year;
            -- total amount of refunded registration fees (due to cancellations)
            select coalesce(sum(refund_amt), 0)
            into refunds
            from Cancels
            where extract(month from cancel_date) = report_month
                and extract(year from cancel_date) = report_year;
            -- total number of course registrations via course package redemptions
            select count(*)
            into package_redemptions
            from Redeems
            where extract(month from redeem_date) = report_month
                and extract(year from redeem_date) = report_year;
            return next;
            n = n - 1;
            record_date = record_date - interval '1 month';
        end loop;
    end if;
end;
$$language plpgsql;

-------------------------------------------------------------------------------------------------------------------------------
--q30 view_manager_report
CREATE OR REPLACE FUNCTION view_manager_report()
RETURNS TABLE(output_name CHAR, num_course_areas INT, num_course_offerings INT, total_net_fee NUMERIC, title CHAR) as $$
DECLARE
curs CURSOR FOR (
        SELECT E.name
        FROM Managers M NATURAL JOIN Employees E
        ORDER BY E.name
    );
r RECORD;
BEGIN OPEN curs;
LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;
        output_name := r.name;

        num_course_areas := (SELECT COUNT(CA.name) AS num_course_areas
                FROM (Employees AS E NATURAL JOIN Managers)
                INNER JOIN (Course_areas as CA NATURAL JOIN Courses C INNER JOIN Offerings as O ON O.course_id=C.course_id) ON E.eid=CA.eid
                WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))
                GROUP BY E.name
                HAVING E.name=r.name);

        num_course_offerings := (SELECT COUNT(*) AS num_offerings
                FROM Registers NATURAL JOIN Sessions AS S
                INNER JOIN Offerings AS O ON S.launch_date=O.launch_date AND S.course_id = O.course_id
                INNER JOIN (Courses as C NATURAL JOIN Course_areas as CA INNER JOIN Employees as E ON CA.eid=E.eid)
                ON O.course_id = C.course_id
                WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))
                GROUP BY E.name
                HAVING E.name=r.name);

total_net_fee := (SELECT SUM(COALESCE(sum, 0) + COALESCE(redemption_fee, 0))
                FROM (
                        (SELECT O.launch_date, O.course_id, sum(fees), E.name FROM Registers
                        NATURAL JOIN Sessions as S
                        INNER JOIN Offerings as O ON S.launch_date=O.launch_date AND S.course_id = O.course_id
                        INNER JOIN (Courses as C NATURAL JOIN Course_areas as CA
                        INNER JOIN Employees as E ON CA.eid=E.eid) ON O.course_id = C.course_id
                        WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))
                        GROUP BY O.launch_date, O.course_id, E.name) AS Registrations
                NATURAL FULL JOIN
                        (SELECT FLOOR(price/num_free_registrations) AS redemption_fee,O.course_id, O.launch_date, E.name FROM Redeems
                        NATURAL JOIN Buys NATURAL JOIN Course_packages NATURAL JOIN Sessions as S
                        INNER JOIN Offerings as O ON S.launch_date=O.launch_date AND S.course_id=O.course_id
                        INNER JOIN Courses as C ON O.course_id=C.course_id
                        INNER JOIN Course_areas as CA ON C.name=CA.name
                        INNER JOIN Employees as E ON CA.eid=E.eid
                        WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))) AS Redemptions
                )
                GROUP BY name
                HAVING name = r.name);

        title := (SELECT (array_agg(Registrations.title ORDER BY (COALESCE(registration_fee, 0) + COALESCE(redemption_fee, 0)) DESC))[1]
                FROM (
                        (SELECT O.launch_date, O.course_id, sum(fees) AS registration_fee, E.name, C.title
                                FROM Registers NATURAL JOIN Sessions as S
                                INNER JOIN Offerings as O ON S.launch_date=O.launch_date AND S.course_id = O.course_id
                                INNER JOIN (Courses as C NATURAL JOIN Course_areas as CA
                                INNER JOIN Employees as E ON CA.eid=E.eid) ON O.course_id = C.course_id
                                WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))
                                GROUP BY O.launch_date, O.course_id, E.name, C.title) AS Registrations
                        NATURAL FULL JOIN
                                (SELECT FLOOR(price/num_free_registrations) as redemption_fee,O.course_id, O.launch_date, E.name, C.title
                                FROM Redeems NATURAL JOIN Buys NATURAL JOIN Course_packages
                                NATURAL JOIN Sessions as S
                                INNER JOIN Offerings as O ON S.launch_date=O.launch_date AND S.course_id=O.course_id
                                INNER JOIN Courses as C ON O.course_id=C.course_id
                                INNER JOIN Course_areas as CA ON C.name=CA.name
                                INNER JOIN Employees as E ON CA.eid=E.eid
                                WHERE (SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW()))) AS Redemptions
                        )
                GROUP BY name
                HAVING name = r.name);
        RETURN NEXT;
END LOOP;
CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------------------------------------------

-- TRIGGERS

-------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_customer_registration_trigger ()
    RETURNS TRIGGER
    AS $$
BEGIN
        IF (EXISTS (
                SELECT 1 FROM Registers R INNER JOIN Sessions S
                ON R.sid=S.sid AND R.launch_date=S.launch_date AND R.course_id = S.course_id
                INNER JOIN offerings O ON S.launch_date=O.launch_date AND S.course_id=O.course_id
                WHERE R.cust_id = NEW.cust_id AND R.launch_date = NEW.launch_date
                AND R.course_id = NEW.course_id)) THEN
                RETURN NULL;
        ELSIF (EXISTS (
                SELECT 1 FROM Redeems R
                WHERE R.cust_id = NEW.cust_id AND R.launch_date = NEW.launch_date
                AND R.course_id = NEW.course_id AND R.sid = NEW.sid)) THEN
                RETURN NULL;
        ELSE
                RETURN NEW;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER check_customer_registration_trigger
    BEFORE INSERT OR UPDATE ON Registers
    FOR EACH ROW
    EXECUTE FUNCTION check_customer_registration_trigger();

CREATE OR REPLACE FUNCTION check_customer_redemption_trigger ()
    RETURNS TRIGGER
    AS $$
BEGIN
        IF (EXISTS (
                SELECT 1 FROM Redeems R INNER JOIN Sessions S
                ON R.sid=S.sid AND R.launch_date=S.launch_date AND R.course_id = S.course_id
                INNER JOIN offerings O ON S.launch_date=O.launch_date AND S.course_id=O.course_id
                WHERE R.cust_id = NEW.cust_id AND R.launch_date = NEW.launch_date
                AND R.course_id = NEW.course_id)) THEN
                RETURN NULL;
        ELSIF (EXISTS (
                SELECT 1 FROM Registers R
                WHERE R.cust_id = NEW.cust_id AND R.launch_date = NEW.launch_date
                AND R.course_id = NEW.course_id AND R.sid = NEW.sid)) THEN
                RETURN NULL;
        ELSE
                RETURN NEW;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER check_customer_redemption_trigger
    BEFORE INSERT OR UPDATE ON Redeems
    FOR EACH ROW
    EXECUTE FUNCTION check_customer_redemption_trigger();

-- for update or insert
CREATE OR REPLACE FUNCTION session_insert_update_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
	offering_end_date DATE;
	offering_start_date DATE;
	offering_seating_capacity INT;

	session_new_seating_capcity INT;
	session_old_seating_capcity INT;

	course_duration INT;
	course_duration_interval INTERVAL;
BEGIN
	SELECT end_date, start_date, seating_capacity 
	INTO offering_end_date, offering_start_date, offering_seating_capacity 
	FROM Offerings 
	WHERE NEW.course_id=course_id AND NEW.launch_date=launch_date
	LIMIT 1;

	SELECT seating_capacity INTO session_new_seating_capcity
	FROM Rooms WHERE rid=NEW.rid LIMIT 1;

	SELECT duration INTO course_duration
	FROM Courses WHERE course_id=NEW.course_id;

	course_duration_interval := ((course_duration::TEXT) || ' hour')::INTERVAL;
	
	-- exception checks
	IF EXISTS(SELECT 1 FROM Sessions 
			WHERE sid<>NEW.sid 
			AND course_id=NEW.course_id 			
			AND launch_date=NEW.launch_date 
			AND session_date=NEW.session_date 
			AND (start_time, end_time) OVERLAPS (NEW.start_time, NEW.end_time)) THEN
		RAISE EXCEPTION 'A sessions exists for the same course during the same day and time!';
	ELSIF EXISTS(SELECT 1 FROM Sessions S NATURAL JOIN Rooms R 
			WHERE S.sid<>NEW.sid
			AND R.rid=NEW.rid
			AND S.session_date=NEW.session_date
			AND (S.start_time, S.end_time) OVERLAPS (NEW.start_time, NEW.end_time)) THEN
		RAISE EXCEPTION 'The room is being used for another session at the same time!';
	ELSIF NEW.start_time + course_duration_interval <> NEW.end_time THEN
		RAISE EXCEPTION 'The end time of the new session: % is wrong! Please check the course duration', NEW.end_time;
	END IF;
	
	-- changes to the parent offering
	IF (NEW.session_date>offering_end_date) THEN
		UPDATE Offerings
		SET end_date=NEW.session_date
		WHERE NEW.course_id=course_id AND NEW.launch_date=launch_date;
		RAISE NOTICE 'The end date of the parent offering is changed!';
	ELSIF (NEW.session_date<offering_start_date) THEN
		UPDATE Offerings
		SET start_date=NEW.session_date
		WHERE NEW.course_id=course_id AND NEW.launch_date=launch_date;
		RAISE NOTICE 'The start date of the parent offering is changed!';
	END IF;

	IF (TG_OP = 'INSERT') THEN
		UPDATE Offerings
		SET seating_capacity=session_new_seating_capcity+offering_seating_capacity
		WHERE NEW.course_id=course_id AND NEW.launch_date=launch_date;
		RAISE NOTICE 'The seating capacity of the parent offering is increased by the seating capacity of the session inserted!';
	ELSIF (TG_OP = 'UPDATE') THEN
		SELECT seating_capacity INTO session_old_seating_capcity
		FROM Rooms WHERE rid=OLD.rid LIMIT 1;
		IF (session_new_seating_capcity <> session_old_seating_capcity) THEN
			UPDATE Offerings
			SET seating_capacity=session_old_seating_capcity+offering_seating_capacity
			WHERE NEW.course_id=course_id AND NEW.launch_date=launch_date;
			RAISE NOTICE 'The seating capacity of the parent offering is changed because the seating capacity of the session has changed!';
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_insert_update_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_insert_update_trigger_func();


-- for delete
CREATE OR REPLACE FUNCTION session_delete_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
	offering_seating_capacity INT;
	old_session_seating_capacity INT;
	offering_new_first_date DATE;
	offering_new_last_date DATE;
	session_loop_first BOOLEAN;
	r_session RECORD;
BEGIN
	SELECT seating_capacity 
	INTO offering_seating_capacity 
	FROM Offerings 
	WHERE OLD.course_id=course_id AND OLD.launch_date=launch_date
	LIMIT 1;

	SELECT seating_capacity INTO old_session_seating_capacity
	FROM Rooms WHERE rid=OLD.rid LIMIT 1;
	
	session_loop_first := true;
	FOR r_session IN SELECT * FROM Sessions WHERE sid<>OLD.sid
	LOOP
		IF session_loop_first THEN
			offering_new_first_date := r_session.session_date;
			offering_new_last_date := r_session.session_date;
		ELSIF r_session.session_date > offering_new_last_date THEN
			offering_new_last_date := r_session.session_date;
		ELSIF r_session.session_date < offering_new_first_date THEN
			offering_new_first_date := r_session.session_date;
		END IF;
	END LOOP;

	UPDATE Offerings 
	SET seating_capacity=offering_seating_capacity-old_session_seating_capacity,
			start_date=offering_new_first_date,
			end_date=offering_new_last_date
	WHERE OLD.course_id=course_id AND OLD.launch_date=launch_date;

	RAISE NOTICE 'Parent offering has been updated with new values!';
	
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_delete_trigger
BEFORE DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_delete_trigger_func();


create or replace function check_employee_type() returns trigger as $$
begin
    if exists (select eid from Employees where eid = NEW.eid) then
        if exists (select eid from Part_time_Emp where eid = NEW.eid)
        and exists (select eid from Instructors where eid = NEW.eid)
        and exists (select eid from Part_time_instructors where eid = NEW.eid) then
            if not exists (select eid from Full_time_Emp where eid = NEW.eid)
            and not exists (select eid from Full_time_instructors where eid = NEW.eid)
            and not exists (select eid from Administrators where eid = NEW.eid)
            and not exists (select eid from Managers where eid = NEW.eid) then
                raise notice 'Trigger: Valid part time instructor employee added.';
                return null;
            else
                raise notice 'Trigger: Part time instructor cannot be in full time employee tables. Please update tables.';
                return null;
            end if;
        else 
            if exists (select eid from Part_time_Emp where eid = NEW.eid)
            or exists (select eid from Part_time_instructors where eid = NEW.eid) then
                raise notice 'Trigger: Employee cannot be full time and part time. Please update tables.';
                return null;
            else 
                if exists (select eid from Full_time_Emp where eid = NEW.eid) then
                    if exists (select eid from Instructors where eid = NEW.eid)
                    and exists (select eid from Full_time_instructors where eid = NEW.eid) then
                        if not exists (select eid from Administrators where eid = NEW.eid)
                        and not exists (select eid from Managers where eid = NEW.eid) then
                            raise notice 'Trigger: Valid full time instructor employee added.';
                            return null;
                        else 
                            raise notice 'Trigger: Full time instructor can only be instructor or admin or manager. Please update tables.';
                            return null; 
                        end if;
                    else
                        if exists (select eid from Administrators where eid = NEW.eid) then
                            if not exists (select eid from Full_time_instructors where eid = NEW.eid)
                            and not exists (select eid from Instructors where eid = NEW.eid)
                            and not exists (select eid from Managers where eid = NEW.eid) then
                                raise notice 'Trigger: Valid full time admin employee added.';
                                return null;
                            else
                                raise notice 'Trigger: Admin cannot be in managers or any instructor table. Please update tables.';
                                return null;
                            end if;
                        else
                            if exists (select eid from Managers where eid = NEW.eid) then
                                if not exists (select eid from Full_time_instructors where eid = NEW.eid)
                                and not exists (select eid from Instructors where eid = NEW.eid)
                                and not exists (select eid from Administrators where eid = NEW.eid) then
                                    raise notice 'Trigger: Valid full time manager employee added.';
                                    return null;
                                else
                                    raise notice 'Trigger: Managers cannot be in admins or any instructor table. Please update tables.';
                                    return null;
                                end if;
                            else
                                raise notice 'Trigger: Full time employee must be instructor, manager or admin. Please update tables.';
                                return null;
                            end if;
                        end if;
                    end if;
                else 
                    raise notice 'Trigger: Employee must be in full time emp or part time emp. Please update tables.';
                    return null;
                end if;
            end if;
        end if;
    else
        raise notice 'Trigger: Employee not in Employees table. Please update tables.';
        return null;
    end if;
end;
$$ language plpgsql;

create constraint trigger employee_type_trigger
after insert or update or delete on Employees
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_ft_type_trigger
after insert or update or delete on Full_time_Emp
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_pt_type_trigger
after insert or update or delete on Part_time_Emp
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_i_type_trigger
after insert or update or delete on Instructors
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_fti_type_trigger
after insert or update or delete on Full_time_instructors
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_pti_type_trigger
after insert or update or delete on Part_time_instructors
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_a_type_trigger
after insert or update or delete on Administrators
deferrable initially deferred
for each row execute function check_employee_type();

create constraint trigger employee_m_type_trigger
after insert or update or delete on Managers
deferrable initially deferred
for each row execute function check_employee_type();

create or replace function register_before_deadline() returns trigger as $$
declare
    deadline date;
    sess_date date;
begin
    select distinct registration_deadline
    into deadline
    from Offerings O
    where O.launch_date = NEW.launch_date and O.course_id = NEW.course_id;
    select distinct session_date
    into sess_date
    from Sessions
    where launch_date = NEW.launch_date and course_id = NEW.course_id
    and sid = NEW.sid;
    if (NEW.register_date <= deadline)
    and (NEW.register_date <= sess_date) then
        return NEW;
    else
        raise notice 'Trigger: Register date cannot be after registration deadline or after session date. Action not carried out.';
        return NULL;
    end if;
end;
$$ language plpgsql;

create trigger register_before_deadline_trigger
before insert or update on Registers
for each row execute function register_before_deadline();

create or replace function redeem_before_deadline() returns trigger as $$
declare
    deadline date;
    sess_date date;
begin
    select distinct registration_deadline
    into deadline
    from Offerings O
    where O.launch_date = NEW.launch_date and O.course_id = NEW.course_id;
    select distinct session_date
    into sess_date
    from Sessions
    where launch_date = NEW.launch_date and course_id = NEW.course_id
    and sid = NEW.sid;
    if (NEW.redeem_date <= deadline)
    and (NEW.redeem_date <= sess_date) then
        return NEW;
    else
        raise notice 'Trigger: Redeem date cannot be after registration deadline or after session date. Action not carried out.';
        return NULL;
    end if;
end;
$$ language plpgsql;

create trigger redeem_before_deadline_trigger
before insert or update on Redeems
for each row execute function redeem_before_deadline();


drop trigger if exists assign_instructor_to_session on Sessions;

create or replace function check_instructor()
returns trigger as $$
declare
    inst_id integer;
    num_hours integer;
    course_area char(100);
begin
    if (new.eid is not null) then
        inst_id := new.eid;
        -- part time instructors cannot teach more than 30 hours each month
        if exists(select 1 from Part_time_instructors P where P.eid = inst_id) then
            -- extract hours for the month from Sessions table
            select sum(extract(hour from S1.end_time - S1.start_time)::integer) into num_hours
            from Sessions S1
            where S1.eid = inst_id 
            and extract(month from new.session_date) = extract(month from S1.session_date);
            if num_hours + extract(hour from new.end_time - new.start_time)::integer > 30 then
                raise exception 'Part time instructors cannot teach more than 30 hours each month!';
                return null;
            end if;
        end if;
        
        -- an instructor must specialize in the course area of a session that he is assigned to
        select C1.name into course_area
        from Courses C1
        where C1.course_id = new.course_id;
        if not exists(select 1 from Specializes S2 
            where S2.eid = inst_id and S2.name = course_area) then
            raise exception 'Instructor does not specialize in the course area of the session';
            return null;
        end if;

        -- instructors cannot teach consecutive sessions, need at least 1 hour break
        -- instructors can only teach at most one session at the same time
        if exists(select 1 from Sessions S2
            where S2.eid = inst_id and S2.session_date = new.session_date
            and (S2.start_time, S2.end_time) overlaps
            (new.start_time - '1 hour'::interval, new.end_time + '1 hour'::interval)) then
            raise exception 'Instructors need at least 1 hour break between two consecutive sessions!';
            return null;
        end if;

        return new;
    else
        -- should trigger not null check constraint on eid in schema
        return new;
    end if;
    
end;
$$ language plpgsql;

create trigger assign_instructor_to_session
before insert or update on Sessions
for each row execute function check_instructor();


