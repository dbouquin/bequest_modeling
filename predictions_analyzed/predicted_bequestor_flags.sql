WITH 
pred_beq AS (
    SELECT ROIFAMILYID 
    FROM UP_16425_1193735 
),

account_profile_family AS (
    SELECT roi_id,
           roi_family_id
    FROM v_account_profile_family apf
    WHERE EXISTS (
            SELECT *
            FROM pred_beq pb
            WHERE pb.ROIFAMILYID = apf.roi_family_id
            )
),

account_profile AS (
    SELECT roi_id,           -- Added roi_id here to reference it later
           account_classification
    FROM v_account_profile ap
    WHERE EXISTS (
            SELECT *
            FROM account_profile_family apf
            WHERE apf.roi_id = ap.roi_id 
            )
),

primaryAddresses AS (
    SELECT roi_id,
        city,
        state_code as state,
        zipcode
    FROM v_account_primary_address
    WHERE EXISTS (
            SELECT *
            FROM account_profile_family apf
            WHERE apf.roi_id = v_account_primary_address.roi_id
        )
),

flag_universe AS (
    SELECT roi_id,
        MAX(
            CASE
                WHEN flagstd_code LIKE 'MD_GROUP%' THEN 'Y'
                ELSE 'N'
            END
        ) AS MD_GROUP,
        MAX(
            CASE
                WHEN flagstd_code LIKE 'MD_TFP_HIGH' THEN 'Y'
                ELSE 'N'
            END
        ) AS DEV_TFP,
        MAX(
            CASE
                WHEN flagstd_code like 'MLS%' THEN 'Y'
                ELSE 'N'
            END
        ) AS MLS,
        MAX(
            CASE
                WHEN flagstd_code like 'REGCOUNCIL%' THEN 'Y'
                ELSE 'N'
            END
        ) AS REG_COUNCIL,
        MAX(
            CASE
                WHEN flagstd_code like 'NPROLE_COUNCIL' THEN 'Y'
                ELSE 'N'
            END
        ) AS Nat_Council,
        MAX(
            CASE
                WHEN flagstd_code like 'NPROLE_BOARD%' THEN 'Y'
                ELSE 'N'
            END
        ) AS Board_or_Emeritus,
        MAX(
            CASE WHEN flagstd_code like 'SUSTAINER%' THEN 'Y' 
            ELSE 'N' 
            END
        ) AS SUSTAINER,
        MAX(
            CASE
                WHEN flagstd_code like 'SF_%' THEN v_account_flag_active.flagstd_name
                ELSE NULL
            END
        ) AS SUPERFUND,
        MAX(
            CASE
                WHEN flagstd_code like 'SF_GROUP5_PLG_PROSP_FY24' THEN v_account_flag_active.flagstd_name
                ELSE NULL
            END
        ) AS SUPERFUND_PlannedGift,
        MAX(
            CASE
                WHEN flagstd_code = 'NPROLE_VETCOUNCIL' THEN 'Y'
                ELSE 'N'
            END
        ) AS Vet_Council,
        MAX(
            CASE
                WHEN flagstd_code like 'CF_GROUP_%' THEN 'Y'
                ELSE 'N'
            END
        ) AS CF_GROUP
    FROM v_account_flag_active
    WHERE 
(
       (flagstd_code LIKE 'MD_GROUP%' AND end_date IS NULL)
    OR (flagstd_code LIKE 'MD_TFP_HIGH' AND end_date IS NULL)
    OR (flagstd_code like 'MLS%' AND end_date IS NULL)
    OR (flagstd_code LIKE 'REGCOUNCIL%' AND end_date IS NULL)
    OR (flagstd_code LIKE 'NPROLE_COUNCIL' AND end_date IS NULL)
    OR (flagstd_code LIKE 'NPROLE_BOARD%' AND end_date IS NULL)
    OR (flagstd_code like 'SF_%' AND end_date IS NULL)
    OR (flagstd_code = 'NPROLE_VETCOUNCIL' AND end_date IS NULL)
    OR flagstd_code LIKE 'CF_GROUP_%' /*Active or inactive CF_GROUP flags*/
    )
        AND EXISTS (
            SELECT *
            FROM account_profile_family apf
            WHERE apf.roi_id = v_account_flag_active.roi_id
        )
    GROUP BY roi_id
),

