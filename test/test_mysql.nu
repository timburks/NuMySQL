;; test_mysql.nu
;;  tests for the Nu MySQL wrapper.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(load "NuMySQL")

(class TestMySQL is NuTestCase
     
     (- (id) testFamily is
        (set m ((MySQLConnection alloc) init))
        (set result (m connect))
        (assert_equal 1 result)
        (set result (m query:"create database if not exists NuMySQLTest"))
        (set result (m selectDB:"NuMySQLTest"))
        (set result (m query:<<-END
create table triples (
	subject text,
	object text,
	relation text)					
END))
        (set result (m query:<<-END
insert into triples ( subject, object, relation )
values 
('homer', 'marge', 'wife'),
('homer', 'bart', 'son'),
('homer', 'lisa', 'daughter'),
('marge', 'homer', 'husband'),
('marge', 'lisa', 'daughter'),
('marge', 'bart', 'son'),
('bart', 'homer', 'father'),
('bart', 'marge', 'mother'),
('bart', 'lisa', 'sister'),
('lisa', 'homer', 'father'),
('lisa', 'marge', 'mother'),
('lisa', 'bart', 'brother')
END))
        (set result (m query:"select * from triples"))
        (assert_equal 12 (result rowCount))
        (set result (m query:"select * from triples where subject = 'homer'"))
        (assert_equal 3 (result rowCount))
        (while (set d (result nextRowAsDictionary))
               (case (d valueForKey:"object")
                     ("bart"   (assert_equal "son"      (d valueForKey:"relation")))
                     ("lisa"   (assert_equal "daughter" (d valueForKey:"relation")))
                     ("marge"  (assert_equal "wife"     (d valueForKey:"relation")))
                     (else nil)))
        (set result (m query:"select object from triples where subject = 'homer' and relation = 'son'"))
        (assert_equal 1 (result rowCount))
        (set row (result nextRowAsArray))
        (assert_equal "bart" (row objectAtIndex:0))
        (set result (m query:"drop database NuMySQLTest"))))
