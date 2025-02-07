/* ROI Family ID 
 Date of account creation
 State
 Region 
 First gift date
 First gift amount
 Most recent gift date
 Most recent gift amount
 Largest gift date
 Largest gift amount
 Bequest received (1 or 0) --> 43600
 
 Bequest date (if applicable)
 Birth date (if available)
 Gender (if available)
 iWave Planned Giving classification
 iWave 5 yr donor capacity
 */
DROP TABLE BequestData3;
CREATE TABLE BequestData3 NOLOGGING AS

CREATE TEMPORARY TABLE regions AS (
    SELECT 'AKRO' AS region_code,
        'AK' AS state_code
    FROM dual
    UNION
    SELECT 'SERO',
        'AL'
    FROM dual
    UNION
    SELECT 'SERO',
        'AR'
    FROM dual
    UNION
    SELECT 'PARO',
        'AS'
    FROM dual
    UNION
    SELECT 'SWRO',
        'AZ'
    FROM dual
    UNION
    SELECT 'PARO',
        'CA'
    FROM dual
    UNION
    SELECT 'SWRO',
        'CO'
    FROM dual
    UNION
    SELECT 'NERO',
        'CT'
    FROM dual
    UNION
    SELECT 'MARO',
        'DC'
    FROM dual
    UNION
    SELECT 'MARO',
        'DE'
    FROM dual
    UNION
    SELECT 'SCRO',
        'FL'
    FROM dual
    UNION
    SELECT 'SERO',
        'GA'
    FROM dual
    UNION
    SELECT 'PARO',
        'GU'
    FROM dual
    UNION
    SELECT 'PARO',
        'HI'
    FROM dual
    UNION
    SELECT 'MWRO',
        'IA'
    FROM dual
    UNION
    SELECT 'NRRO',
        'ID'
    FROM dual
    UNION
    SELECT 'MWRO',
        'IL'
    FROM dual
    UNION
    SELECT 'MWRO',
        'IN'
    FROM dual
    UNION
    SELECT 'MWRO',
        'KS'
    FROM dual
    UNION
    SELECT 'SERO',
        'KY'
    FROM dual
    UNION
    SELECT 'SCRO',
        'LA'
    FROM dual
    UNION
    SELECT 'NERO',
        'MA'
    FROM dual
    UNION
    SELECT 'MARO',
        'MD'
    FROM dual
    UNION
    SELECT 'NERO',
        'ME'
    FROM dual
    UNION
    SELECT 'MWRO',
        'MI'
    FROM dual
    UNION
    SELECT 'MWRO',
        'MN'
    FROM dual
    UNION
    SELECT 'MWRO',
        'MO'
    FROM dual
    UNION
    SELECT 'SERO',
        'MS'
    FROM dual
    UNION
    SELECT 'NRRO',
        'MT'
    FROM dual
    UNION
    SELECT 'SERO',
        'NC'
    FROM dual
    UNION
    SELECT 'NRRO',
        'ND'
    FROM dual
    UNION
    SELECT 'MWRO',
        'NE'
    FROM dual
    UNION
    SELECT 'NERO',
        'NH'
    FROM dual
    UNION
    SELECT 'NERO',
        'NJ'
    FROM dual
    UNION
    SELECT 'SWRO',
        'NM'
    FROM dual
    UNION
    SELECT 'PARO',
        'NV'
    FROM dual
    UNION
    SELECT 'NERO',
        'NY'
    FROM dual
    UNION
    SELECT 'MWRO',
        'OH'
    FROM dual
    UNION
    SELECT 'TXRO',
        'OK'
    FROM dual
    UNION
    SELECT 'NWRO',
        'OR'
    FROM dual
    UNION
    SELECT 'MARO',
        'PA'
    FROM dual
    UNION
    SELECT 'SCRO',
        'PR'
    FROM dual
    UNION
    SELECT 'NERO',
        'RI'
    FROM dual
    UNION
    SELECT 'SERO',
        'SC'
    FROM dual
    UNION
    SELECT 'MWRO',
        'SD'
    FROM dual
    UNION
    SELECT 'SCRO',
        'TN'
    FROM dual
    UNION
    SELECT 'TXRO',
        'TX'
    FROM dual
    UNION
    SELECT 'SWRO',
        'UT'
    FROM dual
    UNION
    SELECT 'MARO',
        'VA'
    FROM dual
    UNION
    SELECT 'SCRO',
        'VI'
    FROM dual
    UNION
    SELECT 'NERO',
        'VT'
    FROM dual
    UNION
    SELECT 'NWRO',
        'WA'
    FROM dual
    UNION
    SELECT 'MWRO',
        'WI'
    FROM dual
    UNION
    SELECT 'MARO',
        'WV'
    FROM dual
    UNION
    SELECT 'NRRO',
        'WY'
    FROM dual
);

