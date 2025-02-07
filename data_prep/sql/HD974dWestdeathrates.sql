WITH num_accounts as (SELECT 
    EXTRACT(YEAR FROM apf.account_Added_date) AS year_created,
    SUM(COUNT(apf.roi_family_id)) OVER (ORDER BY EXTRACT(YEAR FROM apf.account_Added_date)) AS cumulative_count
FROM 
    v_account_profile_family apf
    
GROUP BY 
    EXTRACT(YEAR FROM apf.account_Added_date)
),
deceased as (SELECT 
    COALESCE(EXTRACT(YEAR FROM apf.deceased_date), EXTRACT(YEAR FROM af.effective_date), EXTRACT(YEAR FROM af.last_change_date)) AS year_deceased,
    COUNT(apf.roi_family_id) AS deceased_count,
        SUM(COUNT(apf.roi_family_id)) OVER (
            ORDER BY COALESCE(EXTRACT(YEAR FROM apf.deceased_date), EXTRACT(YEAR FROM af.effective_date), EXTRACT(YEAR FROM af.last_change_date))
        ) AS cumulative_deceased_count
FROM
    v_account_profile_family apf
    JOIN v_account_flag af ON af.roi_family_id=apf.roi_family_id
WHERE 
    af.flagstd_code = 'DECEASED'
GROUP BY
    COALESCE(EXTRACT(YEAR FROM apf.deceased_date), EXTRACT(YEAR FROM af.effective_date), EXTRACT(YEAR FROM af.last_change_date))
    )

SELECT 
year_created,
cumulative_count-cumulative_deceased_count+deceased_count AS active_count,
deceased_count,
cumulative_deceased_count,
ROUND((deceased_count * 100.0) / (cumulative_count-cumulative_deceased_count+deceased_count), 2) AS percentage
FROM num_accounts na
LEFT JOIN deceased d ON na.year_created = d.year_deceased