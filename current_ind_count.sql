SELECT count(*) as count
FROM v_account_profile_family apf
LEFT JOIN (SELECT * FROM v_account_flag WHERE flagstd_code = 'DECEASED') af ON af.roi_family_id = apf.roi_family_id
WHERE (af.flagstd_code IS NULL)