CREATE TEMPORARY TABLE primaryAddresses AS (
    SELECT apa.roi_id,
        apa.street,
        apa.city,
        apa.state_code as state,
        apa.zipcode,
        apa.address_type_name as address_type,
        'Y' as primary_address,
        apa.address_contact_status,
        r.region_code
    FROM v_account_primary_address apa
        JOIN regions r ON apa.state_code = r.state_code
    WHERE apa.address_status_code = 'MAILABLE'
);

CREATE TEMPORARY TABLE giftSummary AS (
    SELECT roi_family_id as roi_id,
        /*Since we're pulling heads of household, might as well call this roi_id*/
        ags.TOTAL_TRANSACTIONS,
        ags.total_amount,
        ags.first_gift_amount,
        ags.first_gift_date,
        ags.mrc_date,
        ags.mrc_amount,
        ags.hpc_date,
        ags.hpc_amount
    FROM v_account_gift_summary ags
    WHERE EXISTS (
            SELECT *
            FROM primaryAddresses pa
            WHERE pa.roi_id = ags.roi_family_id
        )
        AND ags.summary_type = 'DEV_OVERALL - HOUSEHOLD'
);

CREATE TEMPORARY TABLE iWave AS (
    SELECT roi_id,
        roi_family_id,
        "'iWave External Giving Velocity'" as iWave_External_Giving_Velocity,
        "'iWave Giving Capacity (5yr)'" as iWave_Giving_Capacity_5yr,
        "'iWave Giving Capacity (Source)'" as iWave_Giving_Capacity_Source,
        "'iWave Planned Giving'" as iWave_Planned_Giving,
        "'iWave Prospect Classification'" as iWave_Prospect_Classification,
        "'iWave Suggested Cultivation'" as iWave_Suggested_Cultivation,
        "'iWave Suggested Engagement Lead'" as iWave_Suggested_Engagement_Lead
    FROM (
            SELECT amg.roi_id,
                amg.roi_family_id,
                amg.rating_type_name,
                CASE
                    WHEN amg.rating_type_name = 'iWave Giving Capacity (5yr)' THEN rating_detail
                    ELSE amg.rating_value_name
                END AS rating_value
            FROM v_account_mg_ratings amg
            WHERE amg.rating_type_code LIKE 'IWAVE%'
                AND EXISTS (
                    SELECT *
                    FROM primaryAddresses pa
                    WHERE pa.roi_id = amg.roi_id
                        /*head of household*/
                )
        ) PIVOT (
            MAX(rating_value) FOR rating_type_name IN (
                'iWave External Giving Velocity',
                'iWave Giving Capacity (5yr)',
                'iWave Giving Capacity (Source)',
                'iWave Planned Giving',
                'iWave Prospect Classification',
                'iWave Suggested Cultivation',
                'iWave Suggested Engagement Lead'
            )
        )
);

CREATE TEMPORARY TABLE accountInfo AS (
    SELECT apf.roi_id,
        apf.roi_family_id,
        apf.name_first as first_name,
        apf.name_middle as middle_name,
        apf.name_last as last_name,
        apf.name_suffix,
        apf.birth_date as hoh_birth_date,
        ap.organization,
        ap.account_class_code as account_class,
        coalesce(
            ROI_PUBLISHED_NAME(
                apf.ROI_FAMILY_ID,
                VG_SELECT('DEV_DEFAULT_SAL', 'PUBLISHER')
            ),
            ap.household_salutation
        ) as HOUSEHOLD_SALUTATION,
        coalesce(
            ROI_PUBLISHED_NAME(
                apf.ROI_FAMILY_ID,
                VG_SELECT('DEV_DEFAULT_EMAIL_SAL', 'PUBLISHER')
            ),
            apf.salutation
        ) as salutation_waterfall,
        COALESCE(
            ROI_PUBLISHED_NAME(
                apf.ROI_FAMILY_ID,
                VG_SELECT('DEV_HOUSEHOLD_DEFAULT', 'PUBLISHER')
            ),
            HOUSEHOLD_ADDRESS_LINE
        ) as household_address_line,
        apf.do_not_contact as do_not_contact
    FROM v_account_profile_family apf
        /*Head of Household*/
        JOIN v_account_profile ap ON apf.ROI_family_ID = ap.ROI_ID
    WHERE EXISTS (
            SELECT *
            FROM primaryAddresses pa
            WHERE pa.roi_id = apf.roi_id
        )
        /*AND NOT EXISTS (
         SELECT *
         FROM v_account_flag af
         WHERE flagstd_code = 'DECEASED'
         AND af.roi_family_id = apf.roi_family_id
         )
         AND ap.account_status_code = 'ACTIVE'*/
        AND ap.account_class_code IN ('INDIVIDUAL')
);

