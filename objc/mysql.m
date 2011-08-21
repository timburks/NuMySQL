/*!
@file mysql.m
@discussion Objective-C components of the Nu MySQL wrapper.
@copyright Copyright (c) 2008 Neon Design Technology, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#import <Foundation/Foundation.h>
#import <Nu/Nu.h>
#import "mysql.h"

@interface MySQLField : NSObject
{
    MYSQL_FIELD *field;
}

@end

@implementation MySQLField

@end

@interface MySQLResult : NSObject
{
    MYSQL_RES *result;
}

@end

@implementation MySQLResult

+ (id) resultWithResult:(MYSQL_RES *) result
{
    MySQLResult *object = [[self alloc] init];
    object->result = result;
    return object;
}

- (id) nextRowAsArray
{
    int fields = mysql_num_fields(result);
    MYSQL_ROW row = mysql_fetch_row(result);
    if (row == NULL)
        return nil;
    else {
        unsigned long *lengths = mysql_fetch_lengths(result);
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < fields; i++) {
            if (row[i])
                [array addObject:[[NSString alloc] initWithBytes:row[i] length:lengths[i] encoding:NSUTF8StringEncoding]];
            else
                [array addObject:[NSNull null]];
        }
        return array;
    }
}

- (id) nextRowAsDictionary
{
    int fieldCount = mysql_num_fields(result);
	int *fieldTypes = (int *) malloc(fieldCount * sizeof(int));
    NSMutableArray *fieldNames = [NSMutableArray array];
    for (int i = 0; i < fieldCount; i++) {
		MYSQL_FIELD *field = mysql_fetch_field_direct(result, i);
        NSString *key = [NSString stringWithCString:field->name encoding:NSUTF8StringEncoding];
        [fieldNames addObject:key];
		fieldTypes[i] = field->type;
    }
    MYSQL_ROW row = mysql_fetch_row(result);
	id value = nil;
    if (row == NULL) {
        value = nil;
    } else {
        unsigned long *lengths = mysql_fetch_lengths(result);
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (int i = 0; i < fieldCount; i++) {
            NSString *key = [fieldNames objectAtIndex:i];
            id object = nil;
            if (!row[i])
                object = [NSNull null];
            else {
	    		object = [[NSString alloc] initWithBytes:row[i] length:lengths[i] encoding:NSUTF8StringEncoding];
				switch(fieldTypes[i]) {
					case MYSQL_TYPE_TINY:
					case MYSQL_TYPE_SHORT:
					case MYSQL_TYPE_LONG:
					case MYSQL_TYPE_INT24:
					case MYSQL_TYPE_LONGLONG:
						object = [NSNumber numberWithInt:[object intValue]];
						break;
					case MYSQL_TYPE_FLOAT:
						object = [NSNumber numberWithFloat:[object floatValue]];
						break;
					case MYSQL_TYPE_DOUBLE:
						object = [NSNumber numberWithDouble:[object doubleValue]];
						break;
					case MYSQL_TYPE_TIMESTAMP:	//TIMESTAMP field
					case MYSQL_TYPE_DATE:		//DATE field
					case MYSQL_TYPE_TIME:		//TIME field
					case MYSQL_TYPE_DATETIME:	//DATETIME field
						object = [NSDate dateWithNaturalLanguageString:object];
						break;
					case MYSQL_TYPE_NULL:		//NULL-type field
						object = [NSNull null];
						break;
					case MYSQL_TYPE_DECIMAL:	//DECIMAL or NUMERIC field
					case MYSQL_TYPE_NEWDECIMAL:	//Precision math DECIMAL or NUMERIC field (MySQL 5.0.3 and up)					
					case MYSQL_TYPE_BIT:		//BIT field (MySQL 5.0.3 and up)
					case MYSQL_TYPE_YEAR:		//YEAR field
					case MYSQL_TYPE_STRING:		//CHAR or BINARY field
					case MYSQL_TYPE_VAR_STRING:	//VARCHAR or VARBINARY field
					case MYSQL_TYPE_BLOB:		//BLOB or TEXT field (use max_length to determine the maximum length)
					case MYSQL_TYPE_SET:		//SET field
					case MYSQL_TYPE_ENUM:		//ENUM field
					case MYSQL_TYPE_GEOMETRY:	//Spatial field
					default:
						break;
				}
            }
			if (object) {
            	[dictionary setObject:object forKey:key];
			}
        }
        value = dictionary;
    }
	free(fieldTypes);
	return value;
}

- (int) rowCount
{
    return mysql_num_rows(result);
}

- (int) fieldCount
{
    return mysql_num_fields(result);
}

- (void) dealloc
{
    mysql_free_result(result);
    [super dealloc];
}

@end

@interface MySQLConnection : NSObject
{
    MYSQL mysql;
    MYSQL *connection;
}

@end

@implementation MySQLConnection

+ (void) load
{
    static int initialized = 0;
    if (!initialized) {
        initialized = 1;
        [Nu loadNuFile:@"mysql" fromBundleWithIdentifier:@"nu.programming.mysql" withContext:nil];
    }
}

- (id) init
{
    [super init];
    mysql_init(&mysql);
    return self;
}

- (BOOL) connect
{
    connection = mysql_real_connect(&mysql, "", "root", "", "", 0, 0, 0);
    if (!connection) {
        NSLog(@"Connection Failed");
        return NO;
    }
    return YES;
}

- (BOOL) connectWithOptions:(NSDictionary *) options {
	const char *host = "";
	const char *username = "root";
	const char *password = "";
	const char *db = "";
	unsigned int port = 0;
	const char *unix_socket = 0;
	unsigned long client_flag = 0;
	
	if ([options objectForKey:@"host"]) {
		host = [[options objectForKey:@"host"] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	if ([options objectForKey:@"username"]) {
		username = [[options objectForKey:@"username"] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	if ([options objectForKey:@"password"]) {
		password = [[options objectForKey:@"password"] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	if ([options objectForKey:@"db"]) {
		db = [[options objectForKey:@"db"] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	connection = mysql_real_connect(&mysql, host, username, password, db, port, unix_socket, client_flag);
    if (!connection) {
        NSLog(@"Connection Failed");
        return NO;
    }
    return YES;
}

- (BOOL) selectDB:(NSString *) database
{
    return mysql_select_db(connection, [database cStringUsingEncoding:NSUTF8StringEncoding]) == 0;
}

- (MySQLResult *) tables
{
    MYSQL_RES *tables = mysql_list_tables(connection, NULL);
    return [MySQLResult resultWithResult:tables];
}

- (MySQLResult *) query:(NSString *) queryString
{
    int state = mysql_query(connection, [queryString cStringUsingEncoding:NSUTF8StringEncoding]);
    if (state != 0) {
        NSLog(@"query failed");
        return nil;
    }
    else {
        MYSQL_RES *result = mysql_store_result(connection);
        return [MySQLResult resultWithResult:result];
    }
}

- (MySQLResult *) updateTable:(NSString *) tableName withDictionary:(NSDictionary *) dictionary forId:(int) identifier
{
    NSMutableString *command = [NSMutableString stringWithFormat:@"update %@ set ", tableName];
    NSEnumerator *keyEnumerator = [[dictionary allKeys] objectEnumerator];
    NSObject *key;
    bool first = YES;
    while ((key = [keyEnumerator nextObject])) {
        if (!first)
            [command appendString:@", "];
        first = NO;
        id value = [dictionary objectForKey:key];
        char *escapedValue = (char *) malloc ((1 + 2 * [value length]) * sizeof(char));
        mysql_escape_string(escapedValue, (const char *)[value cStringUsingEncoding:NSUTF8StringEncoding], [value length]);
        [command appendFormat:@"%@ = '%s'", key, escapedValue];
        free(escapedValue);
    }
    [command appendFormat:@" where id = %d", identifier];
    //NSLog(@"command is %@", command);
    return [self query:command];
}

- (MySQLResult *) insertRowInTable:(NSString *) tableName withDictionary:(NSDictionary *) dictionary
{
    NSMutableString *command = [NSMutableString stringWithFormat:@"insert into %@ (", tableName];
    NSEnumerator *keyEnumerator = [[dictionary allKeys] objectEnumerator];
    NSObject *key;
    bool first = YES;
    while ((key = [keyEnumerator nextObject])) {
        if (!first)
            [command appendString:@", "];
        first = NO;
        [command appendString:key];
    }
    [command appendString:@") values ("];
    keyEnumerator = [[dictionary allKeys] objectEnumerator];
    first = YES;
    while ((key = [keyEnumerator nextObject])) {
        if (!first)
            [command appendString:@", "];
        first = NO;
        id value = [dictionary objectForKey:key];
        char *escapedValue = (char *) malloc ((1 + 2 * [value length]) * sizeof(char));
        mysql_escape_string(escapedValue, (const char *)[value cStringUsingEncoding:NSUTF8StringEncoding], [value length]);
        [command appendFormat:@"'%s'", escapedValue];
        free(escapedValue);
    }
    [command appendString:@")"];
    return [self query:command];
}

@end
