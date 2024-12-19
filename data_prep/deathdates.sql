SELECT 
    COALESCE(EXTRACT(YEAR FROM apf.deceased_date), EXTRACT(YEAR FROM af.effective_date), EXTRACT(YEAR FROM af.last_change_date)) AS year_deceased,
    COUNT(apf.roi_family_id) AS deceased_count
FROM
    v_account_profile_family apf
    JOIN v_account_flag af ON af.roi_family_id=apf.roi_family_id
WHERE 
    af.flagstd_code = 'DECEASED'
GROUP BY
    COALESCE(EXTRACT(YEAR FROM apf.deceased_date), EXTRACT(YEAR FROM af.effective_date), EXTRACT(YEAR FROM af.last_change_date))