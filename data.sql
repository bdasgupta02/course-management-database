
delete from Cancels;
delete from Specializes;
delete from Redeems;
delete from Registers;
delete from Sessions;
delete from Offerings;
delete from Courses;
delete from Course_areas;
delete from Buys;
delete from Course_packages;
delete from Owns;
delete from Credit_cards;
delete from Rooms;
delete from Administrators;
delete from Managers;
delete from Part_time_instructors;
delete from Full_time_instructors;
delete from Instructors;
delete from Part_time_Emp;
delete from Full_time_Emp;
delete from Pay_slips;
delete from Employees;
delete from Customers;

insert into Customers (cust_id, phone, address, name, email) values
(1, '95940354', 'Blk 156 Jalan Kilang Barat', 'Darren Lok', 'darren@cs2102.com'),
(2, '92134091', '1 Tengah Junction', 'Aisha Rashid', 'aisharashid@cs2102.com'),
(3, '91538095', 'Blk 37 Woodlands Street', 'Darrell Tan', 'darrellt@cs2102.com'),
(4, '96193150', '9 Jalan Ramis', 'Ridwan Ibrahim', 'ibrahim_r@cs2102.com'),
(5, '95123094', '66 Toa Payoh Crescent', 'Beth Aw', 'ylaw@cs2102.com'),
(6, '96140594', 'Blk 20 Lorong 1 Bedok Reservoir', 'Sanjay Kumar', 'skumar@cs2102.com'),
(7, '93409139', '46 Cheng San Avenue North', 'Kate Peck', 'peck_k@cs2102.com'),
(8, '95423945', '63 Cheng San Crescent', 'Russell George', 'george_f1@cs2102.com'),
(9, '91309324', '19 Jalan Tari Lilin', 'Tony Chan', 't_chan@cs2102.com'),
(10, '93590459', 'Blk 15 Aljunied Street', 'Wyatt Ho', 'howyatt@cs2102.com'),
(11, '93591549', 'Blk 15 Bukit Panjang Street', 'Bob Ho', 'hoBobt@cs2102.com');

