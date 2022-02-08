WITH 

ALTASCRM AS (
SELECT DISTINCT ACT_ACCT_CD, ACT_ACCT_INST_DT
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
WHERE EXTRACT(YEAR FROM ACT_ACCT_INST_DT)=2021
GROUP BY ACT_ACCT_CD, ACT_ACCT_INST_DT),

ALTAS AS (
SELECT Contrato, Formato_Fecha
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-20_CR_ALTAS_V3_2021-01_A_2021-12_T`  
WHERE Tipo_Venta="Nueva"
AND (Tipo_Cliente = "PROGRAMA HOGARES CONECTADOS" OR Tipo_Cliente="RESIDENCIAL" OR Tipo_Cliente="EMPLEADO")
AND extract(year from Formato_Fecha) = 2021 
--AND extract(month from Formato_Fecha)=4
AND Subcanal__Venta<>"OUTBOUND PYMES" AND Subcanal__Venta<>"INBOUND PYMES" AND Subcanal__Venta<>"HOTELERO" AND Subcanal__Venta<>"PYMES – NETCOM" 
AND Tipo_Movimiento= "Altas por venta"
AND (Motivo="VENTA NUEVA " OR Motivo="VENTA")
GROUP BY Contrato, Formato_Fecha
),

AMBASALTAS AS (
SELECT x.Contrato, x.Formato_Fecha
FROM ALTASCRM y INNER JOIN ALTAS x ON y.ACT_ACCT_CD=x.Contrato
WHERE DATE(ACT_ACCT_INST_DT)=Formato_Fecha 
AND EXTRACT(MONTH FROM x.Formato_Fecha)=4
),

CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD,MIN(ACT_ACCT_INST_DT) AS MinFechaInst, MAX(CST_CHRN_DT) AS Maxfecha
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
    AND EXTRACT(MONTH FROM MaxFecha)=10
    AND EXTRACT(YEAR FROM MaxFecha)=2021)


SELECT EXTRACT(MONTH FROM Formato_Fecha) AS MES, COUNT(DISTINCT a.Contrato)
FROM AMBASALTAS a INNER JOIN CHURNERSCRM c ON c.ACT_ACCT_CD=a.Contrato
GROUP BY MES ORDER BY MES
