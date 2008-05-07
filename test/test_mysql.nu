;; test_mysql.nu
;;  tests for the Nu MySQL wrapper.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(load "NuMySQL")

(class TestMySQL is NuTestCase
     
     (- testFamily is
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
        
        (set result (m queryAsValue:"select * from triples where subject = 'homer' and relation = 'wife'"))
        (assert_equal "marge" (result "object"))
        
        (set result (m queryAsDictionary:"select * from triples where subject = 'homer'" withKey:"relation"))
        (assert_equal "lisa" ((result "daughter") "object"))
        
        (set result (m queryAsArray:"select * from triples"))
        (assert_equal 12 (result count))
        
        ;; some empty queries
        
        (set result (m queryAsValue:"select * from triples where subject = 'homer' and relation = 'husband'"))
        (assert_equal nil result)
        
        (set result (m queryAsDictionary:"select * from triples where subject = 'homer' and relation = 'husband'" withKey:"relation"))
        (assert_equal 0 (result count))
        
        (set result (m queryAsArray:"select * from triples where subject = 'homer' and relation = 'husband'"))
        (assert_equal 0 (result count))
        
        (set result (m query:"drop database NuMySQLTest")))
     
     
     (- testUpdate is
        (set m ((MySQLConnection alloc) init))
        (set result (m connect))
        (assert_equal 1 result)
        (set result (m query:"create database if not exists NuMySQLTest"))
        (set result (m selectDB:"NuMySQLTest"))
        (set result (m query:<<-END
  create table cities (
    id integer,
  	city text,
  	nation text)					
  END))
        (set result (m query:<<-END
  insert into cities ( id, city, nation )
  values 
  (1, 'San Francisco', 'United States'),
  (2, 'Tokyo', 'Japan'),
  (3, 'Bangalore', 'India'),
  (4, 'Copenhagen', 'Denmark')
  END))
        (set result (m query:"select * from cities"))
        (assert_equal 4 (result rowCount))
        (set result (m updateTable:"cities" withDictionary:(dict city:"Yokohama") forId:2))
        (set result (m queryAsValue:"select * from cities where id = 2"))
        (assert_equal "Yokohama" (result "city"))
        (assert_equal "Japan" (result "nation"))
        (set result (m updateTable:"cities" withDictionary:(dict city:"London" nation:"England") forId:4))
        (set result (m queryAsValue:"select * from cities where id = 4"))
        (assert_equal "London" (result "city"))
        (assert_equal "England" (result "nation"))        
        (set result (m query:"drop database NuMySQLTest"))))