insert into Employees (eid, name, address, email, phone, depart_date, join_date) values
(1, 'wei wei', 'beach road', 'emmmail@aa.com', '99865738', '2020-02-01', '2019-01-02'),
(2, 'rui rui', 'woodlands road', 'asdfmail@cc.com', '995488', '2019-02-03', '2019-01-03'),
(3, 'bibi', 'yishun road', 'mailee@bb.com', '9924388', '2021-02-05', '2019-01-04'),
(4, 'feng feng', 'sembawang road', 'feng011@aa.com', '9141568', '2020-02-07', '2019-01-05'),
(5, 'wei reni', 'yewtee road', 'reniwei@aa.sg', '9981368', '2020-02-02', '2019-01-06'),
(6, 'wei jun', 'kranji road', 'uuuff@yahoo.com', '99881364', '2020-02-01', '2019-01-07'),
(7, 'xue xue', 'normal road', 'xx@yahoo.com', '99821364', '2020-02-02', '2019-01-04'),
(8, 'jun wei', 'marsiling road', 'email@aa.com', '998768', '2020-02-06', '2019-01-08'),
(9, 'jin wei', 'bugis road', 'mmagfil@aa.com', '9985698', '2020-05-04', '2019-01-06'),
(10, 'hao wei', 'beach road', 'emsdfgil@aa.com', '9989658', '2020-09-10', '2019-04-09'),
(11, 'my baby', 'beach streat', 'gildebar@gg.com', '98454578', '2020-09-10', '2019-04-09'),
(12, 'mommo', '639 Tony Terrace', 'emmile@aaac.com', '9377658', '2020-09-10', '2019-12-09'),
(13, 'tchiken', '92 Superior Pass', 'spagget@aia.com', '998947868', '2020-09-11', '2019-09-09'),
(14, 'nabong', '9 Gateway Park', 'rick@you.com', '93862626', '2020-09-30', '2019-04-09'),
(15, 'nu gget', 'animal crossing', 'roll@tube.com', '99896246', '2020-03-15', '2018-12-19'),
(16, 'du bu', 'wolf hill', 'dragonl@bb.com', '926254624', '2020-09-12', '2018-04-09'),
(17, 'mia mama', '11 Hans Avenue', 'msmsyil@paa.com', '92549658', '2020-09-20', '2019-04-19'),
(18, 'miko', 'ferguson tower', 'idont@wan.com', '9677658', '2021-03-10', '2019-09-09'),
(19, 'nico', 'beach road', 'todothis@any.com', '47647658', '2021-02-10', '2019-11-09'),
(20, 'nica', 'not beach road', 'moreee@eee.com', '94657258', '2021-01-10', '2019-10-09'),
(21, 'annabelle', '5 beach road', 'canido@it.com', '2545476558', '2021-09-10', '2019-05-09'),
(22, 'enebele', '10 beach road', 'aikend@aa.com', '94677685658', '2021-09-10', '2019-06-09'),
(23, 'choo tech puat', 'beach lane', 'doeet@aa.com', '99824558', '2021-09-10', '2019-07-09'),
(24, 'Charles', '74013 Mockingbird Court', 'clowman3@pcworld.com', '3518217251', '2020-07-11', '2019-09-21'),
(25, 'Franklin', '728 Westport Alley', 'fmatuszinski4@stumbleupon.com', '7317558771', '2021-01-05', '2019-06-13'),
(26, 'Mendel', '790 Westridge Center', 'mfrensch5@home.pl', '6092890919', '2020-10-22', '2019-12-27'),
(27, 'Marcello', '964 Thierer Way', 'mechallie6@1688.com', '7251039949', '2020-06-11', '2019-05-10'),
(28, 'Niko', '78350 Manufacturers Point', 'nducastel7@ehow.com', '7052785627', '2020-11-02', '2019-10-12'),
(29, 'Christal', '9 Holmberg Avenue', 'criolfo8@zimbio.com', '1115986881', '2020-12-12', '2019-10-02'),
(30, 'Guglielma', '46 Upham Junction', 'gholtham9@fc2.com', '8606415046', '2020-05-17', '2019-08-30'),
(31, 'Teodoor', '129 Donald Circle', 'tdoberera@theglobeandmail.com', '8549282808', '2020-07-30', '2020-03-27'),
(32, 'Adara', '6 Hallows Road', 'agiffkinsb@reddit.com', '2157749610', '2020-05-25', '2019-12-15'),
(33, 'Terza', '2460 Rowland Place', 'tclerkc@abc.net.au', '2305300496', '2020-10-29', '2019-08-13'),
(34, 'Ruthy', '1219 Morrow Trail', 'rblackd@hud.gov', '3876239587', '2020-11-29', '2019-12-16'),
(35, 'Myrvyn', '53593 Hoepker Park', 'mcicceralee@utexas.edu', '6022432388', '2020-11-09', '2019-08-15'),
(36, 'Coleman', '6875 Dawn Center', 'cgianninottif@businessweek.com', '6616956295', '2020-07-27', '2020-03-03'),
(37, 'Gar', '9336 Brentwood Hill', 'gfilippyevg@booking.com', '1488195205', '2020-10-05', '2019-11-12'),
(38, 'Helen', '48 Eastlawn Place', 'hbillhamh@census.gov', '7684274197', '2020-12-07', '2019-04-07'),
(39, 'Clair', '1908 Farwell Center', 'ccranidgei@flickr.com', '4176944256', '2021-02-06', '2019-11-28'),
(40, 'Barn', '022 Larry Junction', 'bspinozzij@webmd.com', '3261019962', '2020-12-13', '2019-10-15');

insert into Full_time_Emp (eid, monthly_salary) values 
(1,'3000'),
(2,'3000'),
(3,'3000'),
(4,'3000'),
(5,'3000'),
(6,'3000'),
(7,'3000'),
(8,'3000'),
(9,'3000'),
(10,'3000'),
(21,'4000'),
(22,'4000'),
(23,'4000'),
(24,'4000'),
(25,'4000'),
(26,'4000'),
(27,'4000'),
(28,'4000'),
(29,'4000'),
(30,'4000'),
(31,'5000'),
(32,'5000'),
(33,'5000'),
(34,'5000'),
(35,'5000'),
(36,'5000'),
(37,'5000'),
(38,'5000'),
(39,'5000'),
(40,'5000');

