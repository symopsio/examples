# For the readonly target, users can read anything in the symdb database.
# The lambda function provides username as a named variable you can use.
GRANT SELECT ON symdb.* TO %(username)s;
