SELECT 
    XMLELEMENT("DailyExRates",
        XMLELEMENT("DailyExRates", '05.03.2023'),
        XMLAGG(
            XMLELEMENT("ExRateCurrency",
                    XMLATTRIBUTES(curs.oid AS "Id"),
                    XMLELEMENT("ExRateCharCode", curs.code),
                    XMLELEMENT("ExRateScale", curs.quantity),
                    XMLELEMENT("ExRateScale", curs.rate)
            ) 
        )
    )
FROM curs_xml_now curs;