insert into Part_time_Emp (eid, hourly_rate) values 
(11,'11'),
(12,'12'),
(13,'13'),
(14,'14'),
(15,'15'),
(16,'16'),
(17,'17'),
(18,'18'),
(19,'19'),
(20,'20');

insert into Pay_slips (payment_date, amount, num_work_hours, num_work_days, eid) values
('2021-03-01', 3000, null, 31, 1),
('2021-03-01', 3000, null, 31, 2),
('2021-03-01', 3000, null, 31, 3),
('2021-03-01', 3000, null, 31, 4),
('2021-03-01', 3000, null, 31, 5),
('2021-04-01', 1760, 110, null, 16),
('2021-04-01', 2040, 120, null, 17),
('2021-04-01', 2340, 130, null, 18),
('2021-04-01', 2660, 140, null, 19),
('2021-04-01', 3000, 150, null, 20);

insert into Instructors (eid) values
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12),
(13),
(14),
(15),
(16),
(17),
(18),
(19),
(20);

insert into Full_time_instructors (eid) values
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10);

insert into Part_time_instructors (eid) values
(11),
(12),
(13),
(14),
(15),
(16),
(17),
(18),
(19),
(20);

insert into Managers (eid) values
(21),
(22),
(23),
(24),
(25),
(26),
(27),
(28),
(29),
(30);

insert into Administrators (eid) values
(31),
(32),
(33),
(34),
(35),
(36),
(37),
(38),
(39),
(40);

insert into Rooms (rid, location, seating_capacity) values
(1, '01-01', 60),
(2, '01-02', 60),
(3, '01-03', 70),
(4, '01-04', 70),
(5, '01-05', 60),
(6, '02-03', 100),
(7, '02-04', 100),
(8, '02-05', 90),
(9, '02-06', 90),
(10, '02-07', 60);

insert into Credit_cards (number, expiry_date, CVV) values
(1234123412341234, '2024-05-02', 123),
(1234123412341235, '2024-05-05', 124),
(1234123412341236, '2024-05-03', 325),
(1234123412341237, '2024-05-04', 126),
(1234123412341238, '2024-05-05', 827),
(1234123412341239, '2024-05-06', 628),
(1234123412341244, '2024-05-07', 129),
(1234123412341254, '2024-05-02', 233),
(1234123412341264, '2024-05-01', 543),
(1234123412341274, '2024-05-10', 153);


insert into Owns (number, cust_id, from_date) values
(1234123412341234, 1, '2020-05-02'),
(1234123412341235, 2, '2021-05-05'),
(1234123412341236, 3, '2020-05-03'),
(1234123412341237, 4, '2021-05-04'),
(1234123412341238, 5, '2020-05-05'),
(1234123412341239, 6, '2021-05-06'),
(1234123412341244, 7, '2020-05-07'),
(1234123412341254, 8, '2021-05-02'),
(1234123412341264, 9, '2020-05-01'),
(1234123412341274, 10, '2021-05-10');


