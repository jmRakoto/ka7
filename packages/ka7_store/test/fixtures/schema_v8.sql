-- Ka7 store schema v8, as written by ka7_store before playlists had an order.
CREATE TABLE IF NOT EXISTS "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
CREATE TABLE IF NOT EXISTS "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL, "playlist_id" TEXT NULL);
CREATE TABLE IF NOT EXISTS "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE TABLE IF NOT EXISTS "pending_downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "format" TEXT NOT NULL, "folder" TEXT NOT NULL, "source_title" TEXT NOT NULL, "source_playlist_id" TEXT NULL, "source_is_channel" INTEGER NOT NULL CHECK ("source_is_channel" IN (0, 1)), "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "channel" TEXT NULL, "duration_seconds" INTEGER NULL, "position" INTEGER NOT NULL, "audio_quality" TEXT NULL, "video_quality" TEXT NULL);
CREATE TABLE IF NOT EXISTS "subscriptions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "link" TEXT NOT NULL UNIQUE, "title" TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS "user_playlists" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "folder" TEXT NULL, "folder_label" TEXT NULL);
INSERT INTO user_playlists VALUES(1,'Soirée',NULL,NULL);
INSERT INTO user_playlists VALUES(2,'Mahaleo','/home/me/Musique/Mahaleo','Musique/Mahaleo');
CREATE TABLE IF NOT EXISTS "playlist_tracks" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "playlist" INTEGER NOT NULL REFERENCES user_playlists (id) ON DELETE CASCADE, "position" INTEGER NOT NULL, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "format" TEXT NOT NULL, "path" TEXT NOT NULL);
PRAGMA user_version = 8;
