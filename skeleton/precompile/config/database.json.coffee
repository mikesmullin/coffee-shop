mysql: mysql =
  host: 'localhost'
  user: 'root'

production:
  _ mysql,
    database: 'project'

staging:
  _ mysql,
    database: 'project'

development:
  _ mysql,
    database: 'project_development'

test:
  _ mysql,
    database: 'project_test'
