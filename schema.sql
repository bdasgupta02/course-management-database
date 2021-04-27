

drop table if exists Cancels;
drop table if exists Specializes;
drop table if exists Redeems;
drop table if exists Registers;
drop table if exists Sessions;
drop table if exists Offerings;
drop table if exists Courses;
drop table if exists Course_areas;
drop table if exists Buys;
drop table if exists Course_packages;
drop table if exists Owns;
drop table if exists Credit_cards;
drop table if exists Rooms;
drop table if exists Administrators;
drop table if exists Managers;
drop table if exists Part_time_instructors;
drop table if exists Full_time_instructors;
drop table if exists Instructors;
drop table if exists Part_time_Emp;
drop table if exists Full_time_Emp;
drop table if exists Pay_slips;
drop table if exists Employees;
drop table if exists Customers;

create table if not exists Customers (
	cust_id serial primary key,
phone char(20),
	address char(100),
	name char(100) not null,
	email char(100) unique
);

create table if not exists Employees (
	eid serial primary key,
	name char(100) not null,
	address char(100),
	email char(100),
	phone char(20),
	depart_date date not null,
	join_date date not null,
	check (depart_date>=join_date)
);

create table if not exists Pay_slips (
	payment_date date,
	amount numeric(10,2) not null,
	num_work_hours integer,
	num_work_days integer,
	eid integer,
	primary key (payment_date, eid),
	foreign key (eid) references Employees
		on delete cascade,
	check (amount>=0),
	check (num_work_hours>=0),
	check (num_work_days>=0)
);

create table if not exists Full_time_Emp (
	eid integer primary key references Employees
on delete cascade,
	monthly_salary numeric(10,2) not null,
	check (monthly_salary>=0)
);

create table if not exists Part_time_Emp (
	eid integer primary key references Employees
		on delete cascade,
	hourly_rate numeric(10,2) not null,
	check (hourly_rate>=0)
);

create table if not exists Instructors (
	eid integer primary key references Employees
		on delete cascade
);

create table if not exists Full_time_instructors (
	eid integer primary key references Full_time_Emp references Instructors
on delete cascade
);

create table if not exists Part_time_instructors (
eid integer primary key references Part_time_Emp references Instructors 
on delete cascade
);

create table if not exists Managers (
	eid integer primary key references Full_time_Emp on delete cascade
);

create table if not exists Administrators (
	eid integer primary key references Full_time_Emp on delete cascade
);

create table if not exists Rooms (
	rid serial primary key,
	location char(100),
	seating_capacity integer
);


create table if not exists Credit_cards (
	number bigint primary key,
expiry_date date not null,
	CVV integer not null,
	check (number>0),
	check (CVV>0)
);


create table if not exists Owns (
number bigint,
cust_id integer,
from_date date not null,
primary key (number, cust_id),
foreign key (number) references Credit_cards on update cascade,
foreign key (cust_id) references Customers
);

create table if not exists Course_packages (
package_id serial primary key,
sale_start_date date not null,
sale_end_date date not null,
num_free_registrations integer not null,
name char(100) not null,
price numeric(10,2) not null
check (num_free_registrations>0),
check (sale_end_date>=sale_start_date)
);

create table if not exists Buys (
	buy_date date,
	num_remaining_redemptions integer not null,
	package_id integer,
	number bigint,
	cust_id integer,
	primary key (buy_date, package_id, number, cust_id),
	foreign key (package_id) references Course_packages,
	foreign key (number, cust_id) references Owns on update cascade,
	check (num_remaining_redemptions>=0)
);

create table if not exists Course_areas (
	name char(100) primary key,
	eid integer not null,
foreign key (eid) references Managers
);

create table if not exists Courses (
	course_id serial primary key,
	title char(100) not null,
	description char(150),
	duration integer not null,
	name char(100) not null,
	foreign key (name) references Course_areas(name),
	check (duration>=0)
);

create table if not exists Offerings (
	launch_date date,
course_id integer,
	start_date date not null,
end_date date not null,
registration_deadline date not null,
	target_number_registrations integer not null,
	fees numeric(10,2) not null,
	seating_capacity integer not null,
	eid integer not null,
	primary key (launch_date, course_id),
	foreign key (course_id) references Courses(course_id)
on delete cascade,
	foreign key (eid) references Administrators(eid),
	check (end_date>=start_date),
	check (registration_deadline>=launch_date),
	check (registration_deadline<=start_date + '10 days'::interval)
);

create table if not exists Sessions (
	sid int unique not null,
start_time time not null,
end_time time not null,
session_date date not null,
launch_date date not null,
course_id integer not null,
rid integer not null,
eid integer not null,
primary key(sid, launch_date, course_id),
foreign key (launch_date, course_id) references Offerings on delete cascade, 
foreign key (rid) references Rooms,
foreign key (eid) references Instructors,
check ((extract(dow from session_date)) in (1,2,3,4,5)),
check (end_time>=start_time),
check (start_time>='09:00'::time),
check (end_time<='18:00'::time),
check ((start_time, end_time) overlaps ('09:00'::time, '18:00'::time) and not (start_time, end_time) overlaps ('12:00'::time, '14:00'::time))
);

create table if not exists Registers (
	register_date date,
	number bigint,
	cust_id integer,
	sid integer,
	launch_date date,
	course_id integer,
	primary key (register_date, number, cust_id, sid, launch_date, course_id),
	foreign key (number, cust_id) references Owns on update cascade,
foreign key(sid, launch_date, course_id) references Sessions,
check (register_date>=launch_date)
);

create table if not exists Redeems (
	redeem_date date,
	sid integer,
	launch_date date,
	course_id integer,
	buy_date date,
	package_id integer,
	cust_id integer,
	number bigint,
	primary key (redeem_date, sid, buy_date, package_id, number, cust_id, launch_date, course_id),
	foreign key (buy_date, package_id, number, cust_id) references Buys on update cascade,
	foreign key (sid, launch_date, course_id) references Sessions,
	check (redeem_date>=buy_date),
	check (redeem_date>=launch_date)
);

create table if not exists Specializes (
	eid integer,
	name char(20),
	primary key (eid, name),
	foreign key (name) references Course_areas,
	foreign key (eid) references Instructors
);

create table if not exists Cancels (
	cancel_date date,
	refund_amt numeric(10,2),
	package_credit integer,
	cust_id integer,
	sid integer,
	launch_date date,
	course_id integer not null,
	primary key (cancel_date, cust_id, sid),
	foreign key (cust_id) references Customers,
	foreign key (sid, launch_date, course_id) references Sessions,
	check (cancel_date>=launch_date),
	check ((refund_amt=0) or (package_credit=0))
);



