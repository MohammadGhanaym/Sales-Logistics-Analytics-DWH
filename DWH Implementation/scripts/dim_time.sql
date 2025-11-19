USE [DWH_Supply_Chain]
IF OBJECT_ID('gold.dim_time', 'U') IS NOT NULL
    DELETE FROM gold.dim_time;


DECLARE @Hour INT = 0;
DECLARE @Minute INT = 0;
DECLARE @Second INT = 0;

WHILE @Hour < 24
BEGIN
    SET @Minute = 0;
    WHILE @Minute < 60
    BEGIN
        DECLARE @time_value TIME = CAST(RIGHT('0' + CAST(@Hour AS VARCHAR(2)), 2) 
                                    + ':' + RIGHT('0' + CAST(@Minute AS VARCHAR(2)), 2) 
                                    + ':00' AS TIME);

        DECLARE @time_key INT = @Hour * 10000 + @Minute * 100;  -- e.g., 134500 for 1:45 PM
        DECLARE @Hour12 INT = CASE WHEN @Hour = 0 THEN 12 
                                   WHEN @Hour > 12 THEN @Hour - 12 
                                   ELSE @Hour END;
        DECLARE @AMPM CHAR(2) = CASE WHEN @Hour < 12 THEN 'AM' ELSE 'PM' END;
        DECLARE @hour_minute CHAR(5) = RIGHT('0' + CAST(@Hour AS VARCHAR(2)), 2) 
                                      + ':' + RIGHT('0' + CAST(@Minute AS VARCHAR(2)), 2);
        DECLARE @Shift VARCHAR(20) = CASE 
                                        WHEN @Hour BETWEEN 6 AND 13 THEN 'Morning'
                                        WHEN @Hour BETWEEN 14 AND 21 THEN 'Evening'
                                        ELSE 'Night'
                                     END;

        INSERT INTO gold.dim_time (time_key, time_value, Hour, Minute, Second, Hour12, AMPM, hour_minute, Shift)
        VALUES (@time_key, @time_value, @Hour, @Minute, @Second, @Hour12, @AMPM, @hour_minute, @Shift);

        SET @Minute = @Minute + 1;
    END
    SET @Hour = @Hour + 1;
END;