insert into Course_packages (package_id, sale_start_date, sale_end_date, num_free_registrations, name, price) values
(1, '2020-04-08', '2021-06-08', 5, 'set 1 package', 30.99),
(2, '2020-04-07', '2021-06-07', 5, 'set 2 package', 40.99),
(3, '2020-04-09', '2021-07-08', 5, 'set 3 package', 50.99),
(4, '2020-04-10', '2021-09-05', 5, 'set 4 package', 60.99),
(5, '2020-04-11', '2021-06-13', 5, 'set 5 package', 70.99),
(6, '2020-04-12', '2021-07-15', 5, 'set 6 package', 80.99),
(7, '2020-04-08', '2021-08-27', 5, 'set 7 package', 90.99),
(8, '2020-04-09', '2021-09-26', 5, 'set 8 package', 35.99),
(9, '2020-04-10', '2021-12-15', 5, 'set 9 package', 36.99),
(10, '2020-04-11', '2021-12-12', 5, 'set 10 package', 37.99),
(11, '2021-04-08', '2021-06-08', 5, 'set 11 package', 30.99),
(12, '2021-04-07', '2021-06-07', 5, 'set 12 package', 40.99),
(13, '2021-04-09', '2021-07-08', 5, 'set 13 package', 50.99),
(14, '2021-04-10', '2021-09-05', 5, 'set 14 package', 60.99),
(15, '2021-04-11', '2021-06-13', 5, 'set 15 package', 70.99),
(16, '2021-04-12', '2021-07-15', 5, 'set 16 package', 80.99),
(17, '2021-04-08', '2021-08-27', 5, 'set 17 package', 90.99),
(18, '2021-04-09', '2021-09-26', 5, 'set 18 package', 35.99),
(19, '2021-04-10', '2021-12-15', 5, 'set 19 package', 36.99),
(20, '2021-04-11', '2021-12-12', 5, 'set 20 package', 37.99);

insert into Buys (buy_date, num_remaining_redemptions, package_id, number, cust_id) values
('2021-03-01', 4, 1, 1234123412341234, 1),
('2021-03-07', 5, 2, 1234123412341235, 2),
('2021-03-02', 3, 3, 1234123412341236, 3),
('2021-03-07', 3, 4, 1234123412341237, 4),
('2021-03-11', 4, 5, 1234123412341238, 5),
('2021-03-12', 5, 6, 1234123412341239, 6),
('2021-03-08', 4, 7, 1234123412341244, 7),
('2021-03-09', 5, 8, 1234123412341254, 8),
('2021-03-10', 4, 9, 1234123412341264, 9),
('2021-03-11', 3, 10, 1234123412341274, 10),
('2021-05-08', 5, 11, 1234123412341234, 1),
('2021-05-07', 5, 12, 1234123412341235, 2),
('2021-05-09', 5, 12, 1234123412341236, 3),
('2021-05-10', 5, 13, 1234123412341237, 4),
('2021-05-11', 5, 13, 1234123412341238, 5),
('2021-05-12', 5, 13, 1234123412341239, 6),
('2021-05-08', 5, 17, 1234123412341244, 7),
('2021-05-09', 5, 18, 1234123412341254, 8),
('2021-05-10', 5, 19, 1234123412341264, 9),
('2021-05-11', 5, 20, 1234123412341274, 10);

insert into Course_areas (name, eid) values
('calculus', 21),
('algebra', 22),
('network science', 23),
('physics', 24),
('computer science', 25),
('economics', 26),
('business', 27),
('arts', 28),
('medicine', 29),
('engineering', 30);

insert into Courses (course_id, title, description, duration, name) values
(1, 'data structures introduction', 'algorithms and complexity', 2, 'computer science'),
(2, 'calculus', 'applications and optimization', 2, 'calculus'),
(3, 'graph theory', 'shortest path and mst', 4, 'network science'),
(4, 'databases', 'SQL and noSQL', 2, 'computer science'),
(5, 'server architecture', 'backend and data management', 4, 'computer science'),
(6, 'managerial economics', 'microeconomics course', 2, 'economics'),
(7, 'expositional writing', 'writing your ideas', 3, 'arts'),
(8, 'social critique of markets', 'core course in sociology', 3, 'arts'),
(9, 'astrophysics', 'stars, planets and satellites', 2, 'physics'),
(10, 'linear algebra', 'specific for computing', 2, 'algebra'),
(11, 'pharmacy', 'specific for medicine', 2, 'medicine'),
(12, 'differential equations', 'specific for calculus', 2, 'engineering'),
(13, 'bull and bear market', 'investment strategies', 2, 'business');

