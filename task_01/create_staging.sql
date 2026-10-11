DROP DATABASE IF EXISTS aid_staging;
CREATE DATABASE aid_staging

  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE aid_staging;

CREATE TABLE stg_maddison (

  country_iso3    CHAR(3)        NOT NULL,
  country_name    VARCHAR(100)   NOT NULL,
  indicator_code  VARCHAR(10)    NOT NULL,
  indicator_name  VARCHAR(100)   NOT NULL,
  year            SMALLINT       NOT NULL,
  value           DECIMAL(22,6)  NULL,

  PRIMARY KEY (country_iso3, indicator_code, year)
) ENGINE = InnoDB;

CREATE TABLE stg_wdi (

  country_iso3    CHAR(3)        NOT NULL,
  country_name    VARCHAR(100)   NOT NULL,
  indicator_code  VARCHAR(30)    NOT NULL,
  indicator_name  VARCHAR(200)   NOT NULL,
  year            SMALLINT       NOT NULL,
  value           DECIMAL(22,6)  NULL,

  PRIMARY KEY (country_iso3, indicator_code, year)
) ENGINE = InnoDB;

CREATE TABLE stg_events (

  event_id        INT            NOT NULL AUTO_INCREMENT,
  year            SMALLINT       NOT NULL,
  country_iso3    CHAR(3)        NOT NULL,
  country_name    VARCHAR(100)   NOT NULL,
  event           VARCHAR(500)   NOT NULL,
  category        VARCHAR(50)    NOT NULL,
  economic_impact VARCHAR(100)   NULL,

  PRIMARY KEY (event_id)
) ENGINE = InnoDB;