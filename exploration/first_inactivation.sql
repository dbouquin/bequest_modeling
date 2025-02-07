SELECT min(last_change_date) as first_inactivation_date
FROM va_account_profile
WHERE rownum<1000 and account_status=297