universe AS (
    SELECT 
        flag_universe.roi_id,
        flag_universe.MD_GROUP,
        flag_universe.DEV_TFP,
        flag_universe.MLS,
        flag_universe.REG_COUNCIL,
        flag_universe.Nat_Council,
        flag_universe.Board_or_Emeritus,
        flag_universe.Vet_Council,
        flag_universe.CF_GROUP,
        flag_universe.SUPERFUND,
        flag_universe.SUPERFUND_PlannedGift
    FROM flag_universe
),

criticalFlags AS (
    SELECT roi_id,
        MAX(
            CASE
                WHEN flagstd_code like 'SF_%'
                and flagstd_code <> 'SF_GROUP5_PLG_PROSP_FY24' THEN v_account_flag_active.flagstd_name
                ELSE NULL
            END
        ) AS SUPERFUND,
        MAX(
            CASE
                WHEN flagstd_code like 'SF_GROUP5_PLG_PROSP_FY24'
                and flagstd_code NOT LIKE '%5' THEN v_account_flag_active.flagstd_name
                ELSE NULL
            END
        ) AS SUPERFUND_PlannedGift,
        MAX(
            CASE
                WHEN flagstd_code like 'SOLICIT_NO_MAIL' THEN 'Y'
                ELSE 'N'
            END
        ) AS SOLICIT_NO_MAIL,
        MAX(
            CASE
                WHEN flagstd_code like 'NO_EMAIL%' THEN 'Y'
                ELSE 'N'
            END
        ) AS NO_EMAIL,
        MAX(
            CASE
                WHEN flagstd_code like 'NPROLE_STAFF' THEN 'Y'
                ELSE 'N'
            END
        ) AS np_role_staff
    FROM v_account_flag_active
    WHERE (
            flagstd_code LIKE 'SF_%'
            OR flagstd_code like 'NO_EMAIL'
            OR flagstd_code like 'SOLICIT_NO_MAIL'
            OR flagstd_code like 'NPROLE_STAFF'
            OR flagstd_code like 'SOLICIT_NO_PHONE'
        )
        AND EXISTS (
            SELECT *
            FROM universe
            WHERE universe.roi_id = v_account_flag_active.roi_id
        )
    GROUP BY roi_id
)

SELECT 
    apf.roi_family_id,                -- Include roi_family_id
    apf.roi_id,                       -- Include roi_id
    primaryAddresses.city, 
    primaryAddresses.state, 
    primaryAddresses.zipcode,
    COALESCE(criticalFlags.SOLICIT_NO_MAIL, 'N') AS SOLICIT_NO_MAIL,
    COALESCE(criticalFlags.NO_EMAIL, 'N') AS NO_EMAIL,
    COALESCE(universe.MD_GROUP, 'N') AS MD_GROUP,
    COALESCE(universe.DEV_TFP, 'N') AS DEV_TFP,
    COALESCE(universe.MLS, 'N') AS MLS,
    COALESCE(universe.REG_COUNCIL, 'N') AS REG_COUNCIL,
    COALESCE(universe.Nat_Council, 'N') AS Nat_Council,
    COALESCE(universe.Vet_Council, 'N') AS Vet_Council,
    COALESCE(universe.CF_GROUP, 'N') AS CF_GROUP,
    COALESCE(universe.Board_or_Emeritus, 'N') AS Board_or_Emeritus,
    COALESCE(universe.SUPERFUND, criticalFlags.SUPERFUND, NULL) AS SUPERFUND,
    COALESCE(universe.SUPERFUND_PlannedGift, criticalFlags.SUPERFUND_PlannedGift, NULL) AS SUPERFUND_PlannedGift,
    COALESCE(criticalFlags.np_role_staff, 'N') AS np_role_staff
FROM 
    account_profile_family apf
JOIN 
    universe ON apf.roi_id = universe.roi_id
JOIN 
    primaryAddresses ON apf.roi_id = primaryAddresses.roi_id
LEFT JOIN 
    criticalFlags ON apf.roi_id = criticalFlags.roi_id