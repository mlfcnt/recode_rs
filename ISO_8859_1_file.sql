
IF EXISTS
		  (
SELECT *
FROM dbo.sysobjects
WHERE id = OBJECT_ID(N'[dbo].[FN_ATLB_GET_DATEMAXCOMPLAINTE]')
	  AND xtype IN(N'FN', N'IF', N'TF')
		  ) 
BEGIN
	DROP FUNCTION [dbo].[FN_ATLB_GET_DATEMAXCOMPLAINTE];
END;
GO


CREATE FUNCTION FN_ATLB_GET_DATEMAXCOMPLAINTE (
				@ID_PTCRMA  INT
			  , @IDS_PKCELL VARCHAR(50)) 
RETURNS @RET_TABLE TABLE (
						 DATEMAX  VARCHAR(10)
					   , HEUREMAX VARCHAR(5))
-- ----------------------------------------------------------------------------------------------------------------------
--   retourne la date maxi pour le contrôle des dates de la saisie des complaintes ATLB
-- ----------------------------------------------------------------------------------------------------------------------
--  CRT - JER - 10/02/2010
--  MDF - CYR - 12/10/2012 - Ajout de la conversion de DATE_PTCRMA de LT à UTC car on compare DATE_D_PTCRMV qui est en UTC à DATE_PTCRMA qui en LT						
--  MDF - PLS - 16/12/2018 - Optimisation de la fonction en passant par des variables.
-- ----------------------------------------------------------------------------------------------------------------------   

AS
BEGIN
	DECLARE @DATEMAX  VARCHAR(10)
		  , @HEUREMAX VARCHAR(5);

	DECLARE @IDPKCELL INT= CAST(REPLACE(@IDS_PKCELL, 'PKCELL', '') AS INT);
	DECLARE @IDSPTCRMA VARCHAR(50)= 'PTCRMA'+CAST(@ID_PTCRMA AS VARCHAR(44));
	DECLARE @CRMA_DATE DATETIME;

	SET @CRMA_DATE =
					 (
					 SELECT DBO.FN_DATE_LT_EN_UTC(DATE_PTCRMA, FK_ID_PKCELL) --12/10/2012
					 FROM PTCRMA
					 WHERE ID_PTCRMA = @ID_PTCRMA
					 );

-- RECHERCHE DE LA DATE DE DEPART DE L'ATLB SUIVANT

	SELECT TOP 1 @DATEMAX = CONVERT(VARCHAR(10), PTCRMV.DATE_D_PTCRMV, 103)
			   , @HEUREMAX = CONVERT(VARCHAR(5), PTCRMV.HRS_D_PTCRMV, 108)
	FROM PTCRMV
	WHERE FID_PKCELL = @IDPKCELL
		  AND FK_ID_PTCRMA <> @IDSPTCRMA
		  AND DBO.FN_CONCAT_DATE_HRS(PTCRMV.DATE_D_PTCRMV, PTCRMV.HRS_D_PTCRMV) > @CRMA_DATE
	ORDER BY PTCRMV.DATE_D_PTCRMV
		   , PTCRMV.HRS_D_PTCRMV;

--- SI PAS DE VALEUR	
	IF @DATEMAX IS NULL
	BEGIN
		SET @DATEMAX = '31/12/2999';
		SET @HEUREMAX = '23:59';
	END;
-- COPIE DES INFOS DANS LA TABLE DE RETOUR
	INSERT INTO @RET_TABLE(DATEMAX
						 , HEUREMAX)

		   SELECT @DATEMAX
				, @HEUREMAX;
	RETURN;
END;
GO
