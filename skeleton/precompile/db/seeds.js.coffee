process.env.BOOTSTRAP = true
require('../../server.js') (app) ->
  model = app.model 'user'
  model.execute_sql """
  DROP TABLE IF EXISTS `sessions`;

  CREATE TABLE "sessions" ("id" integer PRIMARY KEY  NOT NULL, "session_id" varchar(255) NOT NULL, "data" text);

  DROP TABLE IF EXISTS `users`;

  CREATE TABLE `users` (
    `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    `first` varchar(255) NOT NULL,
    `last` varchar(255) NOT NULL,
    `email` varchar(255) NOT NULL,
    `username` varchar(255) NOT NULL,
    `password_digest` varchar(255) NOT NULL
  );
  """

  # do more stuff here to initialize a blank db
