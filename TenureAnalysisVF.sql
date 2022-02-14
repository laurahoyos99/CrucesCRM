WITH 

/*Subconsulta que extrae los contratos con su respectiva fecha de extracción (última fecha activa)*/
ACTIVOSMES AS(
    SELECT DISTINCT ACT_ACCT_CD, EXTRACT(MONTH FROM FECHA_EXTRACCION) AS MES, MAX(FECHA_EXTRACCION) AS FECHABASE
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    GROUP BY ACT_ACCT_CD, MES),

/*Subconsulta que extrae el tenure de toda la base, aseguandose de que el mes base corresponda a la última fecha de extracción*/
TENUREACTIVOS AS(
 SELECT DISTINCT EXTRACT(MONTH FROM t.FECHA_EXTRACCION) AS MES, t.ACT_ACCT_CD,
  CASE WHEN C_CUST_AGE <= 6 THEN "<6M"
        WHEN C_CUST_AGE >6 AND C_CUST_AGE <= 12 THEN "6-12 M"
        WHEN C_CUST_AGE >12 AND C_CUST_AGE <= 24 THEN "1-2 A"
    ELSE ">2A" END AS TENURE
     FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t INNER JOIN 
    ACTIVOSMES a ON t.ACT_ACCT_CD = a.ACT_ACCT_CD AND a.MES = extract (month from t.FECHA_EXTRACCION) and a.FECHABASE = t.FECHA_EXTRACCION
GROUP BY t.ACT_ACCT_CD, MES, TENURE),

/*Subconsulta que extrae los churners del CRM considerando la última fecha de churn, donde el mes de esta es igual al mes de la última fecha de extracción*/
CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD, MAX(CST_CHRN_DT) AS Maxfecha
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),

/*Subconsulta que identifica los churners y no churners*/
CHURNFLAGRESULT AS (
SELECT DISTINCT t.ACT_ACCT_CD,t.MES,c.MaxFecha,TENURE,
CASE WHEN c.MaxFecha IS NOT NULL THEN "Churner"
WHEN c.Maxfecha IS NULL THEN "NonChurner" end as ChurnFlag
FROM TENUREACTIVOS t LEFT JOIN CHURNERSCRM  c ON  t.ACT_ACCT_CD=c.ACT_ACCT_CD 
AND EXTRACT(MONTH FROM MaxFecha)=t.MES
GROUP BY t.ACT_ACCT_CD,t.MES,c.MaxFecha,TENURE)

/*Consulta final que extrae el número de contratos en el mes de la última fecha de extracción y su respectivo tenure. Si se prende el filtro de Churner, 
 se extrae esta misma información para los churnes donde el mes de la última fecha de extracción correspondería a la fecha de Churn*/
SELECT 
t.MES, t.TENURE, COUNT(DISTINCT t.ACT_ACCT_CD)
FROM CHURNFLAGRESULT  t 
--WHERE ChurnFlag="Churner"
GROUP BY MES, TENURE
ORDER BY MES, CASE WHEN TENURE ="<6M" THEN 1
                                WHEN TENURE="6-12 M" THEN 2
                                WHEN TENURE="1-2 A" THEN 3
                                WHEN TENURE=">2A" THEN 4 END


