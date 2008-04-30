;; @file       mysql.nu
;; @discussion Nu components of NuMySQL.
;;
;; @copyright  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(class MySQLConnection
          
     ;; Perform a query and return the result as an array of dictionaries.
     ;; Each row of a query result is returned as a dictionary.
     (- (id) queryAsArray:(id) query is
        (set myresult (self query:query))
        (set a (array))
        (while (set row (myresult nextRowAsDictionary))
               (a addObject:row))
        a)
     
     ;; Perform a query and return the result as a dictionary of dictionaries, 
     ;; with the top-level dictionary keyed by the specified key.
     ;; Each row of a query result is returned as a dictionary.
     (- (id) queryAsDictionary:(id) query withKey:(id) key is
        (set result (self query:query))
        (set d (dict))
        (while (set row (result nextRowAsDictionary))
               (d setValue:row forKey:(row valueForKey:key)))
        d)
     
     ;; Perform a query and return a single result as a dictionary.
     (- (id) queryAsValue:(id) query is
        (set result (self query:query))
        (result nextRowAsDictionary)))