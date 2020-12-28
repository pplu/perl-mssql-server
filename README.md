# Connecting to SQL Server with Perl from Linux

Finding information on how to use SQL Server with Perl is scarce (compared to the plethora of information available for MySQL). Information gets 
even scarcer when you want to connect to SQL Server with Perl from Linux.

Most (if not all) of the documentation regarding this ordeal revolves around using FreeTDS: an open source implementation of [FreeTDS](https://www.freetds.org/), which
is an Open Source implementation of the protocol used by SQL Server. For some while now, Microsoft has been shipping an ODBC driver that works under Linux, and I 
wanted to try that out, as it also leads to [using Azure SQL Datawarehouse](https://github.com/pplu/azure-sqlserver-sqldatawarehouse-perl).

So, we'll be connecting from a Linux host via ODBC with the native Microsoft ODBC driver. We can locally "simulate" a MSSQL host by running SQL Server inside a Linux
Docker container (thanks MS!)

I've run this test successfully on Debian 10 (buster), and prior to this on Debian 9 (stretch) and Debian 8 (jessie) with minor adjustments (repo URLs)

# Preparing the environment:

It looks like the DBD::ODBC has problems if you have libiodbc2 installed. If you don't want to uninstall libodbc2, take a look at 
[this stack overflow question](https://stackoverflow.com/questions/11354288/undefined-symbol-sqlallochandle-using-perl-on-ubuntu)
for how to avoid the problem without removing libodbc2

```
sudo apt-get remove --purge libiodbc2
```

We'll use Perls' carton bundler to install the latest versions of some dependencies (DBI, DBD::ODBC) in a local directory
```
sudo apt-get install -y build-essential carton
```

We'll need the UNIX ODBC library, and its' dev package (to compile the DBD::ODBC module)
```
sudo apt-get install -y unixodbc unixodbc-dev
```

Now we'll need to install the Microsoft ODBC driver. [Luckily there are Debian packages](https://docs.microsoft.com/es-es/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server)

```
sudo su -
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install msodbcsql17
exit
```

Now we'll download the example script from this repo (`apt-get install git` if you don't have git installed)
```
git clone https://github.com/pplu/perl-mssql-server.git
cd perl-mssql-server
```
Now install the local dependencies with carton (they are in the cpanfile of the repository)
```
DBD_ODBC_UNICODE=1 carton install
```
note that you can just `carton install` if you don't need the unicode support.

# Connecting to SQL Server with Perl

Start SQL Server. We'll start it on port 1401 (this is where the [connect](connect.pl) script will connect to)
```
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=Password1' -e 'MSSQL_PID=Developer' -p 1401:1433 --name sqlcontainer1 -d microsoft/mssql-server-linux
```
Run the connect script. It will create a database, a table, put data in it and SELECT it via DBI
```
carton exec connect.pl
```
You're done! Happy Hacking

# Do it again, please

The second time you run connect.pl, it will error out, saying that TestDB already exists. To reset the environment, just:
```
docker stop sqlcontainer1
docker rm sqlcontainer1
```
And `docker run` the SQL Server container again

# Additional notes

## Named DSN

In the example, the DSN for ODBC is inlined in the connect call to DBI. You can connect via a named DSN also.

```
my $dbh = DBI->connect("dbi:ODBC:testdsn", $user, $password, { RaiseError => 1 });
```

With the `odbcinst -q -s` command you can see what DSNs are configured in your system. In the example we're using `testdsn`

In /etc/odbc.ini you should have:

```
[ODBC Data Sources]
data_source_name = testdsn

[testdsn]
Driver = /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.6.so.1.1 
DESCRIPTION = Microsoft ODBC Driver 13 for SQL Server
SERVER=localhost,1401
```

## What is the RaiseError in the connect call?

This enables DBI to throw exceptions when there are failures. Traditional DBI (and lots of code samples on the Internet)
manually throw exceptions based on return values from DBI like this:

```
my $dsn = DBI->connect('...', $user, $password) or die "";
```
That is quite old-school. DBI lets you say that it will throw the exceptions for you, so your code is cleaner, and you
don't have to worry about plaguing all your DBI calls with `or die ""`.

# Additional links that helped me get this running:

https://stackoverflow.com/questions/4905624/how-do-i-connect-with-perl-to-sql-server

https://metacpan.org/pod/DBD::ODBC

https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker

https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-docker

https://www.connectionstrings.com/sql-server/

# Author, Copyright and License

This article was authored by Jose Luis Martinez Torres

This article is (c) 2017 CAPSiDE, Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

The canonical, up-to-date source is [GitHub](https://github.com/pplu/perl-mssql-server.git). Feel free to
contribute back