CREATE TEMPORARY TABLE bequests AS (
    SELECT roi_id,
        roi_family_id,
        MIN(batch_date) as first_bequest_date,
        MAX(batch_date) as last_bequest_date,
        MIN(fiscal_year) as first_bequest_fiscal_year,
        MAX(fiscal_year) as last_bequest_fiscal_year,
        MAX(
            CASE
                WHEN rn_asc = 1 THEN net_amount
            END
        ) as first_bequest_net_amount,
        MAX(
            CASE
                WHEN rn_desc = 1 THEN net_amount
            END
        ) as last_bequest_net_amount
    FROM (
            SELECT rt.roi_id,
                rt.roi_family_id,
                rb.batch_date,
                rb.fiscal_year,
                rt.net_amount,
                ROW_NUMBER() OVER(
                    PARTITION BY rt.roi_id
                    ORDER BY rb.batch_date
                ) as rn_asc,
                ROW_NUMBER() OVER(
                    PARTITION BY rt.roi_id
                    ORDER BY rb.batch_date DESC
                ) as rn_desc
            FROM v_receipt_transaction rt
                JOIN v_receipt_batch rb ON rb.batch_id = rt.batch_id
                JOIN v_campaign_source cs ON cs.source_id = rt.source_id
            WHERE rt.net_amount > 0
                AND rt.transaction_type_code IN ('PAYMENT', 'SOFT_PAYMENT')
                AND cs.general_ledger_account like '43600%'
        ) subquery
    GROUP BY roi_id,
        roi_family_id
);

CREATE TEMPORARY TABLE BequestData AS (
    SELECT
        /*add all available fields*/
        ai.roi_id,
        ai.roi_family_id,
        NTILE(6) OVER (ORDER BY ai.ROI_Family_ID) as quartile,
        ai.first_name,
        ai.middle_name,
        ai.last_name,
        ai.name_suffix,
        ai.hoh_birth_date,
        ai.organization,
        ai.account_class,
        ai.HOUSEHOLD_SALUTATION,
        ai.salutation_waterfall,
        ai.household_address_line,
        ai.do_not_contact,
        pa.street,
        pa.city,
        pa.state,
        pa.zipcode,
        pa.address_type,
        pa.primary_address,
        pa.address_contact_status,
        pa.region_code,
        gs.TOTAL_TRANSACTIONS,
        gs.total_amount,
        gs.first_gift_amount,
        gs.first_gift_date,
        gs.mrc_date,
        gs.mrc_amount,
        gs.hpc_date,
        gs.hpc_amount,
        iw.iWave_External_Giving_Velocity,
        iw.iWave_Giving_Capacity_5yr,
        iw.iWave_Giving_Capacity_Source,
        iw.iWave_Planned_Giving,
        iw.iWave_Prospect_Classification,
        iw.iWave_Suggested_Cultivation,
        iw.iWave_Suggested_Engagement_Lead,
        b.first_bequest_date,
        b.last_bequest_date,
        b.first_bequest_fiscal_year,
        b.last_bequest_fiscal_year,
        b.first_bequest_net_amount,
        b.last_bequest_net_amount
    FROM accountInfo ai
        JOIN primaryAddresses pa ON pa.roi_id = ai.roi_id
        LEFT JOIN giftSummary gs ON gs.roi_id = ai.roi_id
        LEFT JOIN iWave iw ON iw.roi_family_id = ai.roi_family_id
        LEFT JOIN bequests b ON b.roi_id = ai.roi_id
    WHERE quartile = 3
);
COMMIT;

CALL ROI_OUTPUT_TABLE('OWNER','BequestData3','csv','jhaybok@npca.org,dbouquin@npca.org');