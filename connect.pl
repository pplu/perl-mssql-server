#!/usr/bin/perl

use v5.10;
use warnings;
use strict;

use DBI;
use Data::Dumper;

my $user = 'SA';
my $password = 'Password1';

# Connect to the data source and get a handle for that connection.
my $dbh = DBI->connect("dbi:ODBC:Driver=/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.6.so.1.1;Server=localhost,1401", $user, $password, { RaiseError => 1 });
# If you have configured a named DSN that uses SQL Server
#my $dbh = DBI->connect("dbi:ODBC:testdsn", $user, $password, { RaiseError => 1 });

$dbh->do('CREATE DATABASE TestDB');
$dbh->do('USE TestDB');
$dbh->do('CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)');
$dbh->do("INSERT INTO Inventory VALUES (1, 'banana', 150); INSERT INTO Inventory VALUES (2, 'orange', 154)");

my $sth = $dbh->prepare('SELECT * FROM Inventory');

$sth->execute;

while (my $row = $sth->fetchrow_hashref) {
  say Dumper($row);
}

$dbh->disconnect;