insert into Specializes (eid, name) values
(1, 'calculus'),
(2, 'algebra'),
(3, 'network science'),
(4, 'physics'),
(5, 'computer science'),
(6, 'economics'),
(7, 'business'),
(8, 'arts'),
(9, 'medicine'),
(10, 'engineering'),
(10, 'physics'),
(11, 'calculus'),
(12, 'algebra'),
(13, 'network science'),
(14, 'physics'),
(14, 'calculus'),
(15, 'computer science'),
(16, 'economics'),
(17, 'business'),
(17, 'economics'),
(17, 'arts'),
(18, 'arts'),
(19, 'medicine'),
(20, 'engineering');


insert into Offerings (launch_date, start_date, end_date, registration_deadline, target_number_registrations, fees, seating_capacity, course_id, eid) values
('2020-01-01', '2021-04-02', '2021-04-02', '2021-03-02', 50, 157.00, 0, 1, 31),
('2020-01-02', '2021-04-01', '2021-04-01', '2021-03-01', 50, 157.00, 0, 1, 31),
('2020-01-01', '2021-04-01', '2021-04-01', '2021-03-01', 40, 400.00, 0, 2, 32),
('2020-02-01', '2021-04-07', '2021-04-07', '2021-03-07', 70, 280.05, 0, 3, 33),
('2020-02-01', '2021-04-07', '2021-04-07', '2021-03-07', 70, 190.20, 0, 4, 34),
('2020-03-01', '2021-04-20', '2021-04-20', '2021-04-01', 60, 400.10, 0, 5, 35),
('2021-01-01', '2021-04-20', '2021-04-20', '2021-04-01', 100, 205.40, 0, 6, 36),
('2021-01-01', '2021-04-23', '2021-04-23', '2021-04-10', 100, 599.90, 0, 7, 37),
('2021-01-01', '2021-04-23', '2021-04-26', '2021-04-10', 150, 599.90, 0, 8, 38),
('2021-02-01', '2021-04-08', '2021-04-29', '2021-04-15', 200, 205.40, 0, 9, 39),
('2021-02-01', '2021-04-27', '2021-04-27', '2021-04-17', 60, 205.40, 0, 10, 40),
('2021-03-01', '2021-04-28', '2021-04-28', '2021-04-20', 20, 305.40, 0, 11, 40),
('2021-03-02', '2021-04-29', '2021-04-29', '2021-04-21', 100, 115.50, 0, 12, 40),
('2021-03-02', '2021-04-30', '2021-04-30', '2021-04-22', 160, 110.50, 0, 13, 40),
('2021-03-03', '2021-05-20', '2021-05-31', '2021-04-10', 40, 130.00, 0, 13, 31);



insert into Sessions (sid, start_time, end_time, session_date, launch_date, course_id, rid, eid) values
(1, '09:00', '11:00', '2021-04-01', '2020-01-01', 1, 1, 5),
(2, '09:00', '11:00', '2021-04-01', '2020-01-01', 2, 2, 14),
(3, '14:00', '18:00', '2021-04-07', '2020-02-01', 3, 3, 3),
(4, '09:00', '11:00', '2021-04-07', '2020-02-01', 4, 4, 15),
(5, '14:00', '18:00', '2021-04-20', '2020-03-01', 5, 5, 5),
(6, '09:00', '11:00', '2021-04-20', '2021-01-01', 6, 6, 6),
(7, '09:00', '12:00', '2021-04-23', '2021-01-01', 7, 7, 17),
(8, '14:00', '17:00', '2021-04-23', '2021-01-01', 8, 8, 18),
(9, '14:00', '17:00', '2021-04-26', '2021-01-01', 8, 8, 8),
(10, '09:00', '11:00', '2021-04-08', '2021-02-01', 9, 9, 4),
(11, '10:00', '12:00', '2021-04-22', '2021-02-01', 9, 9, 4),
(12, '16:00', '18:00', '2021-04-29', '2021-02-01', 9, 9, 10),
(13, '09:00', '11:00', '2021-04-27', '2021-02-01', 10, 10, 12),
(14, '14:00', '16:00', '2021-04-28', '2021-03-01', 11, 1, 19),
(15, '14:00', '16:00', '2021-04-29', '2021-03-02', 12, 2, 20),
(16, '14:00', '16:00', '2021-04-30', '2021-03-02', 13, 3, 7),
(17, '14:00', '16:00', '2021-05-20', '2021-03-03', 13, 3, 7);

