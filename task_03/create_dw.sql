DROP DATABASE IF EXISTS aid_dw;
CREATE DATABASE aid_dw

  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE aid_dw;

CREATE TABLE DIM_COUNTRY (
  country_key   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  iso3_code     CHAR(3)           NOT NULL,
  country_name  VARCHAR(100)      NOT NULL,
  country_group VARCHAR(40)       NOT NULL,
  PRIMARY KEY (country_key),
  UNIQUE KEY uq_dim_country_iso3 (iso3_code),
  CONSTRAINT chk_dim_country_group CHECK (
    country_group IN ('Focus', 'Western Europe',
                      'Central/Eastern Europe', 'Post-Soviet', 'Benchmark')
  )
) ENGINE = InnoDB;

CREATE TABLE DIM_TIME (
  time_key INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  year     SMALLINT UNSIGNED NOT NULL,
  decade   SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (time_key),
  UNIQUE KEY uq_dim_time_year (year),
  CONSTRAINT chk_dim_time_decade CHECK (decade = FLOOR(year / 10) * 10)
) ENGINE = InnoDB;

CREATE TABLE DIM_SECTOR (
  sector_key   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sector_name  VARCHAR(40)       NOT NULL,
  broad_sector VARCHAR(20)       NOT NULL,
  PRIMARY KEY (sector_key),
  UNIQUE KEY uq_dim_sector_name (sector_name),
  CONSTRAINT chk_dim_sector_broad CHECK (
    broad_sector IN ('Primary', 'Secondary', 'Tertiary')
  )
) ENGINE = InnoDB;

CREATE TABLE FACT_ECONOMY (
  country_key     SMALLINT UNSIGNED NOT NULL,
  time_key        INT UNSIGNED      NOT NULL,
  gdp_per_capita  DECIMAL(20,6)     NULL,
  gdp             DECIMAL(24,6)     NULL,
  gdp_growth_pct  DECIMAL(14,6)     NULL,
  exports_pct_gdp DECIMAL(14,6)     NULL,
  imports_pct_gdp DECIMAL(14,6)     NULL,
  PRIMARY KEY (country_key, time_key),
  KEY idx_fact_economy_time (time_key),
  CONSTRAINT fk_economy_country FOREIGN KEY (country_key)
    REFERENCES DIM_COUNTRY (country_key),
  CONSTRAINT fk_economy_time FOREIGN KEY (time_key)
    REFERENCES DIM_TIME (time_key)
) ENGINE = InnoDB;

CREATE TABLE FACT_SOCIETY (
  country_key    SMALLINT UNSIGNED NOT NULL,
  time_key       INT UNSIGNED      NOT NULL,
  population     DECIMAL(20,6)     NULL,
  gni_per_capita DECIMAL(20,6)     NULL,
  life_expectancy DECIMAL(12,6)    NULL,
  urban_pop_pct  DECIMAL(14,6)     NULL,
  PRIMARY KEY (country_key, time_key),
  KEY idx_fact_society_time (time_key),
  CONSTRAINT fk_society_country FOREIGN KEY (country_key)
    REFERENCES DIM_COUNTRY (country_key),
  CONSTRAINT fk_society_time FOREIGN KEY (time_key)
    REFERENCES DIM_TIME (time_key)
) ENGINE = InnoDB;

CREATE TABLE FACT_SECTOR (
  country_key        SMALLINT UNSIGNED NOT NULL,
  time_key           INT UNSIGNED      NOT NULL,
  sector_key         SMALLINT UNSIGNED NOT NULL,
  value_added_pct_gdp DECIMAL(14,6)    NULL,
  value_added_usd    DECIMAL(24,6)     NULL,
  employment_pct     DECIMAL(14,6)     NULL,
  PRIMARY KEY (country_key, time_key, sector_key),
  KEY idx_fact_sector_time (time_key),
  KEY idx_fact_sector_sector (sector_key),
  CONSTRAINT fk_sector_country FOREIGN KEY (country_key)
    REFERENCES DIM_COUNTRY (country_key),
  CONSTRAINT fk_sector_time FOREIGN KEY (time_key)
    REFERENCES DIM_TIME (time_key),
  CONSTRAINT fk_sector_sector FOREIGN KEY (sector_key)
    REFERENCES DIM_SECTOR (sector_key)
) ENGINE = InnoDB;

CREATE TABLE BRIDGE_EVENT (
  event_key         INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  source_event_id   INT UNSIGNED      NOT NULL,
  country_key       SMALLINT UNSIGNED NOT NULL,
  time_key          INT UNSIGNED      NOT NULL,
  event_description VARCHAR(500)      NOT NULL,
  category          VARCHAR(50)       NOT NULL,
  economic_impact   VARCHAR(100)      NULL,
  PRIMARY KEY (event_key),
  UNIQUE KEY uq_bridge_event_source (source_event_id),
  KEY idx_bridge_event_country_time (country_key, time_key),
  KEY idx_bridge_event_time (time_key),
  CONSTRAINT fk_event_country FOREIGN KEY (country_key)
    REFERENCES DIM_COUNTRY (country_key),
  CONSTRAINT fk_event_time FOREIGN KEY (time_key)
    REFERENCES DIM_TIME (time_key)
) ENGINE = InnoDB;