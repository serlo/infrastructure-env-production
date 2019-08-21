/* only grant SELECT for user 'serlo_readonly' */
REVOKE ALL ON *.* FROM 'serlo_readonly';
GRANT SELECT ON *.* TO 'serlo_readonly';