insert into Registers (register_date, number, cust_id, sid, launch_date, course_id) values
('2020-02-01', 1234123412341234, 1, 1, '2020-01-01', 1),
('2021-02-01', 1234123412341234, 1, 1, '2020-01-01', 1),
('2021-02-01', 1234123412341235, 2, 2, '2020-01-01', 2),
('2021-03-01', 1234123412341236, 3, 3, '2020-02-01', 3),
('2021-03-02', 1234123412341237, 4, 4, '2020-02-01', 4),
('2021-03-20', 1234123412341238, 5, 5, '2020-03-01', 5),
('2021-03-22', 1234123412341239, 6, 6, '2021-01-01', 6),
('2021-04-01', 1234123412341244, 7, 7, '2021-01-01', 7),
('2021-04-02', 1234123412341254, 8, 8, '2021-01-01', 8),
('2021-03-06', 1234123412341264, 9, 10, '2021-02-01', 9),
('2021-04-16', 1234123412341274, 10, 13, '2021-02-01', 10),
('2021-04-16', 1234123412341234, 1, 14, '2021-03-01', 11),
('2021-04-17', 1234123412341235, 2, 15, '2021-03-02', 12),
('2021-04-17', 1234123412341236, 3, 15, '2021-03-02', 12),
('2021-04-18', 1234123412341237, 4, 16, '2021-03-02', 13),
('2021-04-01', 1234123412341236, 3, 17, '2021-03-03', 13),
('2021-04-01', 1234123412341238, 5, 17, '2021-03-03', 13);

insert into Redeems (redeem_date, sid, launch_date, course_id, buy_date, package_id, number, cust_id) values
('2021-03-01', 2, '2020-01-01', 2, '2021-03-01', 1, 1234123412341234, 1),
('2021-03-02', 1, '2020-01-01', 1, '2021-03-02', 3, 1234123412341236, 3),
('2021-03-07', 4, '2020-02-01', 4, '2021-03-02', 3, 1234123412341236, 3),
('2021-03-07', 3, '2020-02-01', 3, '2021-03-07', 4, 1234123412341237, 4),
('2021-04-01', 6, '2021-01-01', 6, '2021-03-11', 5, 1234123412341238, 5),
('2021-04-06', 7, '2021-01-01', 7, '2021-03-07', 4, 1234123412341237, 4),
('2021-04-07', 8, '2021-01-01', 8, '2021-03-08', 7, 1234123412341244, 7),
('2021-04-10', 7, '2021-01-01', 7, '2021-03-11', 10, 1234123412341274, 10),
('2021-04-09', 13, '2021-02-01', 10, '2021-03-10', 9, 1234123412341264, 9),
('2021-04-08', 10, '2021-02-01', 9, '2021-03-11', 10, 1234123412341274, 10);

insert into Cancels (cancel_date, refund_amt, package_credit, cust_id, sid, launch_date, course_id) values
('2021-03-01', 250.90, 0, 1, 1, '2020-01-01', 1),
('2021-03-02', 190.00, 0, 2, 2, '2020-01-01', 2),
('2021-03-03', 190.00, 0, 3, 3, '2020-02-01', 3),
('2021-03-04', 510.50, 0, 4, 4, '2020-02-01', 4),
('2021-03-05', 190.00, 0, 5, 5, '2020-03-01', 5),
('2021-03-06', 0.00, 1, 10, 6, '2021-01-01', 6),
('2021-03-07', 0.00, 1, 9, 7, '2021-01-01', 7),
('2021-03-08', 0.00, 1, 7, 8, '2021-01-01', 8),
('2021-03-09', 0.00, 1, 4, 10, '2021-02-01', 9),
('2021-03-10', 0.00, 1, 5, 13, '2021-02-01', 10);

alter sequence Customers_cust_id_seq restart with 11;
alter sequence Employees_eid_seq restart with 41;
alter sequence Rooms_rid_seq restart with 11;
alter sequence Course_packages_package_id_seq restart with 11;
alter sequence Courses_course_id_seq restart with 11;

