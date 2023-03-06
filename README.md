# GetCurrency
Downloading the official exchange rates of the National Bank of the Republic of Belarus.

![001](/res/001.png)
![002](/res/002.png)
![003](/res/003.png)

## Requirements
Database: **Oracle 11g Enterprise Edition**
Compiler: **Delphi 10.3.1**
Third party components: 
  [Delphi Data Access Components for Oracle (ODAC)](https://www.devart.com/odac/)
  [synopse/mORMot](https://github.com/synopse/mORMot)

## How to setup script init.sql
You can change the username. By default is `test`.
>CREATE USER `test` IDENTIFIED BY `test`;
>GRANT CONNECT, RESOURCE TO `test`;
>SELECT username, account_status FROM dba_users WHERE username = '`TEST`';
>...
>GRANT READ ON DIRECTORY RATES_DIR to `test`;

**Also** you need to setup `RATES_DIR`
>CREATE OR REPLACE DIRECTORY RATES_DIR AS '`x:\path\to\program`';

## How to setup ConnectionUrl
Edit parameter _ConnectionUrl_ in the file  _bin\GetCurrency.ini_
For example: 
```
[MAIN]
ConnectionUrl=test/test@LOCALHOST:1521:ORCL
```

## How to install service
Run file _bin\install.cmd_

## How to uninstall service
Run file _bin\uninstall.cmd_
