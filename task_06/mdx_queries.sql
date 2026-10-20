-- Query 1
WITH
MEMBER [Measures].[PT GDP per capita] AS
([Measures].[GDP per capita], [Country].[Country Hierarchy].[Country].[Portugal]),
FORMAT_STRING = '#,##0'
MEMBER [Measures].[ES GDP per capita] AS
([Measures].[GDP per capita], [Country].[Country Hierarchy].[Country].[Spain]),
FORMAT_STRING = '#,##0'
MEMBER [Measures].[PT to ES ratio] AS
[Measures].[PT GDP per capita] / [Measures].[ES GDP per capita],
FORMAT_STRING = '0.0%'
SELECT
    {[Measures].[PT GDP per capita],
     [Measures].[ES GDP per capita],
     [Measures].[PT to ES ratio]} ON COLUMNS,
    {[Time].[Time Hierarchy].[Decade].[1960] : [Time].[Time Hierarchy].[Decade].[2020]} ON ROWS
FROM [Economy]

-- Query 2
SELECT
    {[Time].[Time Hierarchy].[1990].[1995],
     [Time].[Time Hierarchy].[2020].[2020]} ON COLUMNS,
    Descendants([Sector].[Sector Hierarchy].DefaultMember,
    [Sector].[Sector Hierarchy].[Broad Sector],
    SELF_AND_AFTER) ON ROWS
FROM [Sector]
WHERE ([Measures].[Value added pct GDP], [Country].[Country Hierarchy].[Country].[Portugal])