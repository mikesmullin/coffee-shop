module.exports = function(app) {
  return app.db.execute_sql("DROP TABLE IF EXISTS `sessions`;\n\nCREATE TABLE \"sessions\" (\"id\" integer PRIMARY KEY  NOT NULL, \"session_id\" varchar(255) NOT NULL, \"data\" text);\n\nDROP TABLE IF EXISTS `users`;\n\nCREATE TABLE `users` (\n  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,\n  `first` varchar(255) NOT NULL,\n  `last` varchar(255) NOT NULL,\n  `email` varchar(255) NOT NULL,\n  `username` varchar(255) NOT NULL,\n  `password_digest` varchar(255) NOT NULL\n);");
};
